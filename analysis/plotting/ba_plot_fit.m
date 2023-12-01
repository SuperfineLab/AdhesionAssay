function ba_plot_fit(fitresult, force, errforce, pct_left, figurehandle)

if nargin < 5 || isempty(figurehandle)
    figurehandle = figure;
end

    logforce = log10(force);
    errlogforce = log10(force + errforce)-log10(force);
            
    % Plot fit with data.
    figurehandle.Name = 'erf fit';    
    try
        h = plot( fitresult, logforce, pct_left, 'predobs' );
        legend( h, 'y vs. x with w', 'hbe', 'Lower bounds (hbe)', 'Upper bounds (hbe)', 'Location', 'NorthEast', 'Interpreter', 'none' );
        % Label axes
        xlabel( 'log(force [nN])', 'Interpreter', 'none' );
        ylabel( 'Fraction Left', 'Interpreter', 'none' );
        grid on

        hold on            
            e = errorbar( gca, logforce, pct_left, errlogforce, 'horizontal', '.');
            e.LineStyle = 'none';
            e.Color = 'b';
        hold off
    catch
        clf;
        text(0.5,0.5,'Error while plotting.');
    end
    drawnow
end