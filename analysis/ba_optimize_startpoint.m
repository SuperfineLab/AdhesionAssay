function startfitT = ba_optimize_startpoint(logforce_nN, logforceinterval, fractionLeft, weights, Nmodes)
% XXX @jeremy TODO: Add documentation for this function.
%
% Assembles a "protofit" that optimizes the fitting startpoints for the
% secondary final fits outputted by ba_fit_erf. This approach was designed
% to help matlab find the best possible fit while still providing
% user-friendly outputs (fit objects) the rest of the ba code is already 
% designed to use..
%

fout = ba_fit_setup(Nmodes);

startfitT = optimize_ga(fout, logforce_nN, fractionLeft, weights);

% figure;
% hold on
%     plot( logforce_nN, fractionLeft, 'Color', 'r', 'Marker', '.', 'LineStyle', 'none');
%     plot( logforceinterval(:,1), fractionLeft, 'Color', [0.8 0.8 0.8], 'LineStyle', '-');
%     plot( logforceinterval(:,2), fractionLeft, 'Color', [0.8 0.8 0.8], 'LineStyle', '-');      
%     if all(isfinite(optstart))
%         plot( logforce_nN, fout.fcn(optstart, logforce_nN), 'Color', 'k', 'LineStyle', '-');
%     end
% hold off
% xlabel('log_{10}(Force [nN])');
% ylabel('Factor left');
% legend('data', 'fit');
% title(['Nterms = ', num2str(Nmodes)]);
% drawnow

end


% Solve best fit using global optimization and genetic algorithm
function gafitT = optimize_ga(fout, logforce_nN, fractionLeft, weights)

    RawData = table(logforce_nN, fractionLeft, weights, ...
                    'VariableNames', {'LogForce_nN', 'FractionLeft', 'Weights'});

    Ns = numel(logforce_nN);   

    % Handle the case where there's not enough data to fit the model.
    logentry(['Nparams = ' num2str(fout.Nparams)]);
    if Ns < (fout.Nparams+1) || fout.Nmodes == 0
        optstart = -Inf(1,6);
        gafitT = table('Size', [1 13], ...
            'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'struct', ...
                              'double', 'double', 'double', 'double', 'double', 'struct'}, ...
            'VariableNames', {'OptimizedStartParameters', 'TotalError', 'RedChiSq', 'SolveTime', 'ExitFlag', 'RngState', ...
                              'GenerationSolveCount', 'MaxGenerations', 'PopulationSize', 'FinalPop', 'FinalScore', 'gaOpts'});
        gafitT = standardizeMissing(gafitT, {0, NaN});
        gafitT.RngState = rng('default');
        gafitT.OptimizedStartParameters = {optstart};
        gafitT.gaOpts = ba_fitoptions("ga");
        logentry('Returning no fit parameters (not enough datapoints to fit the model.');
        return
    end

    % *** header for ga-specific options (tweaked for the input data) ***
    max_generations = 400;
    popsize = floor(Ns/2);
    elitecount = ceil(popsize * 0.3);
    FuncTol = 2e-10; 

    if elitecount >= popsize
        elitecount = popsize-1; 
    end

    % Define "ga" optimization options that do not change during run
    options = ba_fitoptions("ga");
    options.PlotFcn = {'gaplotscores','gaplotbestlogf'};
    options.UseParallel = true;
    options.MaxGenerations = max_generations;
    options.MutationFcn = @mutationadaptfeasible;
    options.FunctionTolerance = FuncTol;

    if popsize > 2 % weird error in ga when the popsize is too small
        options.PopulationSize = popsize;   
    end

    options.ConstraintTolerance = 0.5e-5;
    options.CrossoverFraction = 0.5;
    options.EliteCount = elitecount; 
    options.HybridFcn = 'fmincon';

    rng("shuffle");
    rngState = rng;

    % Call the global optimizer
    tic
    [optstart, error, exitflag, output, finalpop, finalscore] = ga(@(params) gafit_error(params, fout.fcn, logforce_nN, fractionLeft, weights), ...
                           fout.Nparams, fout.Aineq, fout.bineq, [], [], fout.lb, fout.ub, [], options);
    t = toc;

    rchisq = red_chisquare(optstart, fout.fcn, logforce_nN, fractionLeft, weights);


    gafitT =  table({optstart}, error, rchisq, t, exitflag, rngState, ...
                     output.generations, max_generations, popsize, ...
                    {finalpop}, {finalscore}, options, ...
                    'VariableNames', {'OptimizedStartParameters', 'TotalError', 'RedChiSq', 'SolveTime', 'ExitFlag', 'RngState', ...
                                      'GenerationSolveCount', 'MaxGenerations', 'PopulationSize', ...
                                      'FinalPop', 'FinalScore', 'gaOpts'});
    
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


