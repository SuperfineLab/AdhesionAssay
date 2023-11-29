function outs = ba_make_ForceTable(filepath, PlateID, modeltype, aggregating_variables)
% BA_PROCESS_EXPT analyzes the output of a bead adhesion experiment.
%
% This function begins the process of analyzing the output of the bead
% adhesion experiment where the bead detaches from the surface and moves
% through z while being tracked by vst. The z-velocity is then used to back
% out the detachment force.
% 
% Inputs:
%  filepath   path location of the tracking results for an "experiment"/plate.
%  PlateID    string indentifier for the plate used in the experiment
%  modeltype  model used for fitting forces. Can be "linear", "erf", or "exponential"
%  aggregating_variables   The list of index variables for the experiment,
%                          e.g, "pH", "BeadChemistry", "SubstrateChemistry", etc.
%
% Output:
%  outs   structure containing tables of File, Bead/Tracking, and Force Data
%

if nargin< 3 || isempty('modeltype')
    modeltype = 'erf';
end

if nargin < 2 || isempty('PlateID')
    logentry('No PlateID defined. Creating one at random.');
    PlateID = ['PL-' num2str(randi(2^32,1,1))];
end

rootdir = pwd;

cd(filepath);
logentry(['Moved to: ' filepath]);
search_radius_low = 10;
search_radius_high = 26;

evtfilelist = dir('*.evt.mat');

for k = 1:length(evtfilelist)
   
   evtname = evtfilelist(k).name;
   basename = strrep(evtname, '.evt.mat', '');
   origfname = [basename '.csv'];
   metafname = [basename '.meta.mat'];
   

   
   
   % Load data from metadata file. Ultimately, use this as indexing file 
   % when combining data for an entire experiment
   metadata = load(metafname);
   
   Fid = metadata.File.Fid;
   visc_Pas = metadata.Medium.Viscosity;
   calibum = metadata.Scope.Calibum;   
   bead_diameter_um = metadata.Bead.Diameter;   
   Ztable = metadata.Results.TimeHeightVidStatsTable;
   Ztable.Time = Ztable.Time * (60 * 60 * 24); % convert from days to seconds
   Ztable.Time = (Ztable.Time - Ztable.Time(1));
   firstframe = metadata.Results.FirstFrame;
   lastframe = metadata.Results.LastFrame;
   
  
   % FileTable{k} = shorten_metadata(metadata);
   
   % Need to use original VST tracking file to find how many beads existed 
   % on the first frame.
   origtracks = load_video_tracking(origfname, [], [], [], 'absolute', [], 'table');
   evttracks = load_evtfile(evtname);   
   VSTfirstframe = origtracks(origtracks.Frame == 1, :);
   FirstFrameBeadCount = height(VSTfirstframe);
   
   
   % BeadInfoTable{k} = ba_discoverbeads(firstframe, lastframe, search_radius_low, search_radius_high, Fid);   
   % BeadInfoTable{k} = ba_match_VST_and_MAT_tracks(BeadInfoTable{k}, VSTfirstframe);
   
   % FileTable{k}.FirstFrameBeadCount = FirstFrameBeadCount;
   ForceTable{k} = ba_get_linefits(evttracks, calibum, visc_Pas, bead_diameter_um, Fid);
   ForceTable{k}.ZmotorPos = interp1(Ztable.Time, Ztable.ZHeight, ForceTable{k}.Mean_time);
      
   % Number of stuck beads is equal to the starting number of beads minus
   % the number of Force approximations we made during our tracking
   % clean-up for the velocity calculation.
   % FileTable{k}.LastFrameBeadCount = FirstFrameBeadCount - height(ForceTable{k});   
end


ForceTable = vertcat(ForceTable{:});
if isstring(ForceTable.SpotID)
    ForceTable.SpotID = double(ForceTable.SpotID);
end

% ForceTable.Filename = [];
% ForceTable = vertcat(ForceTable{:});
% FileTable = vertcat(FileTable{:});
% FileTable.PlateID = categorical(repmat(string(PlateID),height(FileTable),1));
% FileTable = movevars(FileTable, 'PlateID', 'before', 'Fid');
% BeadInfoTable = vertcat(BeadInfoTable{:});

