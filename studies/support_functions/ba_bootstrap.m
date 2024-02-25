function outs = ba_bootstrap(measurements, cis)
    % Example data: replace with your actual data
%     measurements = [value1, value2, value3, ...];  % Replace with your actual values
%     lower_cis = [lower_ci1, lower_ci2, lower_ci3, ...];   % Replace with your actual lower confidence intervals
%     upper_cis = [upper_ci1, upper_ci2, upper_ci3, ...];   % Replace with your actual upper confidence intervals
%     

    [lower_cis, upper_cis] = deal(cis(:,1), cis(:,2));

    % Take the logarithm of measurements
    log_measurements = log(measurements);
    
    % Number of bootstrap samples
    num_samples = 1000;
    
    % Preallocate arrays to store bootstrap results
    bootstrapped_means = zeros(1, num_samples);
    
    % Perform bootstrapping on log-transformed data
    for k = 1:num_samples
        % Generate a bootstrap sample by resampling with replacement
        bootstrap_indices = randi(length(log_measurements), 1, length(log_measurements));
        bootstrap_log_measurements = log_measurements(bootstrap_indices);
        
        % Calculate the weighted mean for the bootstrap sample
        weights = 1 ./ ((upper_cis(bootstrap_indices) - lower_cis(bootstrap_indices)) / 3.29).^2;  % Using the average width as a measure of uncertainty
        bootstrapped_means(k) = sum(weights .* exp(bootstrap_log_measurements)) / sum(weights);
    end
    
    % Calculate the mean of bootstrapped means (the final estimate of the weighted mean)
    final_weighted_mean = mean(bootstrapped_means);

    % Calculate the standard error of the bootstrapped means
    se_bootstrapped_means = std(bootstrapped_means);
    
    % Calculate the 90% confidence interval using percentiles
    confidence_interval_lower = prctile(bootstrapped_means, 5);
    confidence_interval_upper = prctile(bootstrapped_means, 95);

%     confidence_interval_lower = prctile(bootstrapped_means, 10);
%     confidence_interval_upper = prctile(bootstrapped_means, 90);

    
    % Display results
%     disp(['Bootstrapped Standard Error: ', num2str(se_bootstrapped_means)]);
%     disp(['90% Bootstrapped Confidence Interval: [', num2str(confidence_interval_lower), ', ', num2str(confidence_interval_upper), ']']);

    outs = [final_weighted_mean(:), se_bootstrapped_means(:), confidence_interval_lower(:), confidence_interval_upper(:)];
end