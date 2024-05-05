

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

startdir = pwd;

savedatafilesTF = true;

aggregating_variables = {'PlateID', 'SubstrateChemistry', 'BeadChemistry', ...
                         'Media', 'pH'};

% all-data-path
if ismac
    adp = '/Users/stevesnare/adhesion_data/datasets_NOTvideo/';
else
    adp = 'K:\expts\AdhesionAssay\datasets_NOTvideo\';
end

DataSetDirs = get_dataset_list;

% Load the data sources (one source per plate), attach the PlateID, and then 
% concatenate into one big table.
%
% ** The load_bigstudy_data function is at the very bottom of this file. **
if ~exist('Broot', 'var')
    Broot = load_bigstudy_data(adp, DataSetDirs, aggregating_variables, savedatafilesTF );    
end
B = clean_bigstudy_data(Broot);

%
% % Clean out the PWM and SNA
%
BeadChemsToKeep = {'PEG', 'WGA', 'HBE'};
idxFile = ismember(B.FileTable.BeadChemistry, BeadChemsToKeep);

FiltData.FileTable = B.FileTable(idxFile,:);
FiltData.FileTable.BeadChemistry = removecats(FiltData.FileTable.BeadChemistry);
FiltData.FileTable.BeadChemistry = reordercats(FiltData.FileTable.BeadChemistry, BeadChemsToKeep);

FidToKeep = FiltData.FileTable.Fid;

idxTime     = ismember(B.TimeHeightVidStatsTable.Fid, FidToKeep);
idxBead     = ismember(B.BeadInfoTable.Fid, FidToKeep);
idxTracking = ismember(B.TrackingTable.Fid, FidToKeep);
idxForce    = ismember(B.ForceTable.Fid, FidToKeep);
idxDetach   = ismember(B.DetachForceTable.BeadChemistry, BeadChemsToKeep);

FiltData.TimeHeightVidStatsTable = B.TimeHeightVidStatsTable(idxTime,:);
FiltData.BeadInfoTable = B.BeadInfoTable(idxBead,:);
FiltData.TrackingTable = B.TrackingTable(idxTracking,:);
FiltData.ForceTable    = B.ForceTable(idxForce,:);
FiltData.DetachForceTable = B.DetachForceTable(idxDetach,:);
FiltData.DetachForceTable.BeadChemistry = removecats(FiltData.DetachForceTable.BeadChemistry);

OrigData = B;
B = FiltData;


plateNames(:,1) = unique(B.FileTable.PlateID);

% I first want to calculate some basic statistics on the repeat
% measurements within a plate. The protocol right now is to run each
% condition in triplicate. This aggregates each set of replicates into a
% single dataset/sample in each plate for each test condition.
[g, PlateStatsT] = findgroups(B.FileTable(:,aggregating_variables));
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
[~, gyT] = findgroups(PlateStatsT(:,aggregating_variables));
% gyT.PlateID = reordercats(gyT.PlateID, plateNames');
ystrings = string(plateNames);

DetachVars = {'PlateID', 'BeadChemistry', 'SubstrateChemistry', 'Media', ...
              'pH', 'DetachForce', 'relwidthDetachForce'};

Forces = innerjoin(B.DetachForceTable(:,DetachVars), PlateStatsT, 'Keys', aggregating_variables);


SummaryDataT = innerjoin(Forces, PlateStatsT);
sz = [max(SummaryDataT.VisRow), max(SummaryDataT.VisCol)];
fmat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, abs(SummaryDataT.DetachForce));

plot_FuncSurface(fmat, pinefresh(1000), '50% Pulloff Force [nN]', xstrings, ystrings);
clim([0 50]);


% %
%   Average repeated plates
% %
[g3, AvgPlatesT] = findgroups(SummaryDataT(:,{'SubstrateChemistry', 'BeadChemistry', 'Media', 'pH'}));

AvgPlatesT.Nvideos    = splitapply(@(x)sum(x, 'omitnan'), SummaryDataT.Nvideos, g3);
AvgPlatesT.FirstBeads = splitapply(@(x)sum(x, 'omitnan'), SummaryDataT.FirstBeads, g3);
AvgPlatesT.LastBeads  = splitapply(@(x)sum(x, 'omitnan'), SummaryDataT.LastBeads, g3);
AvgPlatesT.StuckPercent = AvgPlatesT.LastBeads ./ AvgPlatesT.FirstBeads * 100;       

