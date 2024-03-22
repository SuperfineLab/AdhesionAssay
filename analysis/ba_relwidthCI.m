function outs = ba_relwidthCI(val, conf_interval)
% calculates the confidence intervals relative width, which is the 
% overall size of the confidence interval normalized by the central or 
% measured value over which the confidence interval is defined.
%

    outs = abs(diff(conf_interval,[],2)) ./ val; 

end
