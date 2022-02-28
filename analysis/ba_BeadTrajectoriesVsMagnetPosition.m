function outs = ba_BeadTrajectoriesVsMagnetPosition(filepath, aggregating_variables, calfit)
% BA_PROCESS_EXPT analzes the output of a bead adhesion experiment.
%

% This function begins the process of analyzing the output of the bead
% adhesion experiment where the bead detaches from the surface and moves
% through z while being tracked by vst. The position of the z-motor, i.e. 
% the surface position of a calibrated magnet system is recorded as a
% function of time/frame within each video collection. The idea here is to
% pull the position data and match it to calibration data previously
% collected, curated, and summarized into a curve as average and error 
% force vs. distance from poletip surface.
%

rootdir = pwd;

cd(filepath);


filelist = dir('*.csv');


% firstfilelist = {evtfilelist.name}';
% firstfilelist = cellfun(@(x1)imread(strrep(x1,'.evt.mat', '.00001.pgm')),firstfilelist, 'UniformOutput', false);
% VideoTable = mk_video_table(evtfilelist, 125, 0.692, 1024, 768, firstfilelist, []);
VideoTable = mk_video_table(filelist, 125, 0.692, 1024, 768, [], []);



    % Load the metadata and extract/combine Z vs time data for each video
    ZTable = table;
    for k = 1:height(VideoTable)

       basename = strrep(VideoTable.TrackingFiles{k}, '.csv', '');

       % Load data from metadata file. Ultimately, use this as indexing file 
       % when combining data for an entire experiment
       metadata = load([basename '.meta.mat']);

    %    Fid = metadata.File.Fid;
    %    visc_Pas = metadata.Medium.Viscosity;
    %    calibum = metadata.Scope.Calibum;   
    %    bead_diameter_um = metadata.Bead.Diameter;   
        Fid = VideoTable.Fid(k);

        tmpZ = metadata.Results.TimeHeightVidStatsTable;
        tmpZ.Time = tmpZ.Time * (60 * 60 * 24); % convert from days to seconds
        tmpZ.Time = (tmpZ.Time - tmpZ.Time(1));
        tmpZ.Frame= [1:height(tmpZ)]';
        tmpZ.Fid = repmat(Fid, height(tmpZ),1);

        ZTable = vertcat(ZTable, tmpZ);
    end



    % Load trajectories into a standard TrackingTable
    TrackingTable = vst_load_tracking(VideoTable);
    
     
    
    % Calculate the radial vector using initial position as position zero and
    % generate a table containing resulting radial info. 
    % XXX TODO The radial vecs function contains the calibumXYZ values hardcoded.
    [g, ~] = findgroups(TrackingTable(:,{'Fid', 'ID'}));
    rout = splitapply(@(x1,x2,x3,x4){sa_calc_rad_vecs(x1,x2,x3,x4)}, ...
                                                      TrackingTable.Fid, ...
                                                      TrackingTable.ID, ...
                                                      TrackingTable.Frame, ...
                                                     [TrackingTable.X, ...
                                                      TrackingTable.Y, ...
                                                      TrackingTable.Z], ...
                                                      g);           
    rout = cell2mat(rout);

    RadialTable = table(rout(:,1), rout(:,2), rout(:,3), rout(:,4));
    RadialTable.Properties.VariableNames = {'Fid', 'ID', 'Frame', 'Rxyz'};

    
    % Combine Tracking, Radial, and Z tables
    T = innerjoin(TrackingTable, RadialTable, 'Keys', {'Fid', 'ID', 'Frame'});   
    T = innerjoin(T, ZTable, 'Keys', {'Fid', 'Frame'}); 
    T.CalForce = calfit(T.ZHeight*1000+317); % This magic number is the offset for the 1/4" cone poletip


    % Normalize distances based on bead diameter
    bead_diameter_um = 24;
    T.NormalizedR = T.Rxyz / bead_diameter_um; % XXX TODO Fix hard-coded bead diameter
    
    
    % Find Forces at which bead translations exceed a threshold, here 1
    % bead diameter.
    thresh = 1; % measured in normalized bead diameters, e.g. "1" for xlations larger than bead diameter
    [g, DetachmentForces] = findgroups(TrackingTable(:,{'Fid', 'ID'}));
    DetachmentForces.Force = splitapply(@(x1,x2)sa_pick_detachemnts(x1,x2,thresh), ...
                                                           T.NormalizedR, ...
                                                           T.CalForce, ...
                                                           g);          
    
    outs.RawData = T;
    outs.DetachmentForces = DetachmentForces;
    outs.BeadDiameter = bead_diameter_um;
    outs.BeadDiametersThreshold = thresh;
    
    
end


function sm = shorten_metadata(metadata)
    sm.Fid = metadata.File.Fid;
    sm.FullFilename = string(fullfile(metadata.File.Binpath, metadata.File.Binfile));
    sm.StartTime = metadata.Results.TimeHeightVidStatsTable.Time(1);
    sm.MeanFps  = 1 ./ mean(diff(metadata.Results.TimeHeightVidStatsTable.Time*86400));
    sm.ExposureTime = metadata.Video.ExposureTime;
    sm.Binfile = string(metadata.File.Binfile);
    sm.SampleName = string(metadata.File.SampleName);
    sm.BeadChemistry = string(metadata.Bead.SurfaceChemistry);
    sm.SubstrateChemistry = string(metadata.Substrate.SurfaceChemistry);
    sm.MagnetGeometry = string(metadata.Magnet.Geometry);
    sm.Media = string(metadata.Medium.Name);
    
    [a,b] = regexpi(sm.Binfile,'_DF(\d*)_', 'match', 'tokens');

    if ~isempty(b) || lower(sm.Media) == "int" || lower(sm.Media) == "intnana"
%         DF = str2double(b{1});
        idx = contains(metadata.Medium.Components.Name, "Sialic Acid");
        sm.MediumNANAConc = metadata.Medium.Components.Conc(idx);
%     elseif lower(sm.Media) == "int" || lower(sm.Media) == "intnana"
%         sm.MediumNANAConc
    else
        sm.MediumNANAConc = 0;
    end
    
    
%     sm.MediumViscosity = metadata.Medium.Viscosity;
    sm.Calibum = metadata.Scope.Calibum;    
    
    if isfield(metadata.Substrate, 'LotNumber')
        sm.SubstrateLotNumber = string(metadata.Substrate.LotNumber);
    end
    
    jac = sm;
    sm = struct2table(sm);
    
    sm.BeadChemistry = categorical(sm.BeadChemistry);
    sm.SubstrateChemistry = categorical(sm.SubstrateChemistry);
    sm.MagnetGeometry = categorical(sm.MagnetGeometry);    
    sm.Media = categorical(sm.Media);
end

function outs = sa_fracleft(force, startCount)

    force = force(:);
    Nforce = length(force);   
    
    [~,Fidx] = sort(force, 'ascend');
    
    FRank(Fidx,1) = [1:Nforce];
    
    outs = 1-(FRank ./ startCount);

end


function outs = sa_calc_rad_vecs(fid, id, frame, XYZ, XYZorigin)

    if nargin<5 || isempty(XYZorigin)
        XYZorigin = XYZ(1,:);
    end

    rout = sqrt( sum( ((XYZ - XYZorigin) .* [0.692 0.692 1]).^2, 2 ) );    
    
    outs = [fid, id, frame, rout];
end


function outs = sa_pick_detachemnts(normR, calforce, threshold)

    idx = normR > threshold;
    if any(idx)
        detachforce = calforce(idx);
    else
        detachforce = NaN;
    end

    outs = detachforce(1);
end
