function weights = ba_weights(conf_lowhi, conflevel)
% assumes normal distribution in data
% conf_lowhi is the confidence interval data [low,high] column-wise
% conf_level is a factor, i.e., "95%" is inputted as 0.95


if nargin < 2 || isempty(conflevel)
    error('Confidence Level is a necessary input.')
end

if nargin < 1 || isempty(conf_lowhi)
    error('[Low High] confidence interval data are a needed input.');
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
weights = 1 ./ (deltaCI/critval).^2;
weights = weights ./ max(weights);
