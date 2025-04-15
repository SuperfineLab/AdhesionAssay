%% Data cleaning (yes, there's more. There's always more.)
mylinecolor = lines(7);

% AttachedThreshold = mean([-1.16 -0.2496]); 
AttachedThreshold = -0.65;  % between two COOH ModeForces

groupvars = {'SubstrateChemistry', 'BeadChemistry', 'PlateColumn', 'Media', 'pH'};
detachgroupvars = [groupvars, 'AttachedTF'];

% Remove full-plate-curve control slides (if they exist in starting table)
control_slide_PlateIDlist = {'ba_240125coohni', 'ba_240126pegni', 'ba_240129ni', 'ba_240130ni'};
myForceFitTable = ForceFitTable;
controlplate = logical(sum(myForceFitTable.PlateID == control_slide_PlateIDlist,2));
myForceFitTable(controlplate,:) = [];

% Add control slides partitioned by PlateColumn
ColumnControlData = load('K:\expts\AdhesionAssay\AdhesionAssay_2024ControlStudy\2024.08.26_cerium_Broot_CONTROLstudy_COLUMNwise_sampling_manually-adjusted-mode-count.UIedited.mat');
myForceFitTable = vertcat(myForceFitTable, ColumnControlData.ForceFitTable);
clear ColumnControlData

% Restructure such that pH is included as Media category rather than as a different axis
myForceFitTable.Media(myForceFitTable.Media == "NoInt" & ...
                      myForceFitTable.pH == "2.5") = "IntLowpH";


% segment data based on attachment "threshold"
DetachForceTable = ba_decouple_modes(myForceFitTable, groupvars);
DetachForceTable.AttachedTF = (DetachForceTable.ModeForce > AttachedThreshold);

% % Filter out datapoints where the ModeScale is less than a threshold value.
% % Here, that is set to 25%. If 25% or less of the beads belong to a mode,
% % then filter out that mode
% ScaleThreshold = 0.25;
% LowScaleTF = (DetachForceTable.ModeScale <= ScaleThreshold);
% DetachForceTable(LowScaleTF,:) = [];

% Insist the ordinal order of the categorical variables (of interest)
DetachForceTable.BeadChemistry = categorical(DetachForceTable.BeadChemistry, ["COOH", "PEG", "WGA", "HBE"], 'Ordinal', true);
DetachForceTable.SubstrateChemistry = categorical(DetachForceTable.SubstrateChemistry, ["COOH", "PEG", "HBE"], 'Ordinal', true);
DetachForceTable.Media = categorical(DetachForceTable.Media, ["NoInt", "IntLowpH", "IntNP40", "Int5xPBS"], 'Ordinal', true);

%% Plot Force vs Scale for fits matching (BeadChemistry, SubstrateChemistry, Media)
% plot_ForceVsScale(DetachForceTable, "PEG", "PEG", "NoInt", false);
% plot_ForceVsScale(DetachForceTable, "COOH", "COOH", "NoInt", false);
% plot_ForceVsScale(DetachForceTable, "WGA", "HBE", "NoInt", false);


%% check for outliers
FiltDetachTable = filterForces(DetachForceTable, "COOH", "COOH", "NoInt");
outliertest = isoutlier(FiltDetachTable.ModeForce,'quartiles');


% % %% Looking at COOH:COOH interaction across different plates/columns
% % subgroup = (DetachForceTable.BeadChemistry == "COOH" & ...
% %             DetachForceTable.SubstrateChemistry == "COOH");
% % subgrouping_vars = ["PlateID", "PlateColumn", "AttachedTF"];
% % run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'Exploring the COOH:COOH interaction');


% % %% Looking at PEG:PEG interaction across different plates/columns
% % subgroup = (DetachForceTable.BeadChemistry == "PEG" & ...
% %             DetachForceTable.SubstrateChemistry == "PEG");
% % subgrouping_vars = ["PlateID", "PlateColumn"];
% % run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'Exploring the COOH:COOH interaction');


