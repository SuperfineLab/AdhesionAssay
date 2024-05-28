function weights = ba_weights(conf_lowhi, conflevel, weightmethod, nbins)
% BA_WEIGHTS computes weights for forces based on measurement certainty
%
% weights = ba_weights(conf_lowhi, conflevel, weightmethod, nbins)
%
% Output: 
%   weights - weights on the datapoints
%
% Inputs: 
%   conf_lowhi* - two-column vector containing [low,high] conf intervals
%   conflevel* - confidence level for "conf_lowhi" (likely 0.95)
%   weightmethod - one from the below list of weighting computation options
%        [ {unweighted}, inverseconf, scaled-inversebin, quantile ]
%   nbins - number of bins available for weightmethod, default: 3
%
% Notes: 
%   - assumes normal distribution in data
%   - (*) denotes required inputs
%   - 'unweighted' sets all weights equal to one.
%   - 'inverseconf' weight values use 1/(confidence interval breadth),
%     normalized to one (highest confidence).
%   - 'scaled-inversebin' bins the 'inverseconf' values to nbins to reduce 
%     introducing extra noise in the cost functions for minimization.
%   - 'quantile' creates *equally-sized* bins, i.e., each quantile bin will
%     contain the same number of datapoints, equalizing the representation of 
%     each quantile as weights, again normalized to a maximum value of one.
%     

if nargin < 4 || isempty(nbins)
    nbins = 3;
end

if nargin < 3 || isempty(weightmethod)
    weightmethod = 'unweighted';
end

if nargin < 2 || isempty(conflevel)
    error('Confidence Level is a necessary input.')
end

if nargin < 1 || isempty(conf_lowhi)
    error('[Low High] confidence interval data are necessary inputs.');
end

if size(conf_lowhi,2) ~= 2
    error('Confidence intervals must be provided as "lower-value higher-value," column-wise.');
end


critval = norminv((1 + conflevel) / 2, 0, 1);

% diff used this way calculates the difference between two columns
deltaCI = diff(conf_lowhi, 1, 2);

% The weights used to influence later fitting methods is related to the
% inverse of the total uncertainty. I've scaled these to a maximum value of
% one, which should give the smallest uncertainty full weight and the
% largest uncertainty a minimal (but not zero) weight in the fit.
protoweights = 1 ./ (deltaCI/critval).^2;
scaledweights = protoweights ./ max(protoweights);

% The weight value depends on the method we choose.
switch weightmethod
    case 'unweighted'
        weights = ones(size(scaledweights));
    case 'inverseconf'
        weights = scaledweights;
    case 'inversebin'       
        [counts, edges, bin] = histcounts(1-scaledweights, [0:1/nbins:1]);
        weights = 1./bin;
    case 'scaled-inversebin'
        [counts, edges, bin] = histcounts(scaledweights, [0:1/nbins:1]);
        weights = bin./nbins;
    case 'quantile'
        myedges = quantile(scaledweights, nbins-1);
        myedges = [0 myedges 1];
        [counts, edges, bin] = histcounts(scaledweights, myedges);
        weights = bin./nbins;        
    otherwise
        error(['The chosen weighting method, ', upper(weightmethod), ' is undefined.']);
end

