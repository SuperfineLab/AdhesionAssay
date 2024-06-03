addpath(genpath('D:\jcribb\src\3dfmAnalysis'));
addpath(genpath('D:\jcribb\src\AdhesionAssay'));

% close all

groupvars = {'PlateID', 'SubstrateChemistry', 'BeadChemistry', 'Media', 'pH'};

rootdir = pwd;

% Load the data sources (one source per plate), attach the PlateID, and then 
% concatenate into one big table.
%
% ** The load_bigstudy_data function is at the very bottom of this file. **
if ~exist('B', 'var')
    B = load_bigstudy_data(groupvars);
    B = clean_bigstudy_data(B);
end
    
plateNames(:,1) = unique(B.FileTable.PlateID);

% I first want to calculate some basic statistics on the repeat
% measurements within a plate. The protocol right now is to run each
% condition in triplicate. This aggregates each set of replicates into a
% single dataset/sample in each plate for each test condition.
[g, PlateStatsT] = findgroups(B.FileTable(:,groupvars));
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


DetachVars = {'PlateID', 'BeadChemistry', 'SubstrateChemistry', 'Media', ...
              'pH', 'DetachForce'};

Forces = innerjoin(B.DetachForceTable(:,DetachVars), PlateStatsT, 'Keys', groupvars);


SummaryDataT = innerjoin(Forces, PlateStatsT);
sz = [max(SummaryDataT.VisRow), max(SummaryDataT.VisCol)];
fmat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, abs(SummaryDataT.DetachForce));
% emat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, abs(SummaryDataT.confDetachForce(:,2)));
% wmat = OrganizeSurfaceData(sz, SummaryDataT.VisRow, SummaryDataT.VisCol, abs(SummaryDataT.);

plot_FuncSurface(10.^fmat, pinefresh(25), '50% Pulloff Force [nN]', xstrings, ystrings);


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
pmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.StuckPercent);
nmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.NForces);
gmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.MedianForce);
dmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.MadForce);
mmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.MeanForce);
smat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.StdForce);
zmat = OrganizeSurfaceData(sz, AvgPlatesT.VisRow, AvgPlatesT.VisCol, AvgPlatesT.StdErrForce);

% figure;
% % bar(mmat([2 5 6 7],:));
% % bar(mmat);
% barwitherr(mmat, zmat);
% ax = gca;
% % ax.XTickLabel = ystrings([2 5 6 7]);
% % ax.XTickLabel = {'0 µM', '36 µM', '360 µM', '36,000 µM'};
% ax.TickLabelInterpreter = 'none';
% legend('PEG', 'PWM', 'WGA', 'SNA', 'HBE');
% xlabel('Sialic Acid conc.');
% ylabel('Force [nN]');
% pretty_plot;

% Plotting the data for the averaged plates.
% plot_FuncSurface(pmat, seabreeze(10), 'Percent Stuck Beads', xstrings, ystrings);
% plot_FuncSurface(gmat, seabreeze(10), 'Median Pulloff Force [nN]', xstrings, ystrings);
% plot_FuncSurface(mmat, pinefresh(15), 'Mean Pulloff Force [nN]', xstrings, ystrings);
% plot_StuckBoxes(AvgPlatesT.FileTable, "SNA", [-5 105]);
% plot_StuckBoxes(AvgPlatesT.FileTable, "HBE", [-5 105]);
% plot_ForceBoxes(AvgPlatesT, "mPEG", [0 100]);
% plot_ForceBoxes(AvgPlatesT, "PWM", [0 100]);
% plot_ForceBoxes(AvgPlatesT, "WGA", [0 100]);
% plot_ForceBoxes(AvgPlatesT, "SNA", [0 100]);
% plot_ForceBoxes(AvgPlatesT, "HBE", [0 100]);


% % 
%  Anova code
% %
BigT = innerjoin(B.FileTable, B.ForceTable);
hbeT = BigT( BigT.SubstrateChemistry == 'HBE', :);
hbeT = hbeT( hbeT.Media == "IntNANA" | hbeT.Media == "NoInt", :);
if iscategorical(hbeT.MediumNANAConc)
    nanatmp = arrayfun(@str2num,string(hbeT.MediumNANAConc));
else
    nanatmp = gnanaT.MediumNANAConc;
end
hbeT.MediaAll = join([string(hbeT.Media), string(num2str(nanatmp, '%.0e'))]);
[ag, agT] = findgroups(hbeT(:,{'BeadChemistry', 'MediaAll'}));
% foo = anova1(hbeT.Force, ag);
% an = anovan(hbeT.Force, {hbeT.BeadChemistry, hbeT.MediaAll}, 'model', 2, 'varnames', {'Bead Chemistry', 'Medium'});


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


