function ba_plot_fracleft(ba_process_data, aggregating_variables, plotFerrTF)

if nargin < 3 || isempty(plotFerrTF)
    plotFerrTF = false;
end

Data = ba_process_data.DetachForceTable;

% "Fraction Left" plot is always going to be plotting the Fraction of beads
% left to detach vs the force at which they detach. SO, that means all we
% need are the aggregating variables AND those relevant columns
ForceTableVars = {'Fid', 'SpotID', 'Force', 'ForceInterval', 'FractionLeft'};
FileTableVars = [{'Fid'}, aggregating_variables(:)'];
% FileTableVars = {'Fid', aggregating_variables{:}};



cmap = lines(height(Data));


f = figure;

for k = 1:height(Data)

    myfit = Data.FitObject{k};
    mylogforce = log10(Data.RawData{k}.Force);
    mylogforceCI = log10(Data.RawData{k}.ForceInterval);
    myfractionleft = Data.RawData{k}.FractionLeft;
    
    logerr = ba_ci2err(mylogforce, mylogforceCI, 'log', 'log');
    mylogforce_errlow = logerr(:,1);
    mylogforce_errhigh = logerr(:,2);

    figure(f);
    hold on;
    if contains(class(Data.FitObject{k}), 'cfit')
        h = plot(myfit, mylogforce, myfractionleft);
        set(h(1), 'Marker', 'o', 'MarkerEdgeColor', cmap(k,:), 'MarkerFaceColor', cmap(k,:))
        set(h(2), 'LineStyle', '-', 'LineWidth', 2, 'Color', cmap(k,:));
    else
        h = plot(mylogforce, myfractionleft, 'o');
        set(h(1), 'Marker', 'o', 'MarkerEdgeColor', cmap(k,:), ...
                  'MarkerFaceColor', cmap(k,:));
    end

    if plotFerrTF
        h = errorbar(mylogforce, myfractionleft, mylogforce_errlow, mylogforce_errhigh);
%             , 'horizontal', 'LineStyle','None','Color',cmap(k,:));
    end

    LineHandles(k,:) = h;
    ystrings{k} = Data.BeadChemistry(k);

end

        
ystrings = cellfun(@char, ystrings, 'UniformOutput', false);

figure(f);
xlabel('logForce [nN]', 'Interpreter', 'none' );
ylabel('Fraction Left', 'Interpreter', 'none' );
grid on

ax = gca;
% ax.XScale = 'log';

legend( LineHandles(:,1), ystrings, 'Location', 'SouthWest', 'Interpreter', 'none' );
ylim([0 1])
xlim([-1.5 1.5])
grid on

% hold off;
% figure(f)
% ax = gca;
% ax.XScale = 'log';
% ax.YScale = 'linear';
% ylim([0 1.02])
% grid on




end


% function outs = sa_sortforce(forceANDfractionleft, direction)
% 
%     if nargin < 2 || isempty(direction)
%         direction = 'ascend';
%     end
% 
%     [outs,Fidx] = sortrows(forceANDfractionleft, direction);
% 
% end