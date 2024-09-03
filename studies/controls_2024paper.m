
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

rootdir = pwd;
mylinecolor = lines(7);

improveBadFitsTF = false;
savedatafilesTF = false;
% recalculateTF = true;

% grouping variable for the STUDY (not when loading the data)
% groupvars = {'PlateID', 'PlateColumn','SubstrateChemistry', 'BeadChemistry', 'Media', 'pH'};
groupvars = {'PlateColumn', 'BeadChemistry', 'SubstrateChemistry'};

% Loading the data and computing the plate-level stats and force curves
% requires that "PlateID" (and possibly 'PlateColumn') be 
% a "grouping variable."
% loaddata_groupvars = unique(['PlateID', 'PlateColumn', groupvars], 'stable');
loaddata_groupvars = unique(['PlateID', groupvars], 'stable');

DataSetDirs = get_dataset_list;

% all-data-path
if ismac
    adp = '/Users/stevesnare/adhesion_data/datasets_NOTvideo/';
else
    adp = 'K:\expts\AdhesionAssay\datasets_NOTvideo\';
end

% check for already cleaned datafile
cleanfile = dir('K:\expts\AdhesionAssay\AdhesionAssay_2024ControlStudy\2024.08.26_cerium_Broot_CONTROLstudy_COLUMNwise_sampling_manually-adjusted-mode-count.UIedited.mat');
if ~isempty(cleanfile)
    cleandata = load(cleanfile.name);
    ForceFitTable = cleandata.ForceFitTable;
    DetachForceTable = ba_decouple_modes(ForceFitTable, groupvars);
elseif ~exist('Broot', 'var')
    % Load the data sources (one source per plate), attach the PlateID, and then 
    % concatenate into one big table.
    %
    % ** The load_bigstudy_data function is at the very bottom of this file. **
    Broot = load_bigstudy_data(adp, DataSetDirs, loaddata_groupvars, improveBadFitsTF, savedatafilesTF );   

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
    B = clean_bigstudy_data(Broot);    
end


DetachForceTable.BeadChemistry = categorical(DetachForceTable.BeadChemistry, ["COOH", "PEG", "WGA", "HBE"], 'Ordinal', true);
DetachForceTable.SubstrateChemistry = categorical(DetachForceTable.SubstrateChemistry, ["COOH", "PEG", "HBE"], 'Ordinal', true);
DetachForceTable = sortrows(DetachForceTable, {'SubstrateChemistry','BeadChemistry'}, {'ascend','ascend'});

AttachedForceThreshold = -0.65; % mean of two COOH ModeForces
DetachForceTable.AttachedTF = (DetachForceTable.ModeForce > AttachedForceThreshold);
detachgroupvars = [groupvars, 'AttachedTF'];

ScaleThreshold = 0.25;
LowScaleTF = (DetachForceTable.ModeScale <= ScaleThreshold);
DetachForceTable(LowScaleTF,:) = [];

% [gd, gdT] = findgroups(DetachForceTable(:,{'BeadChemistry', 'SubstrateChemistry'}));
% factorNames = join(string(table2cell(gdT)),':');

% [gd, gdT] = findgroups(DetachForceTable(:,{'BeadChemistry', 'SubstrateChemistry', 'AttachedTF'}));
% factorNames = join(string(table2cell(gdT)),':');

% [gd, gdT] = findgroups(DetachForceTable(:,{'PlateID'}));
% factorNames = string(table2cell(gdT));

[gd, gdT] = findgroups(DetachForceTable(:,{'PlateID', 'AttachedTF'}));
factorNames= join(string(table2cell(gdT)));

f = figure;
hold on
boxchart(gd, DetachForceTable.ModeForce, 'Notch','off', 'BoxFaceColor', mylinecolor(2,:));
swarmchart(gd, DetachForceTable.ModeForce, 12, [0.3 0.3 0.3], 'filled');
ax = gca;
ax.XTick = [1:numel(factorNames)]';
ax.XTickLabel = factorNames;
ax.TickLabelInterpreter = 'none';
ax.YLim = [-1.5 1.5];
grid

% [ag, agT] = findgroups(niT(:,{'SubstrateChemistry', 'BeadChemistry'}));
% agT_groupNames = join(fliplr(string(table2cell(agT))),':');
% agNames = agT_groupNames(ag);


%% Bartlett test for equal variances. If sample-data fails this (p<0.05),
%  then the standard anova1 (manova?) does not work. 
bartTest = vartestn(DetachForceTable.ModeForce, factorNames(gd)) 
if bartTest > 0.05
    logentry('Equal variances test has passed. Standard ANOVA applies.');
    %% Multi-variate anova (manova)
    maov = manova(factorNames(gd), DetachForceTable.ModeForce);
    m = multcompare(maov, 'CriticalValueType', 'bonferroni');
    disp(m)
    add_sigstar(m, f)

else
    % Move on to Kruskel-Wallis test
    logentry('Variances between groups are not equal. Will use Kruskal-Wallis.');
    [kw.p, kw.tbl, kw.stats] = kruskalwallis(DetachForceTable.ModeForce, factorNames(gd));
    
    figure; 
    [mc.c, mc.m, mc.h, mc.gnames] = multcompare(kw.stats);
    ax = gca;
    ax.TickLabelInterpreter = 'none';
    % ax.Xlabel.Interpreter = 'none';
end



%% external functions
function DataSetDirs = get_dataset_list
    DataSetDirs = { ...
                    '2024.01.25__COOHslide_COOHbeads_noint'; ...
                    '2024.01.26__mPEGslide_mPEGbeads_noint'; ...
    %               '2022.06.23__HBEbeads_HBEplate_homogeneity_test'; ...
                    '2024.01.29__HBEslide_HBEbeads_noint'; ...
                    '2024.01.30__HBEslide2_HBEbeads_noint'; ...
                  };
end


function out = add_sigstar(m, fig)

    m = m(m.pValue < 0.05, :);

    if ~isempty(m)
        ComparedNames = table2cell(m(:,{'Group1','Group2'}));
        ComparedNames = cellfun( @(x1,x2){char(x1),char(x2)}, ComparedNames(:,1), ComparedNames(:,2), 'UniformOutput', false);
    
    
        figure(fig);
        sigstar(ComparedNames, m.pValue);
    end
    out = 0;
end