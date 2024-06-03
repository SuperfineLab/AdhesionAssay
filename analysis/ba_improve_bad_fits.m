function [DetachOut, OptimizedOut] = ba_improve_bad_fits(DetachForceTable, OptimizedStartTable, groupvars)

    groupvars = unique(['PlateID', groupvars], 'stable');

    DetachVars = DetachForceTable.Properties.VariableNames;
    OptimizedVars = OptimizedStartTable.Properties.VariableNames;

    Q = innerjoin(DetachForceTable, OptimizedStartTable, 'Keys', groupvars);
    figh = plot_sse(Q);

    [idx, thresh] = fits_to_fix(Q, []);   

    count = 0;
    Nchk = 3;

    Nfix = sum(idx);
    while (Nfix > 0) && (count < Nchk)
        Qbad = Q(idx,:);
        Qgood = Q(~idx,:);
        
        logentry(['Sum-squared error on ', num2str(Nfix), ' fit(s) exceeds limit. Refitting.']);
        [Qimproved, DiagT] = ba_gafit(Qbad, false);
        improvedSSE(1,:) = Qimproved.sse;
        logentry(['New SSE for fit(s) is: ', num2str(improvedSSE), '.']);
        
        Q = vertcat(Qgood, Qimproved);
        
        plot_sse(Q, figh);

        idx = fits_to_fix(Q, thresh);
        Nfix = sum(idx);
        count = count + 1;
        if count >= Nchk
            logentry('Exceeded limit of fit improvements. Moving on.');
        end
    end

    DetachOut = Q(:,DetachVars);
    OptimizedOut = Q(:,OptimizedVars);

end


function [idx, thresh_out] = fits_to_fix(Q, thresh_in)

    % Operate on bootstats data to get a cleaner value on the median/mad
    BootstatsT = vertcat(Q.BootstatT{:});   

    if isempty(thresh_in)    
        bad_fit_threshold = calc_threshold(BootstatsT.sse);
    else
        bad_fit_threshold = thresh_in;
    end

    idx = ( Q.sse >= bad_fit_threshold );
    badfits(1,:) = Q.sse(idx);
    logentry(['Fit error (sse) ' num2str(badfits) ' is greater than threshold, ' num2str(bad_fit_threshold) '.']);

    thresh_out = bad_fit_threshold;
end


function [threshout, centralval, uncertainty] = calc_threshold(sse)
        ssemed = median(sse);
        ssemad = mad(sse);       
    
        threshout = ssemed + ssemad;
        centralval = ssemed;
        uncertainty = ssemad;
end

% function [threshout, centralval, uncertainty] = calc_threshold(sse)
%         ssemed = median(sse);
%         sseiqr = iqr(sse);       
%     
%         threshout = ssemed + 1.5 * sseiqr;
%         centralval = ssemed;
%         uncertainty = sseiqr;
% end


function figh = plot_sse(Q, figh)
    
    BootstatsT = vertcat(Q.BootstatT{:}); 

    if nargin < 2 || isempty(figh)
        figh = figure;
    end

    data = BootstatsT.sse;
    [~, centralval, uncertainty] = calc_threshold(data);
    

    figure(figh);
    hold on
    histogram(data);

    colororder = get(gca, 'ColorOrder');
    Ncolors = size(colororder,1);
    ch = get(gca,'Children');
    Nhists = sum(arrayfun(@(x1)contains(class(x1), 'Histogram'),ch));    
    ColorN = mod(Nhists,Ncolors); 
    ColorN(ColorN == 0) = 7;
    mycolor = colororder(ColorN,:);
    
    plot(centralval, 0, 'Marker', '*', 'MarkerEdgeColor',mycolor);
    plot(centralval+uncertainty, 0, 'Marker', '<', 'MarkerEdgeColor',mycolor);
    hold off
    xlabel('sse');
    ylabel('counts');
    title('Sum-squared error');
    drawnow
end
