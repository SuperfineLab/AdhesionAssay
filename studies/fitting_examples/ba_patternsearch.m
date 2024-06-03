function pat_summary = ba_patternsearch(dftable,startpoint, plotTF)

% Global optimization fitting routine for Adhesion Assay using the
% patternsearch algorithm. This algorithm serves as a better choice over 
% the particleswarm because it allows for fitting with constraints.
%
if nargin < 3 || isempty(plotTF)
    plotTF = false;
end

if ~exist('pat_summary', 'var')
    pat_summary = table('Size', [0 7], ...
                       'VariableTypes', {'categorical', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                       'VariableNames', {'PlateID', 'StartPoint', 'SolveTime', 'ExitFlag', 'OptimizedStartParameters', 'TotalError', 'RedChiSq'});
end

Data = dftable;
Nmodes = 2;
Nsubsamples = 1;

% configure everything using current data
fout  = ba_fit_setup(Nmodes);

if nargin < 2 || isempty(startpoint)
    startpoint = fout.StartPoint;
end
    
% Define "patternsearch" optimization options that do not change during run
options = ba_fitoptions("patternsearch"); 

options.Algorithm = 'nups-mads';
options.MeshTolerance = 5e-10; % Tolerance on scaling down the mesh size.
options.StepTolerance = 1e-10;
options.InitialMeshSize = 1;
options.FunctionTolerance = 1e-6; 
options.MaxFunctionEvaluations = 1200*fout.Nparams; % Maximum number of objective function evaluations.
options.MaxIterations = 300*fout.Nparams; % Maximum number of iterations.
options.ConstraintTolerance = 1e-6;
options.MaxTime = 180;
options.AccelerateMesh = true;
options.UseCompletePoll = true;
% options.Cache = "on";
options.PlotFcn = {'psplotbestlogf'};
options.Display = 'diagnose';
options.UseParallel = true;

% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m);
    rawdata = Data.RawData{m};
    
    logforce_nN = log10(rawdata.Force);
    logforceinterval = log10(rawdata.ForceInterval);
    fractionLeft = rawdata.FractionLeft; 
%     weights = rawdata.Weights;
    weights = ones(size(rawdata.Weights));

    gray = [0.5 0.5 0.5];

    if plotTF
        fig{m} = figure; 
        figure(fig{m}); 
        clf
        hold on
            plot( logforce_nN, fractionLeft, 'Color', gray, 'Marker', '.', 'LineStyle', 'none');
            plot( logforceinterval(:,1), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');
            plot( logforceinterval(:,2), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');      
        hold off
        xlabel('log_{10}(Force [nN])');
        ylabel('Fraction left');
        title(string(PlateID), 'Interpreter','none');
        fig{m}.Units = 'normalized';
        fig{m}.Position = [0.6161    0.5185    0.2917    0.3889];
    end
    
    % Some number (k) of subsampling fits to generate. This could also
    % be changed to monitor changes in algorithm style parameter sweeps,
    % e.g., swarm-size for particleswarms.
    for k = 1:Nsubsamples
    
    
        tic 
        
        % Call the global optimizer [x,fval,exitflag,output,population,scores] 
        [optimized_params(k,:), fval(k,1), exitflag(k,1), output(k,1)] = patternsearch(@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
                                        startpoint, fout.Aineq, fout.bineq, [], [], fout.lb, fout.ub, [], options);
%         [optimized_params(k,:), fval(k,1), exitflag(k,1), output(k,1)] = patternsearch(@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
%                                         startpoint, [], [], fout.Aeq, fout.beq, fout.lb, fout.ub, [], options);
        
        rchisq(k,:) = red_chisquare(optimized_params(k,:), fout.fcn, logforce_nN, fractionLeft, weights);
        
        t(k,1) = toc;
        
        tmp_ps = table(PlateID, startpoint, t, exitflag(k,1), optimized_params(k,:), fval(k,1), rchisq(k,:), ...
                     'VariableNames', {'PlateID', 'StartPoint', 'SolveTime', 'ExitFlag', 'OptimizedStartParameters', 'TotalError', 'RedChiSq'});
        
        pat_summary = vertcat(pat_summary, tmp_ps);
        

        if plotTF
           figure(fig{m}); 
           hold on
             plot(logforce_nN, fout.fcn(optimized_params(k,:), logforce_nN), 'Color', 'r', 'LineStyle', '-');
           hold off
           drawnow
        end
    
    end

    if plotTF
        legend(['data', 'error', '', compose('%02.6d',fval(:)')]);
    end

    logentry(['Total solve time: ', num2str(sum(t), '%2.1f'), ' seconds.'] );    
pause;
end

end


function error = objectiveFunction(params, fitfcn, logforce_nN, fractionLeft, weights)
    % params: Parameters to be optimized, [a am as b bm bs]
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