function plot_StuckBoxes(BigFileT, BeadChemistry, yLim )
    T = BigFileT( BigFileT.Media == "IntNANA" | BigFileT.Media == "NoInt", :);
    T = T( T.SubstrateChemistry == "HBE" & T.BeadChemistry == string(BeadChemistry), :);
    T = T(:, {'PlateID', 'BeadChemistry', 'SubstrateChemistry', 'Media', 'MediumNANAConc', 'StuckFactor'});  
    T = movevars(T, 'PlateID', 'Before', 'BeadChemistry');

    [gnana, gnanaT] = findgroups(T(:,{'BeadChemistry', 'SubstrateChemistry', 'MediumNANAConc'}));
    
    for k = 1:max(gnana)
        boxCell{k,1} = T( gnana == k, 'StuckFactor' ); 
    end
    
    boxMatrix = NaN(max(cellfun(@numel, boxCell)), length(boxCell));
    for k = 1:length(boxCell)
        boxMatrix(1:height(boxCell{k}),k) = table2array(boxCell{k});
    end

    xticklbls = num2str(gnanaT.MediumNANAConc*1e3, '%2.2g');
    
    h = figure; 
    boxplot(boxMatrix*100, 'Notch', 'on', 'Labels', xticklbls);
    title([char(BeadChemistry) ' coated-bead']);
    xlabel('Interfering Sialic Acid [mM]');
    ylabel('% attached at max force');
    if nargin >= 3 && ~isempty(yLim)
        ylim(yLim);
    end
    set(findobj(gca,'type','line'),'linew',2)
    pretty_plot;
    h.Position(3:4) = h.Position(3:4) * 0.85;    
    drawnow;
    
end

function plot_ForceBoxes(ForceDists, BeadChemistry, yLim )

    
    col=@(x)reshape(x,numel(x),1);

    boxplot2=@(C,varargin)boxplot(cell2mat(cellfun(col,col(C),'uni',0)),cell2mat(arrayfun(@(I)I*ones(numel(C{I}),1),col(1:numel(C)),'uni',0)),varargin{:});

    T = ForceDists( ForceDists.Media == "IntNANA" | ForceDists.Media == "NoInt", :);
    T = T( T.SubstrateChemistry == "HBE" & T.BeadChemistry == string(BeadChemistry), :);
    try
        T = T(:, {'PlateID', 'BeadChemistry', 'SubstrateChemistry', 'Media', 'MediumNANAConc', 'Force'});  
        T = movevars(T, 'PlateID', 'Before', 'BeadChemistry');
    catch 
        T = T(:, {'BeadChemistry', 'SubstrateChemistry', 'Media', 'MediumNANAConc', 'Force'});  
    end
    

    [gnana, gnanaT] = findgroups(T(:,{'BeadChemistry', 'SubstrateChemistry', 'MediumNANAConc'}));
    
    gnanaT.Force = splitapply(@(x){catcells(x)}, T.Force, gnana);
    
    force_nN = cellfun(@(x)x.*1e9, gnanaT.Force, 'UniformOutput', false);

%     [p(k), h(k)] = ranksum(compare_msd, this_msd);
    
%     % if there's significance, put the stars on the plot
%     if p(k)<0.05
%         sigstar([k,COMPARE_COLUMN],p(k)); 
%     end
    
    if iscategorical(gnanaT.MediumNANAConc)
        nanatmp = arrayfun(@str2num,string(gnanaT.MediumNANAConc));
    else
        nanatmp = gnanaT.MediumNANAConc;
    end
    xticklbls = num2str(nanatmp*1e3, '%2.2g');
    
    h = figure; 
    boxplot2(force_nN, 'Notch', 'on', 'Labels', string(xticklbls));
    title([char(BeadChemistry), ' coated-bead']);
    xlabel('Interfering Sialic Acid [mM]');
    ylabel('Detachment Force [nN]');
    if nargin >= 3 && ~isempty(yLim)
        ylim(yLim);
    end
%     set(findobj(gca,'type','line'),'linew',2)
    pretty_plot;
    h.Position(3:4) = h.Position(3:4) * 0.85;
    ax = gca;
    ax.YScale = "log";
    ax.YLim = [0.1 125];
    drawnow;
    
end


