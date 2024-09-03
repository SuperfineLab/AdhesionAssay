

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
mylinecolor = lines(7);
    
startdir = pwd;

% set these to true when running an analysis the first time and to false
% thereafter
improveBadFitsTF = false;
savedatafilesTF = false;

% grouping variable for the STUDY (not when loading the data)
groupvars = {'SubstrateChemistry', 'BeadChemistry', 'Media', 'pH'};

% Loading the data and computing the plate-level stats and force curves
% requires that "PlateID" (and possibly 'PlateColumn') be 
% a "grouping variable."
% loaddata_groupvars = unique(['PlateID', 'PlateColumn', groupvars], 'stable');
loaddata_groupvars = unique(['PlateID', groupvars], 'stable');

% all-data-path
if ismac
    adp = '/Users/stevesnare/adhesion_data/datasets_NOTvideo/';
else
    adp = 'K:\expts\AdhesionAssay\datasets_NOTvideo\';
end

BeadColorTable = ba_BeadColorTable;

DataSetDirs = get_dataset_list;

% Load the data sources (one source per plate), attach the PlateID, and then 
% concatenate into one big table.
%
% ** The load_bigstudy_data function is at the very bottom of this file. **
if ~exist('Broot', 'var')
    Broot = load_bigstudy_data(adp, DataSetDirs, loaddata_groupvars, improveBadFitsTF, savedatafilesTF );   
end

% Improve poorly-discovered force curve fits, if necessary
if improveBadFitsTF
    [Broot.ForceFitTable, ...
     Broot.OptimizedStartTable] = ba_improve_bad_fits(Broot.ForceFitTable, ...
                                                      Broot.OptimizedStartTable, ...
                                                      loaddata_groupvars);    
end

if ~isfield(Broot,'DetachForceTable')
    Broot.DetachForceTable = ba_decouple_modes(Broot.ForceFitTable, loaddata_groupvars);
end
Bclean = clean_bigstudy_data(Broot);


%
% % Clean out the PWM and SNA
%
BeadChemsToKeep = {'PEG', 'WGA', 'HBE'};
Bclean = ba_clean_beadchem(Bclean, BeadChemsToKeep);

% Load in the control plate data...
if ~exist('Bcontrol', 'var')
    Bcontrol = load('K:\expts\AdhesionAssay\AdhesionAssay_2024ControlStudy\2024.08.03_cerium_Broot_CONTROLstudy_repairedBeadInfo.mat');
    Bcontrol = Bcontrol.Broot;
    Bcontrol.DetachForceTable = ba_decouple_modes(Bcontrol.ForceFitTable, loaddata_groupvars);
end
Bcontrol = clean_bigstudy_data(Bcontrol);

% plateNames(:,1) = unique(Bclean.FileTable.PlateID);

% combine both control and big datasets
B = ba_combine_runs(Bcontrol, Bclean);

fscatter = plot_scatterforces(B.DetachForceTable);

%% Running stats on the distilled data after manual optimization
% % After manually optimizing the force fit curves for one or two modes...
% % Set up the distilled results for running statistics.
AttachedThreshold = mean([-1.16 -0.2496]); % two COOH ModeForces
AttachedThreshold = -0.65;
DetachForceTable.AttachedTF = (DetachForceTable.ModeForce > AttachedThreshold);
detachgroupvars = [groupvars, 'AttachedTF'];
[g, gT] = findgroups(DetachForceTable(:,detachgroupvars));
gT.MeanForce = splitapply(@mean, DetachForceTable.ModeForce, g);
gT.MedianForce = splitapply(@median, DetachForceTable.ModeForce, g);
gT.StdForce = splitapply(@std, DetachForceTable.ModeForce, g);
gT.N = splitapply(@numel, DetachForceTable.ModeForce, g);
groupnames = join(string(table2cell(gT(:,detachgroupvars))),'_');
idx = DetachForceTable.AttachedTF;