% % %% Looking at HBE:HBE interaction across different plates
% % subgroup = (DetachForceTable.BeadChemistry == "HBE" & ...
% %             DetachForceTable.SubstrateChemistry == "HBE");
% % % subgrouping_vars = ["PlateID", "PlateColumn"];
% % subgrouping_vars = ["Media"];
% % run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'Exploring the HBE:HBE interaction');
% % 


% Bead:Substrate/ni cross-checks, HBE:PEG/ni, PEG:HBE/ni. 

% %% Looking at HBE:HBE interaction across different plates
% subgroup = (DetachForceTable.BeadChemistry == "HBE" & ...
%             DetachForceTable.SubstrateChemistry == "HBE");
% subgrouping_vars = ["PlateID", "PlateColumn"];
% run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'Exploring the HBE:HBE interaction');


%% Looking at PEG:HBE interaction in differing media conditions
subgroup = (DetachForceTable.BeadChemistry == "PEG" & ...
            DetachForceTable.SubstrateChemistry == "HBE");
subgrouping_vars = ["Media"];
[f,ax,m,factorNames] = run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'Exploring the PEG:HBE interaction');

f.Position(3:4) = [155*2 210];
ax.XTickLabel = {"Ctrl", "LowpH", "NP40", "5xPBS"};
ax.Position([2,4]) = [0.20,0.75];
ax.XLim = [0.5 4.5];

%% Looking at WGA:HBE interaction in differing media conditions
subgroup = (DetachForceTable.BeadChemistry == "WGA" & ...
            DetachForceTable.SubstrateChemistry == "HBE");
subgrouping_vars = ["Media"];
[f,ax,m,factorNames] = run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'Exploring the WGA:HBE interaction');

f.Position(3:4) = [155*2 210];
ax.XTickLabel = {"Ctrl", "LowpH", "NP40", "5xPBS"};
ax.Position([2,4]) = [0.20,0.75];
ax.XLim = [0.5 4.5];

%% Looking at HBE:HBE interaction in differing media conditions
subgroup = (DetachForceTable.BeadChemistry == "HBE" & ...
            DetachForceTable.SubstrateChemistry == "HBE");
subgrouping_vars = ["Media"];
[f,ax,m,factorNames] = run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'Exploring the HBE:HBE interaction');

f.Position(3:4) = [155*2 210];
ax.XTickLabel = {"Ctrl", "LowpH", "NP40", "5xPBS"};
ax.Position([2,4]) = [0.20,0.75];
ax.XLim = [0.5 4.5];

%% Looking at non-interfering medium for PEG slides
subgroup = (DetachForceTable.Media == "NoInt" & ...
            DetachForceTable.SubstrateChemistry == "PEG");
subgrouping_vars = ["BeadChemistry"];
[f, ax, m] = run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'media: non-interfering, PEG slide');
fixBoxPlot_xticks(ax, {"PEG","WGA","HBE"},{"PEG","PEG","PEG"});
f.Position(3:4) = [155*3/2 210];
ax.Position([2,4]) = [0.20,0.75];

%% Looking at non-interfering medium for HBE slides
subgroup = (DetachForceTable.Media == "NoInt" & ...
            DetachForceTable.SubstrateChemistry == "HBE");
subgrouping_vars = ["BeadChemistry"];
[f, ax, m] = run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'media: non-interfering, HBE slide');
fixBoxPlot_xticks(ax, {"PEG","WGA","HBE"},{"HBE","HBE","HBE"});
f.Position(3:4) = [155*3/2 210];


%% Looking at non-interfering medium for PEG and HBE beads on PEG and HBE slides
subgroup = (DetachForceTable.Media == "NoInt" & ...
            (DetachForceTable.BeadChemistry == "PEG" | ...
             DetachForceTable.BeadChemistry == "HBE") & ...
            (DetachForceTable.SubstrateChemistry == "PEG" | ...
             DetachForceTable.SubstrateChemistry == "HBE") );
