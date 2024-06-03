function f = ba_plot_forcecurve(logforce_nN, fractionLeft, logforceinterval, fout, startpoint, Nmodes)

    gray = [0.5 0.5 0.5];
    
    f = figure;
    hold on
        plot( logforce_nN, fractionLeft, 'Color', gray, 'Marker', '.', 'LineStyle', 'none');
        plot( logforceinterval(:,1), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');
        plot( logforceinterval(:,2), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');      
        plot( logforce_nN, fout.fcn(startpoint, logforce_nN), 'Color', 'r', 'LineStyle', '-');
    hold off
    xlabel('log_{10}(Force [nN])');
    ylabel('Factor left');
    legend('data', 'fit');
    title(['Nterms = ', num2str(Nmodes)]);
    drawnow

end