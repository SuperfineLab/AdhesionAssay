function figh = ba_plot_fit(fiteq, fitparams, force, force_interval, pct_left, figh)

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
    try
        
%             h = plot( fitresult, logforce, pct_left, 'predobs' );
%             legend( h, 'y vs. x with w', 'hbe', 'Lower bounds (hbe)', 'Upper bounds (hbe)', 'Location', 'NorthEast', 'Interpreter', 'none' );
            axh = plot( fitparams, logforce, pct_left, 'predobs' );
            legend( axh, 'y vs. x with w', '', 'Location', 'NorthEast', 'Interpreter', 'none' );

            xlabel( 'log(force [nN])', 'Interpreter', 'none' );
            ylabel( 'Fraction Left', 'Interpreter', 'none' );
            grid on

        if ~isempty(force_interval)
            e = errorbar( gca, logforce, pct_left, errlogforce, 'horizontal', '.');
            e.LineStyle = 'none';
            e.Color = 'b';
        end
        
    catch        
        text(0.5,0.5,'Error while plotting.');
    end
    hold off
    ylim([-0.1 1.1]);
    drawnow
end