subgrouping_vars = ["BeadChemistry", "SubstrateChemistry"];
[f, ax, m] = run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'media: non-interfering');
fixBoxPlot_xticks(ax, {"PEG","PEG","HBE","HBE"},{"PEG","HBE","PEG","HBE"});
f.Position(3:4) = [155*2 210];
ax.Position([2,4]) = [0.20,0.75];

% Looking at non-interfering medium for WGA beads on PEG and HBE slides. Use PEG:PEG as a comparison
logentry('Looking at non-interfering medium for WGA beads on PEG and HBE slides.'); 
subgroupPEG = (DetachForceTable.Media == "NoInt" & ...
               (DetachForceTable.BeadChemistry == "PEG" & ...
                DetachForceTable.SubstrateChemistry == "PEG") );

subgroupWGA = (DetachForceTable.Media == "NoInt" & ...
            (DetachForceTable.BeadChemistry == "WGA") & ...
            (DetachForceTable.SubstrateChemistry == "PEG" | ...
             DetachForceTable.SubstrateChemistry == "HBE") );

% combine the PEG and WGA subgroups
subgroup = subgroupPEG | subgroupWGA;
clear subgroupPEG subgroupWGA

subgrouping_vars = ["BeadChemistry", "SubstrateChemistry"];
[f,ax,m] = run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'media: non-interfering');
fixBoxPlot_xticks(ax, {"PEG","WGA","WGA"},{"PEG","PEG","HBE"});
f.Position(3:4) = [155 210];
ax.Position([2,4]) = [0.20,0.75];


%% Looking at non-interfering medium for PEG, WGA, and HBE beads on PEG and HBE slides
subgroup = (DetachForceTable.Media == "NoInt" & ...
            (DetachForceTable.BeadChemistry == "PEG" | ...
             DetachForceTable.BeadChemistry == "WGA" | ...
             DetachForceTable.BeadChemistry == "HBE" ) & ...
            (DetachForceTable.SubstrateChemistry == "PEG" | ...
             DetachForceTable.SubstrateChemistry == "HBE") );
subgrouping_vars = ["SubstrateChemistry","BeadChemistry"];
[f, ax, m] = run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'media: non-interfering');
fixBoxPlot_xticks(ax, {"PEG","WGA","HBE","PEG","WGA","HBE"},{"PEG","PEG","PEG","HBE","HBE","HBE"});
f.Position(3:4) = [155*3 210];

%% Looking at surfactant
subgroup = (DetachForceTable.Media == "IntNP40");
subgrouping_vars = ["BeadChemistry","SubstrateChemistry"];
run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'media: NP40 surfactant');


%% Looking at low pH
subgroup = (DetachForceTable.Media == "IntLowpH");
subgrouping_vars = ["BeadChemistry","SubstrateChemistry"];
run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'media: low pH');

%% Looking at 5xPBS (high salt)
subgroup = (DetachForceTable.Media == "Int5xPBS");
subgrouping_vars = ["BeadChemistry","SubstrateChemistry"];
run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'media: Int5xPBS');


%% looking at everything that's attached
subgroup = (DetachForceTable.AttachedTF);
subgrouping_vars = ["SubstrateChemistry", "BeadChemistry", "Media"];
run_comparison(DetachForceTable(subgroup,:), subgrouping_vars, 'everything');


%% 

