function ga_summary = ba_gafit(dftable, plotTF)

% Global optimization fitting routine for Adhesion Assay using the
% genetic algorithm. This algorithm serves as a good choice over 
% the particleswarm because it allows for fitting with constraints. It is
% painfully slow, though.
%
if nargin < 2 || isempty(plotTF)
    plotTF = false;
end

if ~exist('ga_summary', 'var')
    ga_summary = table('Size', [0 9], ...
                       'VariableTypes', {'categorical', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                       'VariableNames', {'PlateID', 'Run', 'MaxGenerations', 'PopulationSize', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'RedChiSq'});
end

Data = dftable;

Nmodes = 2;
Nruns = 1;

% Define "ga" optimization options that do not change during run
options = ba_fitoptions("ga");
options.FunctionTolerance = 1e-8;
options.PlotFcn = {'gaplotscores','gaplotbestlogf'};
options.UseParallel = true;


% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m);
    rawdata = Data.RawData{m};
    
    logforce_nN = log10(rawdata.Force);
    logforceinterval = log10(rawdata.ForceInterval);
    fractionLeft = rawdata.FractionLeft; 
    weights = rawdata.Weights;
%     weights = ones(size(rawdata.Weights));

    Np = numel(logforce_nN);

    % *** ga-specific options ***
    max_generations = 4000;
    popsize = floor(Np/2);
    elitecount = ceil(popsize * 0.333);
    if elitecount >= popsize, elitecount = popsize -1; end
    options.MaxGenerations = max_generations;
    if sum(weights) == numel(weights), FuncTol = 1e-7; else FuncTol = 2e-9; end
    options.FunctionTolerance = FuncTol;
    options.PopulationSize = popsize;   
    options.ConstraintTolerance = 1e-4;
    options.CrossoverFraction = 0.6;
    options.EliteCount = elitecount; 
    options.HybridFcn = 'fmincon';



    fig{m} = figure;
    xlabel('log_{10}(Force [nN])');
    ylabel('Fraction left');
    title(string(PlateID), 'Interpreter','none');
    title(join(string(Data{m,{'PlateID', 'BeadChemistry', 'SubstrateChemistry', 'Media', 'pH'}}), ', '), 'Interpreter','none');
    fig{m}.Units = 'normalized';
    fig{m}.Position = [0.6161    0.5185    0.2917    0.3889];


    fout  = ba_fit_setup(Nmodes, weights);

    % Some number (k) of subsampling fits to generate. This could also
    % be changed to monitor changes in algorithm style parameter sweeps,
    % e.g., swarm-size for particleswarms.
    for k = 1:Nruns
    
        % If changing options for parameter search, do it here
        
        tic 
        
        % Call the global optimizer [x,fval,exitflag,output,population,scores] 
        [optimized_params(k,:), error(k,1), exitflag(k,1)] = ga(@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
                                        fout.Nparams, fout.Aineq, fout.bineq, [], [], fout.lb, fout.ub, [], options);
        
        rchisq(k,:) = red_chisquare(optimized_params(k,:), fout.fcn, logforce_nN, fractionLeft, weights);
        
        t=toc;
        
        tmpga = table(PlateID, k, max_generations, floor(numel(logforce_nN)/2), t, exitflag(k,1), optimized_params(k,:), error(k,1), rchisq(k,:), ...
                     'VariableNames', {'PlateID', 'Run', 'MaxGenerations', 'PopulationSize', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'RedChiSq'});
        
        ga_summary = vertcat(ga_summary, tmpga);
        

    if plotTF                
        figure(fig{m}); 
        hold on
            plot( logforce_nN, fractionLeft, 'Color', [0.8 0.8 0.8], 'Marker', '.', 'LineStyle', 'none');
            plot( logforceinterval(:,1), fractionLeft, 'Color', [0.8 0.8 0.8], 'LineStyle', '-');
            plot( logforceinterval(:,2), fractionLeft, 'Color', [0.8 0.8 0.8], 'LineStyle', '-');      
            plot(logforce_nN, fout.fcn(optimized_params(k,:), logforce_nN), 'r-'); 
        hold off
    end
    
    end

   % legend(['data', 'error', 'error', compose('%02.6d',error(:)')]);

end % end for-loop

end % end function


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
    error = sum(weighted_errors, [], 'omitnan');
end



