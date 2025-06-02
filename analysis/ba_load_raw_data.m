function outs = ba_load_raw_data(filepath)
% BA_LOAD_RAW_DATA pulls in and combines a plate's metadata 
%
% outs = ba_load_raw_data(filepath)
%
% This function begins the process of analyzing the output of the bead
% adhesion experiment where the bead detaches from the surface and moves
% through z while being tracked by vst. The z-velocity is then used to back
% out the detachment force.
% 
% Input:
%  filepath   path location of the tracking results for an "experiment"/plate.
%
% Output:
%  outs   structure containing tables of File, Bead/Tracking, and Force Data
%

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

   FileTable{k} = shorten_metadata(metadata);
   
   Fid = metadata.File.Fid;

   Zn = height(metadata.Results.TimeHeightVidStatsTable);
   Ztable{k} = metadata.Results.TimeHeightVidStatsTable;
   Ztable{k}.Fid = repmat(Fid, Zn, 1);

   % DatenumTime is the number of days since 0-Jan-0000 (proleptic ISO calendar)
   Ztable{k}.DatenumTime = Ztable{k}.Time;
   
   % Time = relative number of seconds since beginning the experiment
   Ztable{k}.Time = Ztable{k}.Time * (60 * 60 * 24); % convert from days to seconds
   Ztable{k}.Time = (Ztable{k}.Time - Ztable{k}.Time(1));
   
   
   firstframe = metadata.Results.FirstFrame;
   lastframe = metadata.Results.LastFrame;
   
   
   % Loads a tracking data table
   % Need to use original VST tracking file to find how many beads existed 
   % on the first frame.
   origtracks = load_video_tracking(origfname, [], [], [], 'absolute', [], 'table');

   VSTfirstframe = origtracks(origtracks.Frame == 1, :);
   FirstFrameBeadCount = height(VSTfirstframe);
   
   FileTable{k}.FirstFrameBeadCount = FirstFrameBeadCount;
   FileTable{k}.StartTime = datetime(Ztable{k}.DatenumTime(1), 'ConvertFrom', 'datenum');
   BeadInfoTable{k} = ba_discoverbeads(firstframe, lastframe, search_radius_low, search_radius_high, Fid);   
   BeadInfoTable{k} = ba_match_VST_and_MAT_tracks(BeadInfoTable{k}, VSTfirstframe);

   TrackingTable{k} = load_evtfile(evtname);
   TrackingTable{k}.Fid = repmat(Fid, height(TrackingTable{k}), 1);


   % % Debug figure
   % figure;
   % plot(origtracks.Frame, origtracks.Z, '.');
   % title(['Ztracks- ', origfname], 'Interpreter','none');
   % xlabel('frame'); ylabel('z-disp [um]');
 
end

FileTable = vertcat(FileTable{:});
FileTable.PlateID = categorical(string(FileTable.PlateID));
FileTable = movevars(FileTable, 'PlateID', 'before', 'Fid');

Ztable = vertcat(Ztable{:});
Ztable = movevars(Ztable, {'Frame', 'Time', 'ZHeight', 'Mean', 'StDev', 'Max', 'Min'}, 'after', 'Fid');
BeadInfoTable = vertcat(BeadInfoTable{:});
TrackingTable = vertcat(TrackingTable{:});

%
outs.FileTable = FileTable;
outs.TimeHeightVidStatsTable = Ztable;
outs.BeadInfoTable = BeadInfoTable;
outs.TrackingTable = TrackingTable;

cd(rootdir);

end


function sm = shorten_metadata(metadata)

    tocat = @(x)categorical(x);

    w = metadata.File.Well;
    [r,c] = ba_wellnum2rc(w);

    sm.PlateID = metadata.PlateID;
    sm.Fid = metadata.File.Fid;
    sm.Well = tocat(w);
    [sm.PlateRow, sm.PlateColumn] = deal(tocat(r), tocat(c));
    sm.FullFilename = string(fullfile(metadata.File.Binpath, metadata.File.Binfile));
    sm.StartTime = metadata.Results.TimeHeightVidStatsTable.Time(1);
    sm.MeanFps  = 1 ./ mean(diff(metadata.Results.TimeHeightVidStatsTable.Time*86400));
    sm.ExposureTime = metadata.Video.ExposureTime;
    sm.Binfile = string(metadata.File.Binfile);
    sm.SampleName = string(metadata.File.SampleName);
    sm.BeadChemistry = string(metadata.Bead.SurfaceChemistry);
    sm.BeadExpectedDiameter = metadata.Bead.Diameter;
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

