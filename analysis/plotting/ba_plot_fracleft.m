function ba_plot_fracleft(ba_process_data, plotFerrTF)

if nargin < 2 || isempty(plotFerrTF)
    plotFerrTF = false;
end

Data = ba_process_data.DetachForceTable;

% "Fraction Left" plot is always going to be plotting the Fraction of beads
% left to detach vs the force at which they detach. 

cmap = lines(height(Data));

f = figure;

for k = 1:height(Data)

    fiteq = Data.FitSetup(k).fcn;
    p = Data.FitParams(k,:);
    if iscell(p), p = p{1}; end
    
    mylogforce = log10(Data.RawData{k}.Force);
    mylogforceCI = log10(Data.RawData{k}.ForceInterval);
    myfractionleft = Data.RawData{k}.FractionLeft;
    
    figure(f);
    hold on;
    plot(mylogforce, fiteq(p, mylogforce), 'LineStyle', '-', ...
                                           'LineWidth', 1, ...
                                           'Color', cmap(k,:), ...
                                           'Marker', 'none');
    h = plot(mylogforce, myfractionleft, 'LineStyle', 'none', ...
                                         'Marker', 'o', ...
                                         'MarkerEdgeColor', cmap(k,:), ...
                                         'MarkerFaceColor', cmap(k,:));
    if plotFerrTF
        % tweaking the errorbar color to be lower saturation and higher luminance 
        hsv = rgb2hsv(cmap(k,:));
        hsv(2:3) = [hsv(2)*0.6 hsv(3) * 1.1];
        hsv(hsv>1) = 1;
        quietrgb = hsv2rgb(hsv);

%        % plotting as lines
%        plot(mylogforceCI, myfractionleft, 'LineStyle', '-', ...
%                                            'LineWidth', 0.5, ...
%                                            'color', quietrgb)
%        % plotting as bars only
%        plot(mylogforceCI, myfractionleft, 'LineStyle', 'none', ...
%                                            'Marker', '|', ...
%                                            'MarkerEdgeColor', quietrgb, ...
%                                            'MarkerFaceColor', quietrgb);                                               
%       % "manual" error bars
%         plot(mylogforceCI', repmat(myfractionleft,1,2)', 'LineStyle', '-', ...
%                                            'Color', quietrgb, ...
%                                            'Marker', '|', ...
%                                            'MarkerEdgeColor', quietrgb, ...
%                                            'MarkerFaceColor', quietrgb);                                               
        % default errorbars
        errorbar(mylogforce, myfractionleft, ...
                 mylogforce-mylogforceCI(:,1), mylogforceCI(:,2)-mylogforce, ...
                 'horizontal', 'LineStyle', 'None', 'Color', quietrgb);            
    end
    hold off;
    LineHandles(k,:) = h; %#ok<AGROW> 
    ystrings{k} = Data.BeadChemistry(k); %#ok<AGROW> 

end
        
ystrings = cellfun(@char, ystrings, 'UniformOutput', false);

figure(f);
xlabel('logForce [nN]', 'Interpreter', 'none' );
ylabel('Fraction Left', 'Interpreter', 'none' );
legend( LineHandles(:,1), ystrings, 'Location', 'SouthWest', 'Interpreter', 'none' );
ylim([0 1])
xlim([-1.5 1.5])
grid on




end

