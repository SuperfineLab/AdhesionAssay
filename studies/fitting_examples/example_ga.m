% Global optimization fitting routine for Adhesion Assay using the
% genetic algorithm. This algorithm serves as a good choice over 
% the particleswarm because it allows for fitting with constraints. It is
% painfully slow, though.
%

clear ps optimized_params error exitflag 
clear ga_summary

Data = B.DetachForceTable;

if ~exist('ga_summary', 'var')
    ga_summary = table('Size', [0 9], ...
                       'VariableTypes', {'categorical', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                       'VariableNames', {'PlateID', 'Run', 'MaxGenerations', 'PopulationSize', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
end

Nmodes = 4;
Nruns = 3;

% Define "ga" optimization options that do not change during run
options = ba_fitoptions("ga");
options.FunctionTolerance = 1e-7;
options.PlotFcn = {'gaplotscores','gaplotbestf'};
options.UseParallel = true;

% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m);
    rawdata = Data.RawData{m};
    
    logforce_nN = log10(rawdata.Force);
    logforceinterval = log10(rawdata.ForceInterval);
    fractionLeft = rawdata.FractionLeft; 
    weights = rawdata.Weights;

    % *** ga-specific options ***
    max_generations = 1500;
    options.MaxGenerations = max_generations;
    options.PopulationSize = floor(numel(logforce_nN)/2);

    fig = 1000+(100*Nmodes)+m;
    
    gray = [0.5 0.5 0.5];

    figure(fig); 
    clf;
    hold on
        plot( logforce_nN, fractionLeft, 'Color', gray, 'Marker', '.', 'LineStyle', 'none');
        plot( logforceinterval(:,1), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');
        plot( logforceinterval(:,2), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');      
    hold off
    xlabel('log_{10}(Force [nN])');
    ylabel('Fraction left');
    legend('data', 'fit');
    title(join([string(PlateID) ', ' num2str(Nmodes) ' modes'], ''), 'Interpreter','none'); 
    drawnow

    fout  = ba_fit_setup(Nmodes, weights);

    % Some number (k) of subsampling fits to generate. This could also
    % be changed to monitor changes in algorithm style parameter sweeps,
    % e.g., swarm-size for particleswarms.
    for k = 1:Nruns
    
        % If changing options for parameter search, do it here
        
        tic 
        
        % Call the global optimizer [x,fval,exitflag,output,population,scores] 
        [optimized_params(k,:), error(k,1), exitflag(k,1)] = ga(@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
                                        fout.Nparams, fout.Aeq, fout.beq, [], [], fout.lb, fout.ub, [], options);
        
        rchisq(k,:) = red_chisquare(optimized_params(k,:), fout.fcn, logforce_nN, fractionLeft);
        
        t=toc
        
        tmpga = table(PlateID, k, max_generations, pop_size, t, exitflag(k,1), optimized_params(k,:), error(k,1), rchisq(k,:), ...
                     'VariableNames', {'PlateID', 'Run', 'MaxGenerations', 'PopulationSize', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
        
        ga_summary = vertcat(ga_summary, tmpga);
        
        figure(fig); 
        % subplot(1,3,1); 
        hold on;
        plot(logforce_nN, fout.fcn(optimized_params(k,:), logforce_nN), 'r-'); 
        drawnow
    
    
    end

    legend(['data', 'error', 'error', compose('%02.6d',error(:)')]);

end


function error = objectiveFunction(params, fitfcn, logforce_nN, fractionLeft, weights)
    % params: Parameters to be optimized, [a am as bm bs]
    % xdata: Independent variable data
    % ydata: Dependent variable data
    % weights: Weight values for each data point


    % Calculate model predictions using params and xdata
    model_predictions = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    weighted_errors = weights .* (model_predictions - fractionLeft).^2;
%     weighted_errors = smooth(weighted_errors,5);
    error = sum(weighted_errors);
end