AvgPlatesT.Force = splitapply(@(x){catcells(x)}, SummaryDataT.DetachForce, g3);
AvgPlatesT.MedianForce = cell2mat(cellfun(@(x)median(x, 'omitnan'), AvgPlatesT.Force, 'UniformOutput', false));
AvgPlatesT.MeanForce = cell2mat(cellfun(@(x)mean(x,'omitnan'), AvgPlatesT.Force, 'UniformOutput', false));
AvgPlatesT.StdForce = cell2mat(cellfun(@(x)std(x(:), [], 'omitnan'), AvgPlatesT.Force, 'UniformOutput', false));
AvgPlatesT.StdErrForce = cell2mat(cellfun(@(x)stderr(x(:), 1, [], 'omitnan'), AvgPlatesT.Force, 'UniformOutput', false));
AvgPlatesT.NForces = cell2mat(cellfun(@(x)sum(~isnan(x)), AvgPlatesT.Force, 'UniformOutput', false));
AvgPlatesT.MadForce = cell2mat(cellfun(@(x)mad(x(:), 1), AvgPlatesT.Force, 'UniformOutput', false));
AvgPlatesT.IQR = cell2mat(cellfun(@(x)iqr(x(:), 1), AvgPlatesT.Force, 'UniformOutput', false));

AvgPlatesT.BeadChemistry = reordercats(mygT.BeadChemistry, {'PEG', 'WGA', 'HBE'});
AvgPlatesT.yLabel = join([string(mygT.SubstrateChemistry), string(mygT.Media), string(mygT.pH)], ', ');


figure; 
h = heatmap(AvgPlatesT, 'BeadChemistry', 'yLabel', 'ColorVariable', 'MeanForce');

% q = splitapply(@(x,y)ba_bootstrap(x,y), 10.^(SummaryDataT.DetachForce), ...
%                                         [10.^(SummaryDataT.DetachForce) - 10.^(SummaryDataT.confDetachForce(:,1)), ...
%                                         10.^(SummaryDataT.confDetachForce(:,2) - 10.^(SummaryDataT.DetachForce))], ...
%                                         g3);
% 
% q = vertcat(q);
% AvgPlatesT.bootMeanForce = q(:,1); 
% AvgPlatesT.bootStdError =  q(:,2); 
% AvgPlatesT.bootCI        = q(:,3:4); 

% caseorder = {'mPEG_NoInt_0e+00', ...
%              'HBE_NoInt_0e+00', ...
%              'HBE_Int_4e-02', ...
%              'HBE_IntGlcNAc_0e+00', ...
%              'HBE_IntNANA_4e-05', ...
%              'HBE_IntNANA_4e-04', ...
%              'HBE_IntNANA_4e-02'}';
% ystrings  = {'mPEG_NoInt', ...
%              'HBE_NoInt', ...
%              'HBE_Int', ...
%              'HBE_GlcNAc', ...
%              'HBE_NANA_36µM', ...
%              'HBE_NANA_360µM', ...
%              'HBE_NANA_3.6mM'};

% caseorder = {'PEG_NoInt_0_7', ...
%              'HBE_NoInt_0_7', ...
%              'HBE_NoInt_0_2.5', ...
%              'HBE_IntNP40_0_7', ...
%              'HBE_IntGalactose_0_7', ...
%              'HBE_IntGlcNAc_0_7', ...
%              'HBE_IntNANA_3.65e-05_7', ...
%              'HBE_IntNANA_0.000365_7', ...
%              'HBE_IntNANA_0.0365_2.5', ...
%              'HBE_Int_0.0365_2.5', ...                          
%              'HBE_Int25knormpH_0.0365_7', ...
%               }; 

caseorder = {...             
             'PEG_NoInt_7', ...
             'HBE_NoInt_7', ...
             'HBE_NoInt_2.5', ...             
             'HBE_IntNP40_7', ...
             'HBE_Int5xPBS_7', ...
             };

ystrings = caseorder;

tmpT = AvgPlatesT(:,{'SubstrateChemistry','Media', 'pH'});
% tmpT.MediumNANAConc = categorical((tmpT.MediumNANAConc));
% tmpT.MediumNANAConc = categorical(num2str(char(tmpT.MediumNANAConc), '%.0e'));
AvgPlatesT.Cases = categorical(join(string(table2array(tmpT)),'_'));
AvgPlatesT.Cases = reordercats(AvgPlatesT.Cases, caseorder);
AvgPlatesT.VisRow = grp2idx(AvgPlatesT.Cases);
AvgPlatesT.VisCol = grp2idx(AvgPlatesT.BeadChemistry);        

[g3x, g3xT] = findgroups(AvgPlatesT(:,{'BeadChemistry'}));
xstrings = string(table2array(g3xT));