% subfunctions
function [f,ax,m,factorNames] = run_comparison(subDetachForceTable, subgrouping_vars, titlestring)
    
    ascendme = repmat("ascend", 1, numel(subgrouping_vars));
    subDetachForceTable = sortrows(subDetachForceTable, subgrouping_vars, ascendme);
    
    [subg, subgT] = findgroups(subDetachForceTable(:,subgrouping_vars));
    factorNames = mkfactorNames(subgT);
    
    logentry(['Testing, ', titlestring]);
    % Bartlett test for equal variances. If sample-data fails this (p<0.05),
    % then the standard anova1 (manova?) does not work. 
    bartTest = vartestn(subDetachForceTable.ModeForce, factorNames(subg),"Display","off");
    logentry(['Bartlett p-value is ' num2str(bartTest)]);
    if bartTest > 0.05
        logentry('Equal variances test has passed. Standard ANOVA applies.');
        % % Multi-variate anova (manova)
        maov = manova(factorNames(subg), subDetachForceTable.ModeForce);
        m = multcompare(maov, 'CriticalValueType', 'bonferroni');
        disp(m)
        % an = anova1(subDetachForceTable.ModeForce, factorNames(subg));
    else
        % Move on to Kruskel-Wallis test
        logentry('Variances between groups are statistically different. Will use Kruskal-Wallis.');
        [kw.p, kw.tbl, kw.stats] = kruskalwallis(subDetachForceTable.ModeForce, factorNames(subg),"off");        
        figure;
        [m.c, m.m, m.h, m.gnames] = multcompare(kw.stats);
        set(gca, 'TickLabelInterpreter', 'none');        
        title(titlestring);
    end
    
    fprintf('\n\n');

    

    mylinecolor = lines(7);
    % XJitterWidth = 0.9 * min(diff(unique(x)));

    f = figure;
    hold on
    b = boxchart(subg, subDetachForceTable.ModeForce, ...
                 'Notch','off', 'BoxFaceColor', mylinecolor(1,:));
    b.JitterOutliers = "off";
    b.MarkerStyle = 'x'; % outlier markers
    b.MarkerColor = 'r'; 
    b.MarkerSize = 3;
    b.WhiskerLineColor = mylinecolor(1,:);

    good = cell2mat(vertcat(splitapply(@(x){~isoutlier(x, 'quartiles')}, subDetachForceTable.ModeForce, subg)));

    s = swarmchart(subg(good), subDetachForceTable.ModeForce(good), ...
        'Marker', 'o', 'SizeData', 4, ...
        'MarkerFaceColor', [0 0.4470 0.7410], ...
        'MarkerFaceAlpha', 0.5, ...
        'MarkerEdgeColor', [0 0.4470 0.7410],  ...
        'MarkerEdgeAlpha', 0.5, ...
        'XJitter','rand', 'XJitterWidth', 0.33);
        % 12, [1 0.41 0.16], 'filled', ...

    hold off
    title(titlestring);
    ax = gca;
    ax.Box = 'on';
    ax.YLim = [-1.65,2.65];
    ax.YLabel.String = "log_{10}(Force) [nN]";
    ax.TickLabelInterpreter = 'tex';
    ax.XTick = (1:numel(factorNames));
    ax.XTickLabel = factorNames;
    ax.YTick = [-1.5:0.5:2.5];
    ax.YTickLabel = arrayfun(@(x)num2str(x,'%1.1f'),ax.YTick,'UniformOutput',false);
    ax.FontSize = 10;
    grid
    
    if contains(class(m),'table') && isTableCol(m,'pValue') 
        add_sigstar(m, f); 
    end

end

function factorNames = mkfactorNames(subgrouping_vars)

    if isTableCol(subgrouping_vars, "SubstrateChemistry") && ...
       isTableCol(subgrouping_vars, "BeadChemistry")

        subgrouping_vars = movevars(subgrouping_vars, ...
                                    "BeadChemistry", "Before","SubstrateChemistry");


    end

    [~, c] = size(subgrouping_vars);
    if c == 1
        factorNames = string(table2cell(subgrouping_vars));
    elseif c > 1
        factorNames = join(string(table2cell(subgrouping_vars)),'_');
    end
end


