function ba_plot_violins(ba_process_data, aggregating_variables, plotorder, includeMaxTF)

if nargin < 4 || isempty(includeMaxTF)
    includeMaxTF = false;
end

    Data = ba_process_data;
    aggVars = aggregating_variables(:);

    if ~iscell(aggVars)
        error('Need cell array of aggregating variables');
    end
    % {'BeadChemistry', 'Media'}
    [g, BeadCountTable] = findgroups(Data.FileTable(:,aggVars));
    BeadCountTable.TotalBeads = splitapply(@sum, Data.FileTable.FirstFrameBeadCount, g);

    FileVars(1,:) = [{'Fid'}; aggVars];
    FTable = join(Data.ForceTable, Data.FileTable(:,FileVars));
    FTable = innerjoin(FTable, BeadCountTable, 'Keys', aggVars);
    FTable(FTable.Force <= 0,:) = [];

    [gF, grpF] = findgroups(FTable(:,aggVars));
    
    grpFstr = string(table2array(grpF));
    if size(grpFstr,2) > 1
        ystrings = join(grpFstr, '_');
    else
        ystrings = grpFstr;
    end
    
    maxforce = 90e-9;

    if includeMaxTF
        grpF.Force = splitapply(@(x1,x2){sa_attach_stuck_beads(x1,x2,maxforce)}, FTable.Force, ...
                                                                                 FTable.TotalBeads, ...
                                                                                 gF);
    else
        grpF.Force = splitapply(@(x1){sa_beads_assemble(x1)}, FTable.Force, gF);
    end
                                                                         

N = cellfun(@numel, grpF.Force, 'UniformOutput', false);
N = cell2mat(N);
ForceMatrix = NaN(max(N), numel(unique(g)));

for k = 1:height(grpF)
    Forces = grpF.Force{k};
    ForceMatrix(1:length(Forces),k) = Forces(:);
end

% ForceMatrix = log10(ForceMatrix);

h = figure; 
violin(ForceMatrix * 1e9, 'facecolor', [1 1 0.52], 'mc', '', 'medc', '');
% violin(ForceMatrix + 9, 'facecolor', [1 1 0.52], 'mc', '', 'medc', '');

figure(h);
hold on;
boxplot(ForceMatrix * 1e9, 'Notch', 'on', 'Labels', ystrings);
% boxplot(ForceMatrix + 9, 'Notch', 'on', 'Labels', ystrings);
grid;
ylabel('Force [nN]');

ax = gca;
ax.YLim = [-5 100];
% [gMean, gSEM, gStd, gVar, gMeanCI] = grpstats(RelevantData.Force, g, {'mean', 'sem', 'std', 'var', 'meanci'});
% gCov = gStd ./ gMean;
% 
% T = table(N, gMean, gStd, gCov, gSEM, gVar, gMeanCI, 'VariableNames', ...
%         {'N', 'Mean', 'StDev', 'COV', 'StdErr', 'Var', 'MeanCI'});
% T = [grpF T];

end


function myforce = sa_attach_stuck_beads(force, beadcount, maxforce)
    numBeadsThatDetached = length(force);
    numStuckBeads = beadcount(1) - numBeadsThatDetached;
    myforce = [force(:) ; repmat(maxforce,numStuckBeads,1)];
end

function myforce = sa_beads_assemble(forces)
    myforce = forces;
end