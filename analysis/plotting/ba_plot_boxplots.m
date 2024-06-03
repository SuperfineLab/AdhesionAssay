function [ForceMatrix, ystrings, p] = ba_plot_boxplots(ba_process_data, groupvars, plotorder)

Data = ba_process_data;

% "Fraction Left" plot is always going to be plotting the Fraction of beads
% left to detach vs the force at which they detach. SO, that means all we
% need are the aggregating variables AND those relevant columns
ForceTableVars = {'Fid', 'Force'};
FileTableVars = [{'Fid'}, groupvars(:)'];


RelevantData = innerjoin(Data.ForceTable(:,ForceTableVars), ...
                         Data.FileTable(:, FileTableVars), ...
                         'Keys', 'Fid');

[g, grpF] = findgroups(RelevantData(:,groupvars));
grpFstr = string(table2array(grpF));
ystrings = join(grpFstr, '_');

AllForces = RelevantData.Force;
AllForces(AllForces < 0) = NaN;

N = splitapply(@numel, AllForces, g);

ForceMatrix = NaN(max(N), numel(unique(g)));

for k = 1:numel(unique(g))
    Forces = AllForces( g == k);
    ForceMatrix(1:length(Forces),k) = Forces(:);
end

% ForceMatrix = ForceMatrix*1e9;
ForceMatrix = log10(ForceMatrix);
ForceMatrix = ForceMatrix + 9; % convert to nanonewtons

h = figure; 
% violin(ForceMatrix, 'facecolor', [1 1 0.52], 'mc', '', 'medc', '');

ForceMatrix = ForceMatrix(:,plotorder);
ystrings = ystrings(plotorder);

figure(h);
boxplot(ForceMatrix, 'Labels', ystrings, 'Notch', 'on', 'Widths', 0.25);
ylabel('Detachment Force, log_{10}(F) [nN]');
grid on;
ax = gca;
ax.YLim = [-2 2];
% ax.YTickMode = 'manual';
% ax.YScale = 'log';

ax.GridAlpha = 0.5;
ax.XMinorTick = 'off';
% ax.YMinorTick = 'off';
ax.XMinorGrid = 'off';
ax.YMinorGrid = 'off';

% % set up the  Y-axis ticklabels to look like log plot
% YTicksPlain = ax.YTick;
% for k = 1:numel(YTicksPlain)
%     tmp = num2str(YTicksPlain(k), '%02.1f');
%     YTicksFixed{k,1} = ['10^{', tmp, '}'];
% end
% ax.YTickLabel = YTicksFixed;
% ax.TickLabelInterpreter = 'tex';

% Thicken the lines on the boxplot notched-boxes
grp = ax.Children;
lns = grp.Children;
for k = 1:length(lns)
    lns(k).LineWidth = 1.5;
end


N = size(ForceMatrix,2);
m = 1;  % simple iterator through the pairs (sloppy sloppy)
% % % For every pair of datasets (number of columns is > 2)
% % if N >=2
% %     for k = 1:2:N
% % 
% %         ForceGroup = ForceMatrix(:, [k, k+1]);
% % 
% %         [p(m),hyp(m)] = ranksum(ForceMatrix(:, k), ForceMatrix(:,k+1));
% % 
% %         % if there's significance, put the stars on the plot
% %         if p(m)<0.05
% %             Hsig = sigstar({[k,k+1]},p(m)); 
% % 
% %             % Increase the size of the stars
% %             for k = 1:size(Hsig,1)
% %                 this_h = Hsig(k,2);
% %                 set(this_h, 'FontSize', 16);
% %             end
% %         end    
% %         m=m+1;
% %     end
% % end

% [gMean, gSEM, gStd, gVar, gMeanCI] = grpstats(RelevantData.Force, g, {'mean', 'sem', 'std', 'var', 'meanci'});

% gCov = gStd ./ gMean;
% 
% T = table(N, gMean, gStd, gCov, gSEM, gVar, gMeanCI, 'VariableNames', ...
%         {'N', 'Mean', 'StDev', 'COV', 'StdErr', 'Var', 'MeanCI'});
% T = [grpF T];
if ~exist('p')
    p=[];
end

return