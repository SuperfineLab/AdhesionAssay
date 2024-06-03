
% This sets the path for addpath/genpath for Stephen's mac or Jeremy's 
% pc depending on who is running the code
if ismac
    path_for_genpath = '/Users/stevesnare/code';
else
    path_for_genpath = 'D:\jcribb\src';
end

addpath(genpath([path_for_genpath, filesep, '3dfmAnalysis']));
addpath(genpath([path_for_genpath, filesep, 'AdhesionAssay']));

% close all

improveBadFitsTF = true;
savedatafilesTF = true;

% groupvars = {'PlateColumn', 'SubstrateChemistry', 'BeadChemistry', ...
%              'Media', 'pH'};

groupvars = {'PlateID', 'SubstrateChemistry', 'BeadChemistry', 'Media', 'pH'};


% all-data-path
if ismac
    adp = '/Users/stevesnare/adhesion_data/datasets_NOTvideo/';
else
    adp = 'K:\expts\AdhesionAssay\datasets_NOTvideo\';
end

DataSetDirs = { ...
                '2024.01.25__COOHslide_COOHbeads_noint'; ...
                '2024.01.26__mPEGslide_mPEGbeads_noint'; ...
%               '2022.06.23__HBEbeads_HBEplate_homogeneity_test'; ...
                '2024.01.29__HBEslide_HBEbeads_noint'; ...
                '2024.01.30__HBEslide2_HBEbeads_noint'; ...
              };

rootdir = pwd;

% Load the data sources (one source per plate), attach the PlateID, and then 
% concatenate into one big table.
%
% ** The load_bigstudy_data function is at the very bottom of this file. **
if ~exist('Broot', 'var')       
    Broot = load_bigstudy_data(adp, DataSetDirs, groupvars, improveBadFitsTF, savedatafilesTF );    
end
B = clean_bigstudy_data(Broot);

% Improve fits based on all fits statistics...
[NewForceFitTable, NewOptimizedStartTable] = ba_improve_bad_fits(B.ForceFitTable, B.OptimizedStartTable, groupvars);

%
% % Clean out the PWM and SNA
%
BeadChemsToKeep = {'COOH', 'PEG', 'HBE'};
idxFile = ismember(B.FileTable.BeadChemistry, BeadChemsToKeep);

FiltData.FileTable = B.FileTable(idxFile,:);
FiltData.FileTable.BeadChemistry = removecats(FiltData.FileTable.BeadChemistry);
FiltData.FileTable.BeadChemistry = reordercats(FiltData.FileTable.BeadChemistry, BeadChemsToKeep);

FidToKeep = FiltData.FileTable.Fid;

idxTime     = ismember(B.TimeHeightVidStatsTable.Fid, FidToKeep);
idxBead     = ismember(B.BeadInfoTable.Fid, FidToKeep);
idxTracking = ismember(B.TrackingTable.Fid, FidToKeep);
idxForce    = ismember(B.BeadForceTable.Fid, FidToKeep);
idxDetach   = ismember(B.ForceFitTable.BeadChemistry, BeadChemsToKeep);

FiltData.TimeHeightVidStatsTable = B.TimeHeightVidStatsTable(idxTime,:);
FiltData.BeadInfoTable = B.BeadInfoTable(idxBead,:);
FiltData.TrackingTable = B.TrackingTable(idxTracking,:);
FiltData.BeadForceTable    = B.BeadForceTable(idxForce,:);
FiltData.ForceFitTable = B.ForceFitTable(idxDetach,:);
FiltData.ForceFitTable.BeadChemistry = removecats(FiltData.ForceFitTable.BeadChemistry);

OrigData = B;
B = FiltData;

plateNames(:,1) = unique(B.FileTable.PlateID);

% Calculate basic statistics on the repeat measurements within a plate. 
% The assay protocol for a plate runs each condition in triplicate. This 
% aggregates each set of replicates into a single dataset/sample in each 
% plate for each test condition.
[g, PlateStatsT] = findgroups(B.FileTable(:,['PlateID', groupvars]));
PlateStatsT.Nvideos    = splitapply(@numel, B.FileTable.Fid, g);
PlateStatsT.FirstBeads = splitapply(@sum, B.FileTable.FirstFrameBeadCount, g);
PlateStatsT.LastBeads  = splitapply(@sum, B.FileTable.LastFrameBeadCount, g);
PlateStatsT.StuckPercent = PlateStatsT.LastBeads ./ PlateStatsT.FirstBeads * 100;        
PlateStatsT.VisCol = grp2idx(PlateStatsT.BeadChemistry);        
PlateStatsT.VisRow = grp2idx(PlateStatsT.PlateID);
% PlateStatsT.VisRow = grp2idx(reordercats(PlateStatsT.PlateID, plateNames'));

% This section just creates a set of xaxis and yaxis labels consistent with
% categorical values within the constructed tables. In other words, here,
% we want to pull out whatever bead chemistries and Plate IDs are represented 
% and put them in the "right" places on the xaxis and yaxis, respectively. 
[~, gxT] = findgroups(PlateStatsT(:,{'BeadChemistry'}));
xstrings = string(table2array(gxT));
[~, gyT] = findgroups(PlateStatsT(:,groupvars));
% gyT.PlateID = reordercats(gyT.PlateID, plateNames');
ystrings = string(plateNames);


% ForceFitVars = {'PlateID', 'PlateColumn', 'BeadChemistry', 'SubstrateChemistry', 'Media', ...
%               'pH', 'DetachForce', 'confDetachForce'};

ForceFitVars = {'PlateID',  'BeadChemistry', 'SubstrateChemistry', 'Media', ...
              'pH', 'DetachForce', 'relwidthDetachForce'};

Forces = innerjoin(B.ForceFitTable(:,ForceFitVars), PlateStatsT, 'Keys', ['PlateID' groupvars]);


SummaryDataT = innerjoin(Forces, PlateStatsT);
sz = [max(SummaryDataT.VisRow), max(SummaryDataT.VisCol)];
fmat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, abs(SummaryDataT.DetachForce));
fmat(isnan(fmat)) = 0;
plot_FuncSurface(fmat, pinefresh(255), 'Pulloff Force [nN]', xstrings, ystrings);
clim([0 15]);




% %
%   Plotting Functions
% %
function plot_FuncSurface(data, clrmap, titlestring, xstrings, ystrings)
    if nargin < 5 || isempty(ystrings)
        ystrings = 1:size(data,1);
    end
    
    if nargin < 4 || isempty(xstrings)
        xstrings = 1:size(data,2);
    end

    figure;
    imagesc(abs(data));
    xlabel('Bead Functionalization');
    ylabel('Substrate Funct -- Media');
    title(titlestring);
    colorbar;
    colormap(clrmap)
    ax = gca;
    ax.YTick = 1:numel(ystrings);
    ax.YTickLabel = ystrings;
    ax.FontSize = 13;
    ax.XTickLabel = xstrings;
    ax.TickLabelInterpreter = 'none';
    ax.TickLength = [0 0];
    drawnow;
end