sz = [max(AvgPlatesT.VisRow), max(AvgPlatesT.VisCol)];
% pmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.StuckPercent);
% nmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.NForces);
% gmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.MedianForce);
% dmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.MadForce);
mmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.MeanForce);
% smat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.StdForce);
% zmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.StdErrForce);
% % bmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.bootMeanForce);
% % bsmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.bootStdError);
% % blclmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.bootCI(:,1));
% % buclmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.bootCI(:,2));
% 
% figure;
% barwitherr(bsmat, bmat);
% ax = gca;
% ax.XTickLabel = ystrings;
% ax.TickLabelInterpreter = 'none';
% legend('PEG', 'WGA', 'HBE');
% xlabel('');
% ylabel('Force [nN]');
% pretty_plot;
% 
% % Plotting the data for the averaged plates.
% % plot_FuncSurface(pmat, seabreeze(10), 'Percent Stuck Beads', xstrings, ystrings);
% % plot_FuncSurface(10.^gmat, seabreeze(10), 'Median Pulloff Force [nN]', xstrings, ystrings);
plot_FuncSurface(mmat, pinefresh(255), 'Mean Pulloff Force [nN] across plates', xstrings, ystrings);
% plot_FuncSurface(bmat, pinefresh(25), 'Bootstrap Mean Pulloff Force, main mode [nN]', xstrings, ystrings);



% % % % 
% % %  Anova code
% % % %
% % BigT = innerjoin(B.FileTable, B.ForceTable);
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






% function boxplot2(C, varargin)
%     fun = @(I)I*ones(numel(C{I}),1);
%     A = cell2mat(cellfun(col,col(C),'uni',0));
%     B = arrayfun(fun,col(1:numel(C)),'uni',0);
%     C = cell2mat(B);
%     boxplot(A,C,varargin{:})
% end

    
function DataSetDirs = get_dataset_list

    DataSrcs = { ...
% % % %                  'ba_210802pegni',        '2021.08.02__mPEGslideNonInterfering'; ...
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
% % % %                  'ba_210803iglcnac',       '2021.08.03__HBEslideInterferingGlcNAc'; ...
% % % %                  'ba_210806iglcnac',      '2021.08.06__HBEslideInterferingGlcNAc_trial2'; ...
% % % %                  'ba_210803inana',        '2021.08.03__HBEslideInterferingNaNa'; ...
% % % %                  'ba_210805inana',        '2021.08.05__HBEslideInterferingNaNa_trial2'; ...
% % % %                  'ba_210913inana_3.6E4uM', '2021.09.13__HBEslideInterferingNANA_Trial3'; ...
% % % %                  'ba_210920inana_3.6E2uM', '2021.09.20__HBEslide_InterferingNANA-DF100'; ...
% % % %                  'ba_221026inana_3.6E2uM', '2022.10.26__media-3p8e-4MNANA_HBEplate'; ...
% % % %                  'ba_210915inana_3.6E1uM', '2021.09.15__HBEslide_InterferingNANA-DF1000'; ...
% % % %                  'ba_221026inana_3.6E1uM', '2022.10.26__media-3p8e-5MNANA_HBEplate'; ...      
% % % %                  'ba_280831inana38mMpH7p2', '2022.08.31__pH-6p9_NANA38mM_assortedbeads'; ...
% % % %                  'ba_220922intgalactose', '2022.09.22__media-38mMgalactose_HBEplate'; ...
% % % %                  'ba_210802int25kpH2p5', '2021.08.02__HBEslideInterfering'; ...
% % % %                  'ba_220902int25kpH7',  '2022.09.02__Int25k_pH7p4_assortedbeads'; ...
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
% % % %                  'ba_240125coohni',       '2024.01.25__COOHslide_COOHbeads_noint'; ...
% % % %                  'ba_240126pegni',        '2024.01.26__mPEGslide_mPEGbeads_noint'; ...
% % % %                  'ba_220623ni',           '2022.06.23__HBEbeads_HBEplate_homogeneity_test'; ...
% % % %                  'ba_240129ni',           '2024.01.29__HBEslide_HBEbeads_noint'; ...
% % % %                  'ba_240130ni',           '2024.01.30__HBEslide2_HBEbeads_noint'; ...
                 'ba_230921i5xPBS',       '2023.09.21__HBEslide_PBS5X_stdbeadset'; ... 
                 'ba_230922i5xPBS',       '2023.09.22__HBEslide_PBS5X_stdbeadset'; ... 
                 'ba_230925i5xPBS',       '2023.09.25__HBEslide_PBS5X_stdbeadset_parafilmpoletip'; ... 
                 'ba_240206i5xPBS',       '2024.02.06__HBEslide_PBS5X_stdbeadset'; ...
                 'ba_240207i5xPBS',       '2024.02.07__HBEslide_PBS5X_stdbeadset'; ...
                 'ba_240208i5xPBS',       '2024.02.08__HBEslide_PBS5X_stdbeadset'; ...
                 };

    DataSetDirs(:,1) = DataSrcs(:,2);
end