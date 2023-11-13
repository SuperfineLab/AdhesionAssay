function ba_plot_fracleft_new(ba_process_data, aggregating_variables)

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

    figure(f);
    hold on;
    if contains(class(Data.FitObject{k}), 'cfit')
            h = plot(Data.FitObject{k}, log10(Data.ForceData{k}), Data.PctLeftData{k});%, 'predobs');
        
            set(h(1), 'Marker', 'o', 'MarkerEdgeColor', cmap(k,:), 'MarkerFaceColor', cmap(k,:))
            set(h(2), 'LineStyle', '-', 'LineWidth', 2, 'Color', cmap(k,:));
    %     errorbar(F(idx), frac(idx), Flow(idx), Fhigh(idx), 'horizontal', ...
    %                                   'LineStyle','None','Color',cmap(k,:));
        q(k,:) = h;
    end

end
figure(f);
xlabel('logForce [nN]', 'Interpreter', 'none' );
ylabel('Fraction Left', 'Interpreter', 'none' );
grid on

ax = gca;
% ax.XScale = 'log';
ystrings = {'PEG', 'PWM', 'WGA', 'SNA', 'HBE'};
legend( q(:,1), ystrings, 'Location', 'SouthWest', 'Interpreter', 'none' );
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