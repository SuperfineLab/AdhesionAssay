function figh = plot_scatterforces(ForceFitTable, groupvars, GroupPlatesTF)

if nargin < 2 || isempty(groupvars)
    groupvars = {'PlateID', 'BeadChemistry'};
end

if nargin < 3 || isempty(GroupPlatesTF)
    GroupPlatesTF = false;
end

    ForceFitTable.BeadChemistry = reordercats(ForceFitTable.BeadChemistry, ...
                                              {'COOH', 'PEG', 'WGA', 'HBE'});
    
    BeadColorTable = ba_BeadColorTable;
    ForceFitTable = innerjoin(ForceFitTable, BeadColorTable);
    
    [~,gT] = findgroups(ForceFitTable(:,groupvars));
    gT.GroupName = join([string(gT.PlateID), string(gT.BeadChemistry)], "__");
    gT.gID = (1:height(gT))';

    disp(['Number of groups: ', num2str(height(gT))]);

    ForceFitTable = innerjoin(ForceFitTable,gT);
    
    % filter extreme/unrealistic forces (less than 1 pN and more than 10^5 [nN])
    idx = ForceFitTable.ModeForce > -3 & ForceFitTable.ModeForce < 5;
    logentry(['Filtered out ' num2str(sum(~idx)), '/', num2str(numel(idx)), ' unrealistic force values.']);
    qfilt = ForceFitTable(idx,:);
    
    if GroupPlatesTF
        figh = plot_grouped_scatter(qfilt,gT);
    else
        figh{1} = plot_scatter(qfilt,gT);
        figh{2} = plot_scatter(qfilt,gT,'PEG');
        figh{3} = plot_scatter(qfilt,gT,'WGA');
        figh{4} = plot_scatter(qfilt,gT,'HBE');
    end
end


function figh = plot_scatter(q, gT, filter, figh)

    if nargin < 4 || isempty(figh)
        figh = figure;
    end

    if nargin < 3 || isempty(filter)
        filter = '';
    end

    if ~isempty(filter)
        qfilt = q(q.BeadChemistry == string(filter), :);
    else
        qfilt = q;
    end
    % 
    % % function for scaling marker size according to amplitude
    % f = @(x)100*x+3;
    
    figure(figh);
    figh.Position = [1204 38 560 957];

    scatter(qfilt, "ModeForce", "gID", ...
    "filled", ...
    "SizeData", scale_markersize(qfilt.ModeScale), ...
    "ColorVariable", "BeadColor", ...
    "MarkerEdgeColor", [0.5 0.5 0.5], ...
    "MarkerEdgeAlpha", 1, ...
    "MarkerFaceAlpha", "flat", ...
    "AlphaData", falpha(qfilt.RelWidth));
    
    ax = gca; 
    ax.Position = [0.3252, 0.0491, 0.5798, 0.9415];
    ax.XLim = [-2 2];
    ax.YLim = [0, height(gT)+1];
    ax.YDir = 'reverse';
    ax.YTick = (1:height(gT));
    ax.YTickLabel = gT.GroupName; 
    ax.TickLabelInterpreter = 'none';

    yt = ax.YTickLabel;
    for k = 1:length(yt)
        if ~contains(yt{k},filter)
            ax.YTickLabel{k} = '';
        end
    end
  
    line([-2.25 2.25], [4.5 4.5], "Color", 'k');
    line([-2.25 2.25], [24.5 24.5], "Color", 'k');
    line([-2.25 2.25], [39.5 39.5], "Color", 'k');
    line([-2.25 2.25], [54.5 54.5], "Color", 'k');
    line([-2.25 2.25], [69.5 69.5], "Color", 'k');    
    line([-1 -1], [0 88], "Color", [0.75 0.75 0.75]);
end



function figh = plot_grouped_scatter(q, gT, filter, figh)

    if nargin < 4 || isempty(figh)
        figh = figure;
    end

    if nargin < 3 || isempty(filter)
        filter = '';
    end

    if ~isempty(filter)
        qfilt = q(q.BeadChemistry == string(filter), :);
    else
        qfilt = q;
    end

    s = scatter(qfilt, "gID", "ModeForce", ...
    "filled", ...
    "SizeData", scale_markersize(qfilt.ModeScale), ...
    "ColorVariable", "BeadColor", ...
    "MarkerEdgeColor", [0.5 0.5 0.5], ...
    "MarkerEdgeAlpha", 1, ...
    "MarkerFaceAlpha", "flat", ...
    "AlphaData", falpha(qfilt.RelWidth));
    
    ax = gca;
    ax.XLim = [0, height(gT)+1];
    ax.XTickLabel = ['', gT.GroupName(:)', ''];
    ax.TickLabelInterpreter = 'none';

    pause(0.1);

end


function fout = scale_markersize(x)   
% function for scaling marker size according to amplitude   
    fout = 100*x+3;
end

function alphaout = falpha(relwidth)
% Calculates out the alpha/transparency/opacity value for the glyph plotted
% in the grouped scatterforce plot.
    relwidth = relwidth(:);

    alphaout = NaN(size(relwidth));

    alphaout(relwidth < 1) = 1;
    alphaout(relwidth > 10) = 0.1;
    alphaout(relwidth > 100) = 0;
    
    % everywhere else needs mapping
    alphafunc = @(w)(-0.089.*w + 0.9889);
    idx = relwidth >= 1 & relwidth <= 10;
    alphaout(idx) = alphafunc(relwidth(idx));           
end