figure; 
boxchart(g(idx), DetachForceTable.ModeForce(idx), 'Notch', 'on');

grpidx = unique(g(idx));

% DetachForceTable.SubstrateChemistry == "PEG" & ...
subgroup = (DetachForceTable.Media == 'Int5xPBS' & ...
            DetachForceTable.pH == "7" & ...
            DetachForceTable.AttachedTF);
subT = DetachForceTable(subgroup, :);
subT.BeadChemistry = categorical(subT.BeadChemistry, ["COOH", "PEG", "WGA", "HBE"], 'Ordinal', true);
subT.SubstrateChemistry = categorical(subT.SubstrateChemistry, ["COOH", "PEG", "HBE"], 'Ordinal', true);
subT = sortrows(subT, {'SubstrateChemistry','BeadChemistry'}, {'ascend','ascend'});
[gs, gsT] = findgroups(subT(:,{'SubstrateChemistry', 'BeadChemistry'}));
mylabels = join(string(table2cell(fliplr(gsT))),':');

figure;
hold on
boxchart(gs,subT.ModeForce, 'Notch','off', 'BoxFaceColor', mylinecolor(2,:));
swarmchart(gs, subT.ModeForce, 12, [0.8 0.8 0.2], 'filled');
ax = gca;
ax.XTick = [1:numel(mylabels)]';
ax.XTickLabel = mylabels;
ax.TickLabelInterpreter = 'none';
ax.YLim = [-2 2.5];
grid

ax.XLabel.Rotation = deg2rad(30);
%%
ax = gca;
ax.XTick = [1:30];
ax.XTickLabel = [1:30];
ax = gca;
ax.XTick = [1:30];
ax.XTickLabel = groupnames(grpidx)';
ax.TickLabelInterpreter = 'none';

% 
% Anova code
%
testconditions{1} = (DetachForceTable.SubstrateChemistry == 'PEG' | ...
                     DetachForceTable.SubstrateChemistry == 'HBE' && ...
                     DetachForceTable.Media == "NoInt" && ...
                     DetachForceTable.pH = "");
for k = 1:numel(testconditions)
    AnovaT = DetachForceTable;
    AnovaT = AnovaT( mygroup(k), :);

    [ag, agT] = findgroups(AnovaT(:,{'SubstrateChemistry', 'BeadChemistry'}));

niT.groupname = join([string(niT.BeadChemistry), string(niT.SubstrateChemistry)], ':');
niT.BeadChemistry = categorical(niT.BeadChemistry, ["COOH", "PEG", "WGA", "HBE"], 'Ordinal', true);
niT.SubstrateChemistry = categorical(niT.SubstrateChemistry, ["COOH", "PEG", "HBE"], 'Ordinal', true);

[ag, agT] = findgroups(niT(:,{'SubstrateChemistry', 'BeadChemistry'}));
agT_groupNames = join(fliplr(string(table2cell(agT))),':');
agNames = agT_groupNames(ag);

%% Bartlett test for equal variances. If sample-data fails this (p<0.05),
%  then the standard anova1 (manova?) does not work. 
bartTest = vartestn(DetachForceTable.ModeForce, factorNames(gd));
if bartTest > 0.05
    logentry('Equal variances test has passed. Standard ANOVA applies.');
    an = anova1(DetachForceTable.ModeForce, factorNames(gd));
else
    % Move on to Kruskel-Wallis test
    logentry('Variances between groups are statistically different. Will use Kruskal-Wallis.');
    [kw.p, kw.tbl, kw.stats] = kruskalwallis(DetachForceTable.ModeForce, factorNames(gd));
    figure; [mc.c, mc.m, mc.h, mc.gnames] = multcompare(kw.stats);
end


end

%% Multi-variate anova (manova)
maov = manova(factorNames(gd), DetachForceTable.ModeForce);
m = multcompare(maov, 'CriticalValueType', 'bonferroni')










