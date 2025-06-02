function redchisq = red_chisquare(params, fitfcn, logforce_nN, fractionLeft, weights)
% RED_CHISQUARE computes the weighted-reduced chi-square statistic
%
% redchisq = red_chisquare(params, fitfcn, logforce_nN, fractionLeft, weights)
%
% Output:
%
% Inputs:
%   params 
%   fitfcn 
%   logforce_nN 
%   fractionLeft 
%   weights
%
% Note: Uses the weighted-reduced chi-square equation from: 
% https://en.wikipedia.org/wiki/Reduced_chi-squared_statistic
% reduced_chi_square = r'*W*r/nu, where r is the residuals from the fit, W
% is the weight matrix, and nu is the degrees of freedom (Ndatapoints - Nparams)
%

    if nargin < 5 || isempty(weights)
        weights(1,:) = ones(numel(logforce_nN),1);
    end

    % Calculate model predictions using params and xdata
    model_predictions = fitfcn(params, logforce_nN);

    % residuals, R, from model prediction
    R(:,1) = model_predictions - fractionLeft;
    W = diag(weights);
    dof = numel(logforce_nN) - numel(params);

    redchisq = (R' * W * R)/dof;

end

