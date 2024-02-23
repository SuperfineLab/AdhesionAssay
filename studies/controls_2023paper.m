
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

savedatafilesTF = true;

aggregating_variables = {'PlateColumn', 'SubstrateChemistry', 'BeadChemistry', ...
                         'Media', 'pH'};

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
    Broot = load_bigstudy_data(adp, DataSetDirs, aggregating_variables, savedatafilesTF );    
end
B = clean_bigstudy_data(Broot);

%
% % Clean out the PWM and SNA
%
BeadChemsToKeep = {'COOH', 'PEG', 'HBE'};
idxFile = ismember(B.FileTable.BeadChemistry, BeadChemsToKeep);

FiltData.FileTable = B.FileTable(idxFile,:);
FiltData.FileTable.BeadChemistry = removecats(FiltData.FileTable.BeadChemistry);
% FiltData.FileTable.BeadChemistry = reordercats(B.FileTable.BeadChemistry, BeadChemsToKeep);

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
[g, PlateStatsT] = findgroups(B.FileTable(:,['PlateID', aggregating_variables]));
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


DetachVars = {'PlateID', 'PlateColumn', 'BeadChemistry', 'SubstrateChemistry', 'Media', ...
              'pH', 'DetachForce', 'confDetachForce'};

Forces = innerjoin(B.DetachForceTable(:,DetachVars), PlateStatsT, 'Keys', aggregating_variables);


SummaryDataT = innerjoin(Forces, PlateStatsT);
sz = [max(SummaryDataT.VisRow), max(SummaryDataT.VisCol)];
fmat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, abs(SummaryDataT.DetachForce));
% emat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, abs(SummaryDataT.confDetachForce(:,2)));
% wmat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, abs(SummaryDataT.);
figure;
plot_FuncSurface(10.^fmat, pinefresh(50), '50% Pulloff Force [nN]', xstrings, ystrings);
clim([0 100]);

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
AvgPlatesT.NForces = cell2mat(cellfun(@(x)numel(x), AvgPlatesT.Force, 'UniformOutput', false));
AvgPlatesT.MadForce = cell2mat(cellfun(@(x)mad(x(:), 1), AvgPlatesT.Force, 'UniformOutput', false));

q = splitapply(@(x,y)ba_bootstrap(x,y), 10.^(SummaryDataT.DetachForce), ...
                                        [10.^(SummaryDataT.DetachForce) - 10.^(SummaryDataT.confDetachForce(:,1)), ...
                                        10.^(SummaryDataT.confDetachForce(:,2) - 10.^(SummaryDataT.DetachForce))], ...
                                        g3);

q = vertcat(q);
AvgPlatesT.bootMeanForce = q(:,1); 
AvgPlatesT.bootStdError =  q(:,2); 
AvgPlatesT.bootCI        = q(:,3:4); 

caseorder = {...             
             'COOH_NoInt_7', ...
             'PEG_NoInt_7', ...
             'HBE_NoInt_7', ...             
             };

ystrings = caseorder;

tmpT = AvgPlatesT(:,{'SubstrateChemistry','Media', 'pH'});
AvgPlatesT.Cases = categorical(join(string(table2array(tmpT)),'_'));
AvgPlatesT.Cases = reordercats(AvgPlatesT.Cases, caseorder);
AvgPlatesT.VisRow = grp2idx(AvgPlatesT.Cases);
AvgPlatesT.VisCol = grp2idx(AvgPlatesT.BeadChemistry);        

[g3x, g3xT] = findgroups(AvgPlatesT(:,{'BeadChemistry'}));
xstrings = string(table2array(g3xT));

Vr = AvgPlatesT.VisRow;
Vc = AvgPlatesT.VisCol;

sz = [max(Vr), max(Vc)];
pmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.StuckPercent);
nmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.NForces);
gmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.MedianForce);
dmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.MadForce);
mmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.MeanForce);
smat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.StdForce);
zmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.StdErrForce);
bmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.bootMeanForce);
bsmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.bootStdError);
blclmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.bootCI(:,1));
buclmat = OrganizeSurfaceData(sz, Vr, Vc, AvgPlatesT.bootCI(:,2));

figure; 
barwitherr(bsmat, bmat);
ax = gca;
ax.XTickLabel = ystrings;
ax.TickLabelInterpreter = 'none';
legend('PEG', 'WGA', 'HBE');
xlabel('');
ylabel('Force [nN]');
title('bootstrap mean force : stderr');
pretty_plot;

% Plotting the data for the averaged plates.
plot_FuncSurface(pmat, seabreeze(10), 'Percent Stuck Beads', xstrings, ystrings);
plot_FuncSurface(bmat, pinefresh(25), 'Bootstrap Mean Pulloff Force, main mode [nN]', xstrings, ystrings);
% plot_StuckBoxes(AvgPlatesT.FileTable, "HBE", [-5 105]);
% plot_ForceBoxes(AvgPlatesT, "PEG", [0 100]);
% plot_ForceBoxes(AvgPlatesT, "HBE", [0 100]);


