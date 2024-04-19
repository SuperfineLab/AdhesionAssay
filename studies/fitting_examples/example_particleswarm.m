%
% fit without constraints
%


clear pstart optimized_params fval exitflag output
clear ps_summary

Data = B.DetachForceTable;

if ~exist('ps_summary', 'var')
    ps_summary = table('Size', [0 7], ...
                       'VariableTypes', {'categorical', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                       'VariableNames', {'PlateID', 'SwarmSize', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
end

Nmodes = 2;
Nsubsamples = 5;

% *** particleswarm-specific options ***
swarm_sz = 100;

% Define "particleswarm" optimization options that do not change during run
options = ba_fitoptions('particleswarm');
options.Display = 'final';

% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m);
    rawdata = Data.RawData{m};
    
    force = rawdata.Force;
    errforce = diff(rawdata.ForceInterval,[],2)/2;
    fractionLeft = rawdata.FractionLeft; 
    weights = rawdata.Weights;

    logforce_nN = log10(force);
    errbarlength  = log10(force + errforce)-log10(force);

    % open new figure and plot the original data (with errorbars)
    fig = 1000+(100*Nmodes)+m;
    figure(fig); 
    clf
    plot(logforce_nN, fractionLeft, 'b.');
    hold on    
        e = errorbar( gca, logforce_nN, fractionLeft, errbarlength, 'horizontal', '.', 'CapSize',3);
        e.LineStyle = 'none';
        e.Color = 'b';
        title(string(PlateID), 'Interpreter','none');
    hold off
    
    % configure everything using current data (includes weights)
    fout  = ba_fit_setup(Nmodes, weights);
    

    % Some number (k) of subsampling fits to generate. This could also
    % be changed to monitor changes in algorithm style parameter sweeps,
    % e.g., swarm-size for particleswarms.
    for k = 1:Nsubsamples    
    
        tic 
        
        % Call the global optimizer [x,fval,exitflag,output,population,scores] 
        [optimized_params(k,:), fval(k,1), exitflag(k,1), output(k,1)] = particleswarm(@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
                                        fout.Nparams, fout.lb, fout.ub, options);
        
        rchisq(k,:) = red_chisquare(optimized_params(k,:), fout.fcn, logforce_nN, fractionLeft);
        
        t = toc;
        
        tmp_ps = table(PlateID, swarm_sz, t, exitflag(k,1), optimized_params(k,:), fval(k,1), rchisq(k,:), ...
                     'VariableNames', {'PlateID', 'SwarmSize', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
        
        ps_summary = vertcat(ps_summary, tmp_ps);
        
        figure(fig); 
        % subplot(1,3,1); 
        hold on;
        plot(logforce_nN, fout.fcn(optimized_params(k,:), logforce_nN), 'k--'); 
        drawnow
    
    end
    
    legend(['data', 'error', compose('%02.6d',fval(:)')]);

end




function error = objectiveFunction(params, fitfcn, logforce_nN, fractionLeft, weights)
    % params: Parameters to be optimized, [a am as bm bs]
    % fitfcn: function to be fitted
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