% %
%   Functions: Custom Colormaps (schema came from colorbrewer)
% %
function outs = pinefresh(cnum)
    cbmap = ... [255,255,255;
             [255,255,204; 
             194,230,153;
             120,198,121;
             49,163,84;
             0,104,55];
    outs = interpcmap(cbmap, cnum);
end


function outs = seabreeze(cnum)
    cbmap = ... [255,255,255;
             [240,249,232; 
             186,228,188; 
             123,204,196; 
             67,162,202; 
             8,104,172];
    outs = interpcmap(cbmap, cnum);
end


function outs = candycane(cnum)
    cbmap = ... [255,255,255;
             [241,238,246;
             215,181,216;
             223,101,176;
             221,28,119;
             152,0,67];
%     cbmap = [255,255,255;
%              255,0,0];
     outs = interpcmap(cbmap, cnum);     
end


function outs = doldrums(cnum)
    outs = gray(cnum);
    outs(:,2) = 0;
    outs(:,3) = flipud(outs(:,1));
    outs(1,:) = 1;
end


function outs = interpcmap(map, cnum)
    map = map ./ 255;
    sampleN = size(map,1);
    xnew = linspace(1,sampleN,cnum);

    outs = interp1(map, xnew);
    outs(1,:) = [1,1,1];
end


% % 
%   Functions: Data Wrangling
% %
function outs = catcells(x)
    if iscell(x)
        outs = cat(1,x{:});
    elseif isnumeric(x)
        outs = x;
    end
end
    
% function myforce = sa_attach_stuck_beads(force, beadcount, maxforce)
%     padforce = beadcount(1) - length(force);
%     myforce = [force(:) ; repmat(maxforce,padforce,1)];
% end

function outs = OrganizeSurfaceData(sz, VisRow, VisCol, data)
%     myidx = sub2ind(sz, VisRow, VisCol);
% 
%     outs = NaN(sz);
%     outs(myidx) = data(myidx);
    R = max(VisRow);
    C = max(VisCol);
    cmat = zeros(R, C);
    
    for k = 1:R
        for m = 1:C
            try
                cmat(k,m) = data(VisRow == k & VisCol == m);
            catch
                cmat(k,m) = NaN;
            end
        end
    end
    
    outs = cmat;
end

    
% function boxplot2(C, varargin)
%     fun = @(I)I*ones(numel(C{I}),1);
%     A = cell2mat(cellfun(col,col(C),'uni',0));
%     B = arrayfun(fun,col(1:numel(C)),'uni',0);
%     C = cell2mat(B);
%     boxplot(A,C,varargin{:})
% end


function B = clean_bigstudy_data(B)
    
    goodOrder = {'PEG', 'PWM', 'WGA', 'SNA', 'HBE'};
    
    B.FileTable.BeadChemistry( B.FileTable.BeadChemistry == "mPEG" ) = "PEG";
    B.FileTable.BeadChemistry( B.FileTable.BeadChemistry == "RhoPEG" ) = "PEG";
    B.FileTable.BeadChemistry = removecats(B.FileTable.BeadChemistry);
    B.FileTable.BeadChemistry = reordercats(B.FileTable.BeadChemistry, goodOrder);
    
    B.FileTable.SubstrateChemistry( B.FileTable.SubstrateChemistry == "mPEG" ) = "PEG";
    B.FileTable.SubstrateChemistry( B.FileTable.SubstrateChemistry == "RhoPEG" ) = "PEG";

    B.DetachForceTable.BeadChemistry( B.DetachForceTable.BeadChemistry == "mPEG" ) = "PEG";
    B.DetachForceTable.BeadChemistry( B.DetachForceTable.BeadChemistry == "RhoPEG" ) = "PEG";

    B.DetachForceTable.BeadChemistry = removecats(B.DetachForceTable.BeadChemistry);
    B.DetachForceTable.BeadChemistry = reordercats(B.DetachForceTable.BeadChemistry, goodOrder);
    
    
    B.DetachForceTable.SubstrateChemistry( B.DetachForceTable.SubstrateChemistry == "RhoPEG" ) = "PEG";
    B.DetachForceTable.SubstrateChemistry( B.DetachForceTable.SubstrateChemistry == "RhoPEG" ) = "PEG";

%     B.DetachForceTable.DetachForce(abs(imag(B.DetachForceTable.DetachForce)) > ...
%                                    0.1*abs(real(B.DetachForceTable.DetachForce))) = complex(NaN);
%     B.DetachForceTable.DetachForce =  abs(B.DetachForceTable.DetachForce);
%     B.DetachForceTable.DetachForce( isnan(B.DetachForceTable.DetachForce) ) = 111;
end

    
function BigStudy = load_bigstudy_data(aggvar)

    % all-data-path
    adp = 'K:\expts\AdhesionAssay\datasets_NOTvideo\';
    DataSrcs = { ...
                 'ba_210802pegni',        [adp, '2021.08.02__mPEGslideNonInterfering\']; ...
                 'ba_230724pegni',        [adp, '2023.07.24__Rho-PEGslide_HBE+lectins']; ... 
                 'ba_230915pegni',        [adp, '2023.09.15__PEGslide_NoInt-stdbeadset\']; ... 
                 'ba_231024pegni',        [adp, '2023.10.24__PEGslide_noint_stdbeadset\']; ...
                 'ba_231025pegni',        [adp, '2023.10.25__PEGslide_noint_stdbeadset\']; ...
                 'ba_210802ni',           [adp, '2021.08.02__HBEslideNonInterfering\']; ...
                 'ba_210805ni',           [adp, '2021.08.05__HBEslideNonInterfering_Trial2\']; ...
                 'ba_210910ni',           [adp, '2021.09.10__HBEslideNonInterfering_Trial3\']; ...
                 'ba_230721ni',           [adp, '2023.07.21__HBEslide_HBE+lectins\']; ...      
%                  'ba_210803iglcnac',      [adp, '2021.08.03__HBEslideInterferingGlcNAc\']; ...
%                  'ba_210806iglcnac',      [adp, '2021.08.06__HBEslideInterferingGlcNAc_trial2\']; ...
%                  'ba_210803inana',        [adp, '2021.08.03__HBEslideInterferingNaNa\']; ...
%                  'ba_210805inana',        [adp, '2021.08.05__HBEslideInterferingNaNa_trial2\']; ...
%                  'ba_210913inana_3.6E4uM',[adp, '2021.09.13__HBEslideInterferingNANA_Trial3\']; ...
%                  'ba_210920inana_3.6E2uM',[adp, '2021.09.20__HBEslide_InterferingNANA-DF100\']; ...
%                  'ba_221026inana_3.6E2uM',[adp, '2022.10.26__media-3p8e-4MNANA_HBEplate\']; ...
%                  'ba_210915inana_3.6E1uM',[adp, '2021.09.15__HBEslide_InterferingNANA-DF1000\']; ...
%                  'ba_221026inana_3.6E1uM',[adp, '2022.10.26__media-3p8e-5MNANA_HBEplate\']; ...      
%                  'ba_220831inana_neutpH', [adp, '2022.08.31__pH-6p9_NANA38mM_assortedbeads']; ...
%                  'ba_220922intgalactose', [adp, '2022.09.22__media-38mMgalactose_HBEplate\']; ...
%                  'ba_210802int25kpH2p5',  [adp, '2021.08.02__HBEslideInterfering\']; ...
%                  'ba_220902int25kpH7',    [adp, '2022.09.02__Int25k_pH7p4_assortedbeads']; ...
                 'ba_220901ilowph',       [adp, '2022.09.01__pH2p6_NoInt_assortedbeads']; ...
                 'ba_230801ilowph',       [adp, '2023.08.01__HBEslide_NoIntpH2p5-stdbeadset\']; ...      
                 'ba_230804ilowph',       [adp, '2023.08.04__HBEslide_NoIntpH2p5-stdbeads\']; ...                       
                 'ba_220922inp40',        [adp, '2022.09.22__media-0p1pctNP40_HBEplate\']; ...      
                 'ba_230801inp40',        [adp, '2023.08.01__HBEslide_0p1pctNP40-stdbeadset\']; ...                       
                 'ba_230804inp40',        [adp, '2023.08.04__HBEslide_IntNP40-stdbeadset\']; ...                       
                 'ba_230907inp40',        [adp, '2023.09.07__HBEslide_0p1pctNP40\']; ... 
                 'ba_230914inp40',        [adp, '2023.09.14__HBEslide_IntNP40-stdbeadset\']; ...                  
                 'ba_230921i5xPBS',       [adp, '2023.09.21__HBEslide_PBS5X_stdbeadset\']; ... 
                 'ba_230922i5xPBS',       [adp, '2023.09.22__HBEslide_PBS5X_stdbeadset\']; ... 
                 'ba_230925i5xPBS',       [adp, '2023.09.25__HBEslide_PBS5X_stdbeadset_parafilmpoletip\']; ... 
                 };

%     plateNames = DataSrcs(:,1);
    platepaths = DataSrcs(:,2);
    
    model = 'erf';
    for k = 1:length(DataSrcs)
        q = ba_process_expt(platepaths{k}, model, aggvar);        
        BigFileT{k,1} = q.FileTable;
        BigTimeHeightVidStatsT{k,1} = q.TimeHeightVidStatsTable;
        BigTrackingT{k,1} = q.TrackingTable;
        BigBeadInfoT{k,1} = q.BeadInfoTable;
        BigForceT{k,1} = q.ForceTable;
        BigForceFitT{k,1} = q.DetachForceTable;
    end

    BigStudy.FileTable = vertcat(BigFileT{:});
    BigStudy.TimeHeightVidStatsTable = vertcat(BigTimeHeightVidStatsT{:});
    BigStudy.BeadInfoTable = vertcat(BigBeadInfoT{:});
    BigStudy.TrackingTable = vertcat(BigTrackingT{:});
    BigStudy.ForceTable = vertcat(BigForceT{:});
    BigStudy.DetachForceTable = vertcat(BigForceFitT{:});
    
end

