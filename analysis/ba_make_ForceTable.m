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


cd(rootdir);
 
outs.ForceTable = ForceTable;

end






