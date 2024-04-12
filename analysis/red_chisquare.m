function redcs = red_chisquare(params, fitfcn, logforce_nN, fractionLeft)
% XXX @jeremy TODO: document this function

    % Calculate model predictions using params and xdata
    model_predictions = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    chisquare = sum( (model_predictions - fractionLeft).^2 ./  fractionLeft);

    dof = numel(logforce_nN) - numel(params);

    redcs = chisquare / dof;
end