function out = add_sigstar(m, fig)

    m = m(m.pValue < 0.05, :);

    if ~isempty(m)
        CompareNames = table2cell(m(:,{'Group1','Group2'}));
        CompareNames = cellfun( @(x1,x2){char(x1),char(x2)}, CompareNames(:,1), CompareNames(:,2), 'UniformOutput', false);
        % CompareNames = string([m.Group1, m.Group2]);
        % CompareNamesTrimmed(1,:) = mat2cell(CompareNames, ones(size(CompareNames,1),1), size(CompareNames,2));
   
    
        figure(fig);
        sigstar(CompareNames, m.pValue);
    end

    out = 0;
end


function q = plot_ForceVsScale(DetachForceTable, BeadChemistry, SubstrateChemistry, Media, includeSpreadTF)

    if nargin < 5 || isempty(includeSpreadTF)
        includeSpreadTF = true;
    end

    mylinecolor = lines(7);

    q = filterForces(DetachForceTable, BeadChemistry, SubstrateChemistry, Media);

    idx = q.DomModeTF == 1;    

    scale_errn = q.ModeScale - q.confModeScale(:,1);
    scale_errp = q.confModeScale(:,2) - q.ModeScale;
    force_errn = q.ModeForce - q.confModeForce(:,1);
    force_errp = q.confModeForce(:,2) - q.ModeForce;
    forcespread_errn = q.ModeSpread - q.confModeSpread(:,1);
    forcespread_errp = q.confModeSpread(:,2) - q.ModeSpread;

    forcespreadn = q.ModeForce - ...
                   (force_errn + q.ModeSpread  + forcespread_errp);
    forcespreadp = q.ModeForce + ...
                   force_errp + q.ModeSpread + forcespread_errp;

    f = figure;
    f.Position = [202   560   340   255];
    hold on
        errorbar(q.ModeForce, ...
                 q.ModeScale, ...
                 scale_errn, ...
                 scale_errp, ...
                 force_errn, ...
                 force_errp, ...
                 'Marker', 'o', ...
                 'LineStyle', 'none', ...
                 'LineWidth', 1, ...
                 'CapSize', 6, ...
                 'Color', mylinecolor(1,:) );

        if includeSpreadTF
            % regular mode with spread {errorbar(x,y,err,ornt)}
            errorbar(q.ModeForce, ...
                     q.ModeScale, ...
                     forcespreadn, ...
                     forcespreadp, ...
                     "horizontal", ...
                     'Marker', 'none', ...
                     'LineStyle', 'none', ...
                     'LineWidth', 1, ...
                     'CapSize', 3, ...
                     'Color', mylinecolor(1,:) );
        end


    hold off
    legend('mode+conf', 'mode+spread+conf', 'dom mode', 'dom mode+spread', "Location","best");
    ax = gca;
    ax.YLim = [0 1];
    ax.XLim = [-2 2];
    ax.YTick = [0:0.1:1];
    ax.XLabel.String = 'ModeForce';
    ax.YLabel.String = 'ModeScale';     
    ax.Title.String = join([BeadChemistry, ":", SubstrateChemistry, "/" Media]);    
    grid on
end

function q = filterForces(DetachForceTable, BeadChemistry, SubstrateChemistry, Media)
    q = DetachForceTable;
    bc = BeadChemistry;
    sc = SubstrateChemistry;
    med = Media;
    
    if ~isempty(BeadChemistry)
        q = q(q.BeadChemistry      == bc, :);
    end
    
    if ~isempty(SubstrateChemistry)
        q = q(q.SubstrateChemistry == sc, :);
    end
    
    if ~isempty(Media) 
        q = q(q.Media == med,:);
    end
end


function fixBoxPlot_xticks(ax, BeadChemistry,SubstrateChemistry)
    labelArray = [BeadChemistry;SubstrateChemistry];
    tickLabels = strtrim(sprintf('%s\\newline%s\n', labelArray{:}));
    ax.XTickLabel = tickLabels;
    ax.TickLabelInterpreter = "tex";
end