% if ~isfield(B, 'BeadRollingTable')
%     B.BeadRollingTable = ba_simple_check_for_rolling(B);
% end
% RollingForceTable = innerjoin(B.BeadForceTable,B.BeadRollingTable,'Keys','Fid');
% 
% figure; 
% histogram(B.BeadRollingTable.MaxRxy(~isnan(B.BeadRollingTable.MaxRxy))*0.692,[0:24:30*24]);
% xlabel('Maximum radial disp before detachment [\mum]');
% ylabel('count');
% 
% figure;
% plot(RollingForceTable.MaxRxy*0.692,RollingForceTable.Force*1e9,'.');
% xlabel('Maximum radial disp before detachment [\mum]')
% ylabel('Force [nN]');
% ax.XScale = 'log';









% % I first want to calculate some **BASIC** statistics on the repeat
% % measurements within a plate. The protocol right now is to run each
% % condition in triplicate. This aggregates each set of replicates into a
% % single dataset/sample in each plate for each test condition.
% [g, PlateStatsT] = findgroups(B.FileTable(:,groupvars));
% PlateStatsT.Nvideos    = splitapply(@numel, B.FileTable.Fid, g);
% PlateStatsT.FirstBeads = splitapply(@sum, B.FileTable.FirstFrameBeadCount, g);
% PlateStatsT.LastBeads  = splitapply(@sum, B.FileTable.LastFrameBeadCount, g);
% PlateStatsT.StuckPercent = PlateStatsT.LastBeads ./ PlateStatsT.FirstBeads * 100;        
% PlateStatsT.VisCol = grp2idx(PlateStatsT.BeadChemistry);        
% PlateStatsT.VisRow = grp2idx(PlateStatsT.PlateID);
% 
% % This section just creates a set of xaxis and yaxis labels consistent with
% % categorical values within the constructed tables. In other words, here,
% % we want to pull out whatever bead chemistries and Plate IDs are represented 
% % and put them in the "right" places on the xaxis and yaxis, respectively. 
% [~, gxT] = findgroups(PlateStatsT(:,{'BeadChemistry'}));
% xstrings = string(table2array(gxT));
% [~, gyT] = findgroups(PlateStatsT(:,groupvars));
% % gyT.PlateID = reordercats(gyT.PlateID, plateNames');
% ystrings = string(plateNames);
% 
% Forces = innerjoin(B.DetachForceTable, PlateStatsT, 'Keys', groupvars);
% Forces = innerjoin(Forces, BeadColorTable);
% 
% SummaryDataT = innerjoin(Forces, PlateStatsT);
% sz = [max(SummaryDataT.VisRow), max(SummaryDataT.VisCol)];
% pmat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, SummaryDataT.StuckPercent);
% plot_FuncSurface(pmat, seabreeze(50), 'Percent Stuck Beads', xstrings, ystrings);
% clim([0 100])
% 
% % %
% %   Average repeated plates
% % %
% [g3, AvgPlatesT] = findgroups(SummaryDataT(:,groupvars));
% 
% AvgPlatesT.Nvideos    = splitapply(@(x)sum(x, 'omitnan'), SummaryDataT.Nvideos, g3);
% AvgPlatesT.FirstBeads = splitapply(@(x)sum(x, 'omitnan'), SummaryDataT.FirstBeads, g3);
% AvgPlatesT.LastBeads  = splitapply(@(x)sum(x, 'omitnan'), SummaryDataT.LastBeads, g3);
% AvgPlatesT.StuckPercent = AvgPlatesT.LastBeads ./ AvgPlatesT.FirstBeads * 100;       
% 
% AvgPlatesT.Force = splitapply(@(x){catcells(x)}, SummaryDataT.ModeForce, g3);
% AvgPlatesT.MedianForce = cell2mat(cellfun(@(x)median(x, 'omitnan'), AvgPlatesT.Force, 'UniformOutput', false));
% AvgPlatesT.MeanForce = cell2mat(cellfun(@(x)mean(x,'omitnan'), AvgPlatesT.Force, 'UniformOutput', false));
% AvgPlatesT.StdForce = cell2mat(cellfun(@(x)std(x(:), [], 'omitnan'), AvgPlatesT.Force, 'UniformOutput', false));
% AvgPlatesT.StdErrForce = cell2mat(cellfun(@(x)stderr(x(:), 1, [], 'omitnan'), AvgPlatesT.Force, 'UniformOutput', false));
% AvgPlatesT.NForces = cell2mat(cellfun(@(x)sum(~isnan(x)), AvgPlatesT.Force, 'UniformOutput', false));
% AvgPlatesT.MadForce = cell2mat(cellfun(@(x)mad(x(:), 1), AvgPlatesT.Force, 'UniformOutput', false));
% AvgPlatesT.IQR = cell2mat(cellfun(@(x)iqr(x(:), 1), AvgPlatesT.Force, 'UniformOutput', false));
% 
% AvgPlatesT.BeadChemistry = reordercats(AvgPlatesT.BeadChemistry, {'PEG', 'WGA', 'HBE'});
% AvgPlatesT.yLabel = join([string(AvgPlatesT.SubstrateChemistry), string(AvgPlatesT.Media), string(AvgPlatesT.pH)], ', ');
% 
% 
% % figure; 
% % h = heatmap(AvgPlatesT, 'BeadChemistry', 'yLabel', 'ColorVariable', 'StuckPercent', 'CellLabelFormat','%3.0f','ColorMethod','none');
% % h.YDisplayData = flipud(h.YDisplayData);  % equivalent to 'YDir', 'Reverse'
% % clim([0 100]);
% 
% caseorder = {...             
%              'PEG_NoInt_7', ...
%              'HBE_NoInt_7', ...
%              'HBE_NoInt_2.5', ...             
%              'HBE_IntNP40_7', ...
%              'HBE_Int5xPBS_7', ...
%              };
% 
% ystrings = caseorder;
% 
% tmpT = AvgPlatesT(:,{'SubstrateChemistry','Media', 'pH'});
% AvgPlatesT.Cases = categorical(join(string(table2array(tmpT)),'_'));
% AvgPlatesT.Cases = reordercats(AvgPlatesT.Cases, caseorder);
% AvgPlatesT.VisRow = grp2idx(AvgPlatesT.Cases);
% AvgPlatesT.VisCol = grp2idx(AvgPlatesT.BeadChemistry);        
% 
% [g3x, g3xT] = findgroups(AvgPlatesT(:,{'BeadChemistry'}));
% xstrings = string(table2array(g3xT));
% 
% sz = [max(AvgPlatesT.VisRow), max(AvgPlatesT.VisCol)];
% pmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.StuckPercent);
% plot_FuncSurface(pmat, seabreeze(25), 'Percent Stuck Beads', xstrings, ystrings);
% clim([0 100])
% 