% % % [g, grpT] = findgroups(FileTable(:,aggregating_variables));
% % % NStartingBeads(:,1) = splitapply(@sum, FileTable.FirstFrameBeadCount, g);
% % % NStartingBeadsT = [grpT, table(NStartingBeads)];
% % % 
% % % T = join(ForceTable, FileTable(:,{'Fid', aggregating_variables{:}}));
% % % T = join(T, NStartingBeadsT);
% % % % T = sortrows(T, {'Filename', 'Force'}, {'ascend', 'ascend'});
% % % [g, grpT] = findgroups(T(:,aggregating_variables));
% % % 
% % % foo = splitapply(@(x1,x2,x3,x4){sa_fracleft(x1,x2,x3,x4)}, T.Fid, T.SpotID, T.Force, T.NStartingBeads, g);
% % % fooM = cell2mat(foo);
% % % 
% % % Tmp.Fid = fooM(:,1);
% % % Tmp.SpotID = fooM(:,2);
% % % Tmp.Force = fooM(:,3);
% % % Tmp.FractionLeft = fooM(:,4);
% % % 
% % % Tmp = struct2table(Tmp);
% % % ForceTable = join(ForceTable, Tmp);

cd(rootdir);
 
% outs.FileTable = FileTable;
% outs.ForceTable = ForceTable;
% outs.BeadInfoTable = BeadInfoTable;
% % 
% % % switch modeltype
% % %     case 'linear'
% % %         [DetachForce, fits] = ba_plate_detachmentforces_linear(outs, aggregating_variables, true);
% % %     case 'erf'        
% % %         [DetachForce, fits] = ba_plate_detachmentforces_erf(outs, aggregating_variables, true);
% % %     case 'exponential'
% % %         [DetachForce, fits] = ba_plate_detachmentforces(outs, aggregating_variables, true);
% % %     otherwise
% % %         error('Missing or unknown model type.');
% % % end
outs.ForceTable = ForceTable;
% outs.DetachForceTable = DetachForce;

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
    sm.Buffer = string(metadata.Medium.Buffer);
    sm.pH = metadata.Medium.pH;
    
    [a,b] = regexpi(sm.Binfile,'_DF(\d*)_', 'match', 'tokens');

%     if ~isempty(b) || lower(sm.Media) == "int" || lower(sm.Media) == "intnana"
%         DF = str2double(b{1});
     idx = contains(metadata.Medium.Components.Name, "Sialic Acid");
    if sum(idx)>0
        sm.MediumNANAConc = categorical(metadata.Medium.Components.Conc(idx));
%     elseif lower(sm.Media) == "int" || lower(sm.Media) == "intnana"
%         sm.MediumNANAConc
    else
        sm.MediumNANAConc = categorical(0);
    end
    
    
    sm.MediumViscosity = metadata.Medium.Viscosity;
    sm.Calibum = metadata.Scope.Calibum;    
    
    if isfield(metadata.Substrate, 'LotNumber')
        sm.SubstrateLotNumber = string(metadata.Substrate.LotNumber);
    end
    
    sm = struct2table(sm);
    
    sm.BeadChemistry = categorical(sm.BeadChemistry);
    sm.SubstrateChemistry = categorical(sm.SubstrateChemistry);
    sm.MagnetGeometry = categorical(sm.MagnetGeometry);  
    sm.pH = categorical(sm.pH);
    sm.Media = categorical(sm.Media);
end

function outs = sa_fracleft(fid, spotid, force, startCount)

    force = force(:);
    Nforce = length(force);   
    
    % I do not really understand how this determines "rank" of force, but
    % it does and outputs the fraction left attached
    [~,Fidx] = sort(force, 'ascend');
    [~,Frank] = sort(Fidx, 'ascend');    
    
    fracleft = 1-(Frank ./ startCount);

    outs = [fid(:), spotid(:), force(:), fracleft(:)];
end




