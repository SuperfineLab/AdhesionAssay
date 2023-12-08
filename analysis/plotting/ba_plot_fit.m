function ba_plot_fit(fitresult, force, errforce, pct_left, figurehandle)

if nargin < 5 || isempty(figurehandle)
    figurehandle = figure;
end

    logforce = log10(force);
    errlogforce = log10(force + errforce)-log10(force);
            
    % Plot fit with data.
    figurehandle.Name = 'erf fit';    
    clf
    hold on
    try
        
%             h = plot( fitresult, logforce, pct_left, 'predobs' );
%             legend( h, 'y vs. x with w', 'hbe', 'Lower bounds (hbe)', 'Upper bounds (hbe)', 'Location', 'NorthEast', 'Interpreter', 'none' );
            h = plot( fitresult, logforce, pct_left );
            legend( h, 'y vs. x with w', 'hbe', 'Location', 'NorthEast', 'Interpreter', 'none' );

            xlabel( 'log(force [nN])', 'Interpreter', 'none' );
            ylabel( 'Fraction Left', 'Interpreter', 'none' );
            grid on

        
            e = errorbar( gca, logforce, pct_left, errlogforce, 'horizontal', '.');
            e.LineStyle = 'none';
            e.Color = 'b';
        
    catch        
        text(0.5,0.5,'Error while plotting.');
    end
    hold off
    drawnow
end