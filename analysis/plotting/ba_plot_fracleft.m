function ba_plot_fracleft(ba_process_data, aggregating_variables)

Data = ba_process_data;

% "Fraction Left" plot is always going to be plotting the Fraction of beads
% left to detach vs the force at which they detach. SO, that means all we
% need are the aggregating variables AND those relevant columns
ForceTableVars = {'Fid', 'SpotID', 'Force', 'ForceInterval', 'FractionLeft'};
FileTableVars = [{'Fid'}, aggregating_variables(:)'];
% FileTableVars = {'Fid', aggregating_variables{:}};

RelevantData = innerjoin(Data.ForceTable(:,ForceTableVars), ...
                         Data.FileTable(:, FileTableVars), ...
                         'Keys', 'Fid');


% foo = splitapply(@(x){sa_sortforce(x, 'descend')}, [RelevantData.Force, ...
%                                                   RelevantData.FractionLeft], ...
%                                                  g);

% vars = [aggregating_variables, {'FractionLeft'}];
% cending = [repmat("ascend", size(aggregating_variables)), "descend"];
% vars = [aggregating_variables, {'Force'}];
% cending = [repmat("ascend", size(aggregating_variables)), "ascend"];
% RelevantData = sortrows(RelevantData, vars, cending);

[g, grpF] = findgroups(RelevantData(:,aggregating_variables));
grpFstr = string(table2array(grpF));
ystrings = join(grpFstr, '_');

F = RelevantData.Force*1e9;
Flow = abs(F - RelevantData.ForceInterval(:,1)*1e9);
Fhigh= abs(RelevantData.ForceInterval(:,2)*1e9 - F);
frac = RelevantData.FractionLeft;

w = 1./abs(Fhigh-F);
% w = ones(numel(F),1);

cmap = lines(height(grpF));


f = figure;
fitfig = figure;

figure(f);
gscatter(F, frac, g, cmap);
legend(ystrings, 'Interpreter', 'none');
xlabel('Force [nN]');
ylabel('FractionLeft');

hold on;
gn = unique(g);
for k = 1:height(grpF)
    idx = g==gn(k);
    figure(f);
    errorbar(F(idx), frac(idx), Flow(idx), Fhigh(idx), 'horizontal', ...
                                      'LineStyle','None','Color',cmap(k,:));
                                  
    % Label axes
    xlabel( 'F', 'Interpreter', 'none' );
    ylabel( 'frac', 'Interpreter', 'none' );
    grid on

    % % Fit: 'ExponentialWithOffset'.
    [xData, yData, weights] = prepareCurveData( F(idx), frac(idx), w(idx) );

    % Set up fittype and options.
    ft = fittype( 'exp(-b*x)+c*exp(-d*x)+e', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.StartPoint = [0.192644774570146 0.568675630542075 0 0];
    opts.Weights = weights;
    opts.Upper = [Inf 1 Inf Inf];
    opts.Lower = [0 0 0 0];
    

        


    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );

    % Plot fit with data.
    figure( fitfig );%, 'Name', 'ExponentialWithOffset' );
    hold on;
%     h = plot( fitresult, xData, yData);%, 'MarkerColor', cmap(k,:) );
    h = plot( fitresult, xData, yData );
    set(h(1), 'Marker', 'o', 'MarkerEdgeColor', cmap(k,:), 'MarkerFaceColor', cmap(k,:))
    set(h(2), 'LineStyle', '-', 'LineWidth', 2, 'Color', cmap(k,:));
    errorbar(F(idx), frac(idx), Flow(idx), Fhigh(idx), 'horizontal', ...
                                  'LineStyle','None','Color',cmap(k,:));
    xlabel('Force [nN]')
    ylabel('Fraction Left');
    q(k,:) = h;
end
figure(fitfig);
ax = gca;
ax.XScale = 'log';
ystrings = {'PEG', 'PWM', 'WGA', 'SNA', 'HBE'};
legend( q(:,1), ystrings, 'Location', 'SouthWest', 'Interpreter', 'none' );
ylim([0 1])
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