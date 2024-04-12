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

fitname = 'erf-new';
Nmodes = 2;
Nruns = 3;

% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m);
    rawdata = Data.RawData{m};
    
    force = rawdata.Force;
    errforce = rawdata.ForceError;
    factorLeft = rawdata.PctLeft; 
    weights = rawdata.Weights;

    logforce_nN = log10(force);
    errbarlength  = log10(force + errforce)-log10(force);
    
    % *** ga-specific options ***
    max_generations = 1500;
    pop_size = floor(numel(logforce_nN)/2);
    
    % Define "ga" optimization options that do not change during run
    options = optimoptions("ga");
    options.MaxGenerations = max_generations;
    options.PopulationSize = pop_size;
    options.FunctionTolerance = 1e-7;
    options.PlotFcn = {'gaplotscores','gaplotbestf'};
    options.UseParallel = true;

    fig = 1000+(100*Nmodes)+m;
    
    figure(fig); 
    clf
    hold on
    plot(logforce_nN, factorLeft, 'b.');
    % plot(logforce_nN-errbarlength, factorLeft, 'b.', logforce_nN+errbarlength, factorLeft, 'b.');
    e = errorbar( gca, logforce_nN, factorLeft, errbarlength, 'horizontal', '.', 'CapSize',2);
    e.LineStyle = 'none';
    e.Color = 'b';
    title(string(PlateID), 'Interpreter','none');
    
    fout  = ba_setup_fit(fitname, weights, Nmodes);

    % Some number (k) of subsampling fits to generate. This could also
    % be changed to monitor changes in algorithm style parameter sweeps,
    % e.g., swarm-size for particleswarms.
    for k = 1:Nruns
    
        % If changing options for parameter search, do it here
        
        tic 
        
        % Call the global optimizer [x,fval,exitflag,output,population,scores] 
        [optimized_params(k,:), error(k,1), exitflag(k,1)] = ga(@(p) objectiveFunction(p, fout.fcn, logforce_nN, factorLeft, weights), ...
                                        fout.Nparams, fout.Aeq, fout.beq, [], [], fout.lb, fout.ub, [], options);
        
        rchisq(k,:) = reduced_chisquare(optimized_params(k,:), fout.fcn, logforce_nN, factorLeft);
        
        t=toc
        
        tmpga = table(PlateID, k, max_generations, pop_size, t, exitflag(k,1), optimized_params(k,:), error(k,1), rchisq(k,:), ...
                     'VariableNames', {'PlateID', 'Run', 'MaxGenerations', 'PopulationSize', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
        
        ga_summary = vertcat(ga_summary, tmpga);
        
        figure(fig); 
        % subplot(1,3,1); 
        hold on;
        plot(logforce_nN, fout.fcn(optimized_params(k,:), logforce_nN), 'k--'); 
        drawnow
    
    
    end

    legend(['data', 'error', compose('%02.6d',error(:)')]);

end


function error = objectiveFunction(params, fitfcn, logforce_nN, factorLeft, weights)
    % params: Parameters to be optimized, [a am as bm bs]
    % xdata: Independent variable data
    % ydata: Dependent variable data
    % weights: Weight values for each data point


    % Calculate model predictions using params and xdata
    model_predictions = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    weighted_errors = weights .* (model_predictions - factorLeft).^2;
%     weighted_errors = smooth(weighted_errors,5);
    error = sum(weighted_errors);
end

function redcs = reduced_chisquare(params, fitfcn, logforce_nN, factorLeft)
    % Calculate model predictions using params and xdata
    model_predictions = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    chisquare = sum( (model_predictions - factorLeft).^2 ./  factorLeft);

    dof = numel(logforce_nN) - numel(params);

    redcs = chisquare / dof;

end