% % % % 
% % %  Anova code
% % % %
% % BigT = innerjoin(B.FileTable, B.BeadForceTable);
% % hbeT = BigT( BigT.SubstrateChemistry == 'HBE', :);
% % hbeT = hbeT( hbeT.Media == "IntNANA" | hbeT.Media == "NoInt", :);
% % if iscategorical(hbeT.MediumNANAConc)
% %     nanatmp = arrayfun(@str2num,string(hbeT.MediumNANAConc));
% % else
% %     nanatmp = gnanaT.MediumNANAConc;
% % end
% % hbeT.MediaAll = join([string(hbeT.Media), string(num2str(nanatmp, '%.0e'))]);
% % [ag, agT] = findgroups(hbeT(:,{'BeadChemistry', 'MediaAll'}));
% % % foo = anova1(hbeT.Force, ag);
% % % an = anovan(hbeT.Force, {hbeT.BeadChemistry, hbeT.MediaAll}, 'model', 2, 'varnames', {'Bead Chemistry', 'Medium'});


% %
%   Plotting Functions
% %


% % %
% %   OLD Plotting Functions
% % %
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


    
function DataSetDirs = get_dataset_list

    DataSrcs = { ...
                 'ba_210802pegni',        '2021.08.02__mPEGslideNonInterfering'; ...
                 'ba_230724pegni',        '2023.07.24__Rho-PEGslide_HBE+lectins'; ... 
                 'ba_230915pegni',        '2023.09.15__PEGslide_NoInt-stdbeadset'; ... 
                 'ba_231024pegni',        '2023.10.24__PEGslide_noint_stdbeadset'; ...
                 'ba_231025pegni',        '2023.10.25__PEGslide_noint_stdbeadset'; ...
                 'ba_240111pegni',        '2024.01.11__mPEGslide_StandardBeadSet_noint'; ... 
                 'ba_240124pegni',        '2024.01.24__mPEGslide_StdBeadset_noint'; ...
                 'ba_210802ni',           '2021.08.02__HBEslideNonInterfering'; ... 
                 'ba_210805ni',           '2021.08.05__HBEslideNonInterfering_Trial2'; ...
                 'ba_210910ni',           '2021.09.10__HBEslideNonInterfering_Trial3'; ... 
                 'ba_230721ni',           '2023.07.21__HBEslide_HBE+lectins'; ...      
                 'ba_240110ni',           '2024.01.10__HBEslide_StandardBeadSet_noint'; ... 
                 'ba_220901nilowph',      '2022.09.01__pH2p6_NoInt_assortedbeads'; ...
                 'ba_230801nilowph',      '2023.08.01__HBEslide_NoIntpH2p5-stdbeadset'; ...
                 'ba_230804nilowph',      '2023.08.04__HBEslide_NoIntpH2p5-stdbeads'; ...
                 'ba_240209nilowph',      '2024.02.09__HBEslide_NoIntpH2p5_stdbeadset'; ...
                 'ba_240408nilowph',      '2024.04.05__HBEslide_NoIntpH2p5_stdbeadset'; ...
                 'ba_220922inp40',        '2022.09.22__media-0p1pctNP40_HBEplate'; ...
                 'ba_230801inp40',        '2023.08.01__HBEslide_0p1pctNP40-stdbeadset'; ...
                 'ba_230804inp40',        '2023.08.04__HBEslide_IntNP40-stdbeadset'; ...                       
                 'ba_230907inp40',        '2023.09.07__HBEslide_0p1pctNP40'; ...   
                 'ba_230914inp40',        '2023.09.14__HBEslide_IntNP40-stdbeadset'; ...   
% % % % % %                  'ba_240125coohni',       '2024.01.25__COOHslide_COOHbeads_noint'; ...
% % % % % %                  'ba_240126pegni',        '2024.01.26__mPEGslide_mPEGbeads_noint'; ...
% % % % % %                  'ba_220623ni',           '2022.06.23__HBEbeads_HBEplate_homogeneity_test'; ...
% % % % % %                  'ba_240129ni',           '2024.01.29__HBEslide_HBEbeads_noint'; ...
% % % % % %                  'ba_240130ni',           '2024.01.30__HBEslide2_HBEbeads_noint'; ...
                 'ba_230921i5xPBS',       '2023.09.21__HBEslide_PBS5X_stdbeadset'; ... 
                 'ba_230922i5xPBS',       '2023.09.22__HBEslide_PBS5X_stdbeadset'; ... 
                 'ba_230925i5xPBS',       '2023.09.25__HBEslide_PBS5X_stdbeadset_parafilmpoletip'; ... 
                 'ba_240206i5xPBS',       '2024.02.06__HBEslide_PBS5X_stdbeadset'; ...
                 'ba_240207i5xPBS',       '2024.02.07__HBEslide_PBS5X_stdbeadset'; ...
                 'ba_240208i5xPBS',       '2024.02.08__HBEslide_PBS5X_stdbeadset'; ...
                 };

    DataSetDirs(:,1) = DataSrcs(:,2);
end