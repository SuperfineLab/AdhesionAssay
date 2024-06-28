function figh = ba_plot_fit(DetachForceTable, figh, figopts)
%
%
% b bootfit
% m median-line
% d datapoints
% e confidence-intervals/error
% p parameter text box (for one curve/condition)
% c follow adhesionassay colortable definition
% l legend
%

if nargin < 3 || isempty(figopts)
    figopts = 'bmdepcl';
end

if nargin < 2 || isempty(figh)
    figh = figure;
end

BeadColorTable = ba_BeadColorTable;

Q = DetachForceTable;
Q = innerjoin(Q, BeadColorTable);

Nq = height(Q);


    if contains(figopts, 'c')
        stdclr = Q.BeadColor;
    else
        stdclr = lines(Nq);
    end

PlateIDs = string(Q.PlateID);
BeadChems = string(Q.BeadChemistry);
SlideChems = string(Q.SubstrateChemistry);

twist = @(x)reshape(transpose(x),[],1);

colonstring = repmat(":",Nq,1);
dashstring = repmat("-",Nq,1);

leglabels = join([PlateIDs, dashstring, BeadChems, colonstring, SlideChems], '');



clf(figh);

for k = 1:Nq

    legcount = 0;

    fcn = Q.BootFitSetup(k).fcn;
    MedianFitParams = Q.FitParams{k};
    logforce = log10(Q.RawData{k}.Force);
    logforceconf = log10(Q.RawData{k}.ForceInterval);
    fractionLeft = Q.RawData{k}.FractionLeft;
    bootstat = Q.BootstatT{k};

    MedianFitCurve = fcn(MedianFitParams, logforce);

    figure(figh); 
    % figh.Position(3:4) = [420 315];
    hold on

    % [~,edges,bin] = histcounts(bootstat.adjrsquare,10);
    
    if contains(figopts, 'b')
        Nb = size(bootstat,1); % number of bootstat curves
        for m = 1:Nb
            myfitparams = bootstat.FitParams{m,:};
            myfitcurve = fcn(myfitparams,logforce);
    
            plot(logforce, myfitcurve, 'LineStyle', '-', ...
                                       'Color', bootstat_color(stdclr(k,:)));
        end
        legcount = legcount + Nb;
    else 
        Nb = 0;
    end


    if contains(figopts, 'm')
        plot(logforce, MedianFitCurve, 'Color', stdclr(k,:), ...
                                       'LineStyle', '-', ...
                                       'LineWidth', 2);
        legcount = legcount+1;
    end


    if contains(figopts, 'd')    
        plot(logforce, fractionLeft, 'Marker','o', ...
                                     'MarkerSize', 3, ...
                                     'MarkerEdgeColor', (stdclr(k,:)), ...
                                     'MarkerFaceColor', (stdclr(k,:)), ...
                                     'LineStyle','none');
        legcount = legcount+1;
    end


    if contains(figopts, 'e')
        plot(logforceconf(:,1), fractionLeft, 'Marker','>', ...
                                              'MarkerSize', 2, ...
                                              'MarkerEdgeColor', confint_color(stdclr(k,:)), ...
                                              'MarkerFaceColor', 'none', ...
                                              'LineStyle','none');
        plot(logforceconf(:,2), fractionLeft, 'Marker','<', ...
                                              'MarkerSize', 2, ...
                                              'MarkerEdgeColor', confint_color(stdclr(k,:)), ...
                                              'MarkerFaceColor','none', ...
                                              'LineStyle','none');
        legcount = legcount+2;
    end


    if contains(figopts, 'p')

        str = string(num2str(MedianFitParams(1:3))); 

        % If there are 6 fit parameters (two modes) then break up the
        % parameters according to mode
        if numel(MedianFitParams) == 6
            str = vertcat(str, string(num2str(MedianFitParams(4:6))));
        end

        % Don't use parameter textbox if plotting more than one curve
        if Nq == 1
            annotation("textbox", [0.14 0.22 0.72 0.065], 'String', str, 'FitBoxToText', 'on')
        end

    end

end  % for-loop over force data table

if contains(figopts, 'l')
    leg = strings(Nq,legcount);
    leg(:,Nb+1) = leglabels;
    leg = twist(leg);
    legend(leg, 'Interpreter','none');
end

% set up the figure title
if Nq == 1
    title(join(string(Q{k,1:5}), ', '), 'Interpreter','none');
else
    title('');
end

xlabel('logForce [nN]');
ylabel('Fraction Left');
xlim([-1.5 1.5]);
ylim([0 1]);
grid on;

end


function clrOUT = bootstat_color(clrIN)
    hsv = rgb2hsv(clrIN);
    hsv = hsv .* [1 0.3 1];
    hsv(hsv>1,:) = 1;
    clrOUT = hsv2rgb(hsv);
end


function clrOUT = confint_color(clrIN)
        hsv = rgb2hsv(clrIN);
        hsv(1, :) = hsv .* [1 0.8 1.2];
        hsv(hsv>1) = 1;
        clrOUT = hsv2rgb(hsv);
end


function figh = ba_plot_fit_old(fiteq, fitparams, force, force_interval, fractionleft, figh)

if nargin < 5 || isempty(figh)
    figh = figure;
end

    logforce = log10(force);

    if ~isempty(force_interval)
        errlogforce = log10(force + force_interval)-log10(force);
    end
            
    % Plot fit with data.
    figh.Name = 'erf fit';    
    clf
    hold on

    fitdata = fiteq(fitparams, logforce);
    
    try
        
%             h = plot( fitresult, logforce, pct_left, 'predobs' );
%             legend( h, 'y vs. x with w', 'hbe', 'Lower bounds (hbe)', 'Upper bounds (hbe)', 'Location', 'NorthEast', 'Interpreter', 'none' );
            axh = plot( logforce, fractionleft, 'ro', ...
                        logforce, fitdata, 'k-');
            legend( axh, 'y vs. x with w', '', 'Location', 'NorthEast', 'Interpreter', 'none' );

            xlabel( 'log(force [nN])', 'Interpreter', 'none' );
            ylabel( 'Fraction Left', 'Interpreter', 'none' );
            grid on

        % if ~isempty(force_interval)
        %     e = errorbar( gca, logforce, fractionleft, errlogforce, 'horizontal', '.');
        %     e.LineStyle = 'none';
        %     e.Color = 'b';
        % end
        
    catch        
        text(0.5,0.5,'Error while plotting.');
    end
    hold off
    ylim([-0.1 1.1]);
    drawnow
end