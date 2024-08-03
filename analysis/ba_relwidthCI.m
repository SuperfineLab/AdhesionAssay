function outs = ba_relwidthCI(val, conf_interval)
% calculates the confidence intervals relative width, which is the 
% overall size of the confidence interval normalized by the central or 
% measured value over which the confidence interval is defined.
%

    [Nrows, Ncols] = size(val);

    if Nrows == 1 % column-ordered
        DIFFDIM = 1;
    elseif Ncols == 1 % row-ordered
        DIFFDIM = 2;
    else
        error('Not set up for larger than 2d matrices. Expand the function.');
    end
    
    outs = abs(diff(conf_interval,[],DIFFDIM) ./ val); 

end
