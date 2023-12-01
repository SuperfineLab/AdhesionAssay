function ba_plot_fit(fitresult, logforce, pct_left, weights)
        % Plot fit with data.
        figure( 'Name', 'erf fit' );
        h = plot( fitresult, logforce, pct_left, 'predobs' );
        legend( h, 'y vs. x with w', 'hbe', 'Lower bounds (hbe)', 'Upper bounds (hbe)', 'Location', 'NorthEast', 'Interpreter', 'none' );
        % Label axes
        xlabel( 'log(force [nN])', 'Interpreter', 'none' );
        ylabel( 'Fraction Left', 'Interpreter', 'none' );
        grid on

        errlength = log10(10.^logforce + 1./weights);
        e = errorbar( gca, logforce, pct_left, errlength, 'horizontal');
        e.LineStyle = 'none';
        e.Color = 'b';
end