% % 
%  Anova code
% %
% BigT = innerjoin(B.FileTable, B.ForceTable);
% hbeT = BigT( BigT.SubstrateChemistry == 'HBE', :);
% hbeT = hbeT( hbeT.Media == "IntNANA" | hbeT.Media == "NoInt", :);
% if iscategorical(hbeT.MediumNANAConc)
%     nanatmp = arrayfun(@str2num,string(hbeT.MediumNANAConc));
% else
%     nanatmp = gnanaT.MediumNANAConc;
% end
% hbeT.MediaAll = join([string(hbeT.Media), string(num2str(nanatmp, '%.0e'))]);
% [ag, agT] = findgroups(hbeT(:,{'BeadChemistry', 'MediaAll'}));
% foo = anova1(hbeT.Force, ag);
% an = anovan(hbeT.Force, {hbeT.BeadChemistry, hbeT.MediaAll}, 'model', 2, 'varnames', {'Bead Chemistry', 'Medium'});

% % 
%   Functions: Data Wrangling
% %



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


% function plot_StuckBoxes(BigFileT, BeadChemistry, yLim )
%     T = BigFileT( BigFileT.Media == "IntNANA" | BigFileT.Media == "NoInt", :);
%     T = T( T.SubstrateChemistry == "HBE" & T.BeadChemistry == string(BeadChemistry), :);
%     T = T(:, {'PlateID', 'BeadChemistry', 'SubstrateChemistry', 'Media', 'MediumNANAConc', 'StuckFactor'});  
%     T = movevars(T, 'PlateID', 'Before', 'BeadChemistry');
% 
%     [gnana, gnanaT] = findgroups(T(:,{'BeadChemistry', 'SubstrateChemistry', 'MediumNANAConc'}));
%     
%     for k = 1:max(gnana)
%         boxCell{k,1} = T( gnana == k, 'StuckFactor' ); 
%     end
%     
%     boxMatrix = NaN(max(cellfun(@numel, boxCell)), length(boxCell));
%     for k = 1:length(boxCell)
%         boxMatrix(1:height(boxCell{k}),k) = table2array(boxCell{k});
%     end
% 
%     xticklbls = num2str(gnanaT.MediumNANAConc*1e3, '%2.2g');
%     
%     h = figure; 
%     boxplot(boxMatrix*100, 'Notch', 'on', 'Labels', xticklbls);
%     title([char(BeadChemistry) ' coated-bead']);
%     xlabel('Interfering Sialic Acid [mM]');
%     ylabel('% attached at max force');
%     if nargin >= 3 && ~isempty(yLim)
%         ylim(yLim);
%     end
%     set(findobj(gca,'type','line'),'linew',2)
%     pretty_plot;
%     h.Position(3:4) = h.Position(3:4) * 0.85;    
%     drawnow;
%     
% end
% 
% function plot_ForceBoxes(ForceDists, BeadChemistry, yLim )
% 
%     
%     col=@(x)reshape(x,numel(x),1);
% 
%     boxplot2=@(C,varargin)boxplot(cell2mat(cellfun(col,col(C),'uni',0)),cell2mat(arrayfun(@(I)I*ones(numel(C{I}),1),col(1:numel(C)),'uni',0)),varargin{:});
% 
%     T = ForceDists( ForceDists.Media == "IntNANA" | ForceDists.Media == "NoInt", :);
%     T = T( T.SubstrateChemistry == "HBE" & T.BeadChemistry == string(BeadChemistry), :);
%     try
%         T = T(:, {'PlateID', 'BeadChemistry', 'SubstrateChemistry', 'Media', 'MediumNANAConc', 'Force'});  
%         T = movevars(T, 'PlateID', 'Before', 'BeadChemistry');
%     catch 
%         T = T(:, {'BeadChemistry', 'SubstrateChemistry', 'Media', 'MediumNANAConc', 'Force'});  
%     end
%     
% 
%     [gnana, gnanaT] = findgroups(T(:,{'BeadChemistry', 'SubstrateChemistry', 'MediumNANAConc'}));
%     
%     gnanaT.Force = splitapply(@(x){catcells(x)}, T.Force, gnana);
%     
%     force_nN = cellfun(@(x)x.*1e9, gnanaT.Force, 'UniformOutput', false);
% 
% %     [p(k), h(k)] = ranksum(compare_msd, this_msd);
%     
% %     % if there's significance, put the stars on the plot
% %     if p(k)<0.05
% %         sigstar([k,COMPARE_COLUMN],p(k)); 
% %     end
%     
%     if iscategorical(gnanaT.MediumNANAConc)
%         nanatmp = arrayfun(@str2num,string(gnanaT.MediumNANAConc));
%     else
%         nanatmp = gnanaT.MediumNANAConc;
%     end
%     xticklbls = num2str(nanatmp*1e3, '%2.2g');
%     
%     h = figure; 
%     boxplot2(force_nN, 'Notch', 'on', 'Labels', string(xticklbls));
%     title([char(BeadChemistry), ' coated-bead']);
%     xlabel('Interfering Sialic Acid [mM]');
%     ylabel('Detachment Force [nN]');
%     if nargin >= 3 && ~isempty(yLim)
%         ylim(yLim);
%     end
% %     set(findobj(gca,'type','line'),'linew',2)
%     pretty_plot;
%     h.Position(3:4) = h.Position(3:4) * 0.85;
%     ax = gca;
%     ax.YScale = "log";
%     ax.YLim = [0.1 125];
%     drawnow;
%     
% end

% function boxplot2(C, varargin)
%     fun = @(I)I*ones(numel(C{I}),1);
%     A = cell2mat(cellfun(col,col(C),'uni',0));
%     B = arrayfun(fun,col(1:numel(C)),'uni',0);
%     C = cell2mat(B);
%     boxplot(A,C,varargin{:})
% end
