% Global optimization fitting routine for Adhesion Assay using the
% patternsearch algorithm. This algorithm serves as a better choice over 
% the particleswarm because it allows for fitting with constraints.
%

clear pstart optimized_params fval exitflag output
clear pat_summary   % comment this out if comparing parameters across several runs

Data = B.DetachForceTable;

if ~exist('pat_summary', 'var')
    pat_summary = table('Size', [0 7], ...
                       'VariableTypes', {'categorical', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                       'VariableNames', {'PlateID', 'StartPoint', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
end

Nmodes = 2;
Nsubsamples = 5;

% Define "patternsearch" optimization options that do not change during run
options = ba_fitoptions("patternsearch"); 
options.Display = 'final';


% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m);
    rawdata = Data.RawData{m};
    
    logforce_nN = log10(rawdata.Force);
    logforceinterval = log10(rawdata.ForceInterval);
    fractionLeft = rawdata.FractionLeft; 
    weights = rawdata.Weights;

    gray = [0.5 0.5 0.5];

    % Some number (m) of plates to process
    fig = 1000+(100*Nmodes)+m;   
    figure(fig); 
    clf
    hold on
        plot( logforce_nN, fractionLeft, 'Color', gray, 'Marker', '.', 'LineStyle', 'none');
        plot( logforceinterval(:,1), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');
        plot( logforceinterval(:,2), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');      
    hold off
    xlabel('log_{10}(Force [nN])');
    ylabel('Fraction left');
    title(string(PlateID), 'Interpreter','none');

    % configure everything using current data (includes weights)
    fout  = ba_fit_setup(Nmodes, weights);
    
    % Some number (k) of subsampling fits to generate. This could also
    % be changed to monitor changes in algorithm style parameter sweeps,
    % e.g., swarm-size for particleswarms.
    for k = 1:Nsubsamples
    
    
        tic 
        
        % Call the global optimizer [x,fval,exitflag,output,population,scores] 
        % [optimized_params(k,:), error(k,1), exitflag(k,1)] = ga(@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
        %                                 fout.Nparams, fout.Aeq, fout.beq, [], [], fout.lb, fout.ub, [], options);
        
        [optimized_params(k,:), fval(k,1), exitflag(k,1), output(k,1)] = patternsearch(@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
                                        fout.StartPoint, [], [], fout.Aeq, fout.beq, fout.lb, fout.ub, [], options);
        
        rchisq(k,:) = red_chisquare(optimized_params(k,:), fout.fcn, logforce_nN, fractionLeft);
        
        t = toc;
        
        tmp_ps = table(PlateID, fout.StartPoint, t, exitflag(k,1), optimized_params(k,:), fval(k,1), rchisq(k,:), ...
                     'VariableNames', {'PlateID', 'StartPoint', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
        
        pat_summary = vertcat(pat_summary, tmp_ps);
        
        
        figure(fig); 
        % subplot(1,3,1); 
        hold on
            plot(logforce_nN, fout.fcn(optimized_params(k,:), logforce_nN), 'Color', 'r', 'LineStyle', '-');
        hold off
        drawnow
    
    end
    
    legend(['data', 'error', '', compose('%02.6d',fval(:)')]);

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


