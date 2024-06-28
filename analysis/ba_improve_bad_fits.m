function [ForceFitOut, OptimizedOut] = ba_improve_bad_fits(ForceFitTable, OptimizedStartTable, groupvars)

    groupvars = unique(['PlateID', groupvars], 'stable');

    ForceFitVars = ForceFitTable.Properties.VariableNames;
    OptimizedStartVars = OptimizedStartTable.Properties.VariableNames;

    Q = innerjoin(ForceFitTable, OptimizedStartTable, 'Keys', groupvars);
    figh = plot_data(Q);

    [idx, thresh] = fits_to_fix(Q, []);   

    count = 0;
    Nchk = 3; % Number of times to check for better fit

    Nfix = sum(idx);
    while (Nfix > 0) && (count < Nchk)
        Qbad = Q(idx,:);
        Qgood = Q(~idx,:);
        
        logentry(['Root-mean-squared error on ', num2str(Nfix), ' fit(s) exceeds limit. Refitting.']);
        [Qimproved, DiagT] = ba_gafit(Qbad, false);
        improvedRMSE = transpose(Qimproved.rmse(:));
        logentry(['New RMSE for fit(s) is: ', num2str(improvedRMSE), '.']);
        
        Q = vertcat(Qgood, Qimproved);
        
        plot_data(Q, figh);

        idx = fits_to_fix(Q, thresh);
        Nfix = sum(idx);
        count = count + 1;
        if count >= Nchk
            logentry('Exceeded limit of fit improvements. Moving on.');
        end
    end

    ForceFitOut = Q(:,ForceFitVars);
    OptimizedOut = Q(:,OptimizedStartVars);

end


function [idx, thresh_out] = fits_to_fix(Q, thresh_in)

    % Operate on bootstats data to get a cleaner value on the median/mad
    
    BootstatsT = vertcat(Q.BootstatT{:});   

    if isempty(thresh_in)    
        bad_fit_threshold = calc_iqr_threshold(BootstatsT.rmse);
    else
        bad_fit_threshold = thresh_in;
    end

    idx = ( Q.rmse >= bad_fit_threshold );
    badfits(1,:) = Q.rmse(idx);
    if any(idx)
        logentry(['Fit error (rmse) ' num2str(badfits) ' is greater than threshold, ' num2str(bad_fit_threshold) '.']);
    end
    thresh_out = bad_fit_threshold;
end


function [threshout, centralval, uncertainty] = calc_threshold(datain)
        datamed = median(datain);
        datamad = mad(datain);       
    
        threshout = datamed + datamad;
        centralval = datamed;
        uncertainty = datamad;
end


function [threshout, centralval, uncertainty] = calc_iqr_threshold(datain)
        datamed = median(datain);
        dataiqr = iqr(datain);       

        threshout = datamed + 1.5 * dataiqr;
        centralval = datamed;
        uncertainty = dataiqr;
end


function figh = plot_data(Q, figh)
    
    BootstatsT = vertcat(Q.BootstatT{:}); 

    if nargin < 2 || isempty(figh)
        figh = figure;
    end

    figure(figh);
    subplot(1,2,1);
    myhisto(BootstatsT.sse, 'sse', 'Sum-squared error', gca);
    subplot(1,2,2); 
    myhisto(BootstatsT.rmse, 'rmse', 'RMS error', gca);

end


function myhisto(data, myxlabel, mytitle, ax)
    [~, centralval, uncertainty] = calc_threshold(data);

    hold on
    histogram(data);

    colororder = get(ax, 'ColorOrder');
    Ncolors = size(colororder,1);
    ch = get(ax,'Children');
    Nhists = sum(arrayfun(@(x1)contains(class(x1), 'Histogram'),ch));    
    ColorN = mod(Nhists,Ncolors); 
    ColorN(ColorN == 0) = 7;
    mycolor = colororder(ColorN,:);
    
    plot(centralval, 0, 'Marker', '*', 'MarkerEdgeColor',mycolor);
    plot(centralval+uncertainty, 0, 'Marker', '<', 'MarkerEdgeColor',mycolor);
    hold off
    xlabel(myxlabel);
    ylabel('counts');
    title(mytitle);
    drawnow
end
