function [optstart, diagT] = ba_optimize_startpoint(logforce_nN, logforceinterval, fractionLeft, weights, Nmodes)
% XXX @jeremy TODO: Add documentation for this function.
%
% Assembles a "protofit" that optimizes the fitting startpoints for the
% secondary final fits outputted by ba_fit_erf. This approach was designed
% to help matlab find the best possible fit while still providing
% user-friendly outputs (fit objects) the rest of the ba code is already 
% designed to use..
%

fout = ba_fit_setup(Nmodes);

% optstart = optimize_lsqcurvefit(fout.fcn, fout.StartPoint, logforce_nN, fractionLeft, fout.lb, fout.ub);
% optstart = optimize_lsqnonlin(fout, logforce_nN, fractionLeft, weights);
% optstart = optimize_lsqnonlin(fout.fcn, fout.StartPoint, logforce_nN, fractionLeft, [], fout.lb, fout.ub);
[optstart, diagT] = optimize_ga(fout, logforce_nN, fractionLeft, weights);

figure;
hold on
    plot( logforce_nN, fractionLeft, 'Color', 'r', 'Marker', '.', 'LineStyle', 'none');
    plot( logforceinterval(:,1), fractionLeft, 'Color', [0.8 0.8 0.8], 'LineStyle', '-');
    plot( logforceinterval(:,2), fractionLeft, 'Color', [0.8 0.8 0.8], 'LineStyle', '-');      
    plot( logforce_nN, fout.fcn(optstart, logforce_nN), 'Color', 'k', 'LineStyle', '-');
hold off
xlabel('log_{10}(Force [nN])');
ylabel('Factor left');
legend('data', 'fit');
title(['Nterms = ', num2str(Nmodes)]);
drawnow

end


% Solve best fit using global optimization and genetic algorithm
function [optstart, diagT] = optimize_ga(fout, logforce_nN, fractionLeft, weights)

    Ns = numel(logforce_nN);
    
    % *** header for ga-specific options (tweaked for the input data) ***
    max_generations = 6000;
    popsize = floor(Ns/2);
    elitecount = ceil(popsize * 0.28);
    weights = ones(size(weights));

    if elitecount >= popsize, elitecount = popsize-1; end
    if sum(weights) == numel(weights), FuncTol = 1e-8; else FuncTol = 2e-10; end

    % Define "ga" optimization options that do not change during run
    options = ba_fitoptions("ga");
    options.PlotFcn = {'gaplotscores','gaplotbestlogf'};
    options.UseParallel = true;
    options.MaxGenerations = max_generations;
    options.MutationFcn = @mutationadaptfeasible;
    options.FunctionTolerance = FuncTol;
    options.PopulationSize = popsize;   
    options.ConstraintTolerance = 1e-4;
    options.CrossoverFraction = 0.49;
    options.EliteCount = elitecount; 
    options.HybridFcn = 'fmincon';


    % Call the global optimizer
    tic
    [optstart, error, exitflag, output] = ga(@(params) gafit_error(params, fout.fcn, logforce_nN, fractionLeft, weights), ...
                           fout.Nparams, fout.Aineq, fout.bineq, [], [], fout.lb, fout.ub, [], options);
    t = toc;

    rchisq = red_chisquare(optstart, fout.fcn, logforce_nN, fractionLeft, weights);
    
    RawData = table(logforce_nN, fractionLeft, weights, ...
                    'VariableNames', {'LogForce_nN', 'FractionLeft', 'Weights'});
    diagT =  table(optstart, error, rchisq, t, exitflag, output.generations, max_generations, popsize, {RawData}, ...
             'VariableNames', {'OptimizedParameters', 'TotalError', 'RedChiSq', 'SolveTime', 'ExitFlag', 'GenerationSolveCount', 'MaxGenerations', 'PopulationSize', 'RawData'});
    
end


function optstart = optimize_lsqcurvefit(fitfcn, p0, logforce_nN, fractionLeft, lb, ub)

    opts = optimset('Display', 'off');    
    
    probopts = optimoptions(@lsqcurvefit, 'Display', 'off');

    problem = createOptimProblem('lsqcurvefit','x0',p0,'objective',fitfcn,...
        'lb',lb,'ub',ub,'xdata',logforce_nN,'ydata',fractionLeft, options=probopts);
    
%     ms = MultiStart('PlotFcns',@gsplotbestf);
    ms = MultiStart("Display","off");

    % [X,FVAL,EXITFLAG,OUTPUT,SOLUTIONS] = run(ms, problem, 100);
    [optstart,errormulti] = run(ms,problem,100);
end



function optstart = optimize_lsqnonlin(fout, logforce_nN, fractionLeft, weights)

    if isempty(weights)
        weights = ones(size(logforce_nN));
    end

    costfunction = @(p) weights .* (fout.fcn(p,logforce_nN)-fractionLeft).^2;

    probopts = optimoptions(@lsqnonlin, 'Display', 'off'); % Display: 'final' or 'off'    
    problem = createOptimProblem('lsqnonlin','x0',fout.StartPoint,'objective',costfunction,...
        'lb',fout.lb,'ub',fout.ub, options=probopts);
    
%     ms = MultiStart('PlotFcns',@gsplotbestf);
    ms = MultiStart("Display","off");
    [optstart,errormulti] = run(ms,problem,200);
end


function error = gafit_error(params, fitfcn, logforce_nN, fractionLeft, weights)
    % params: Parameters to be optimized, [a am as bm bs]
    % logforce_nN: detachment force in nN
    % fractionLeft: fraction of beads still attached
    % weights: Weight values for each DETACHMENT FORCE


    % Calculate model predictions using params and xdata
    predicted_fractionLeft = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    weighted_errors = weights .* (predicted_fractionLeft - fractionLeft).^2;
    error = sum(weighted_errors, [], 'omitnan');
end


