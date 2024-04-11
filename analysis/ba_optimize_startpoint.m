function optstart = ba_optimize_startpoint(logforce_nN, logforceinterval, fractionLeft, weights, Nmodes)
% XXX @jeremy TODO: Add documentation for this function.
%
% Assembles a "protofit" that optimizes the fitting startpoints for the
% secondary final fits outputted by ba_fit_erf. This approach was designed
% to help matlab find the best possible fit while still providing
% user-friendly outputs (fit objects) the rest of the ba code is already 
% designed to use..
%

fout = ba_setup_fit(Nmodes, weights);

% optstart = optimize_lsqcurvefit(fout.fcn, fout.StartPoint, logforce_nN, fractionLeft, fout.lb, fout.ub);
optstart = optimize_lsqnonlin(fout.fcn, fout.StartPoint, logforce_nN, fractionLeft, weights, fout.lb, fout.ub);
% optstart = optimize_lsqnonlin(fout.fcn, fout.StartPoint, logforce_nN, fractionLeft, [], fout.lb, fout.ub);
% optstart = optimize_ga(fout.fcn, fout.StartPoint, logforce_nN, fractionLeft, weights, fout.lb, fout.ub);

gray = [0.5 0.5 0.5];

f = figure;
hold on
plot( logforce_nN, fractionLeft, 'Color', gray, 'Marker', '.', 'LineStyle', 'none');
plot( logforceinterval(:,1), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');
plot( logforceinterval(:,2), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');      
plot( logforce_nN, fout.fcn(optstart, logforce_nN), 'Color', 'r', 'LineStyle', '-');
hold off
xlabel('log_{10}(Force [nN])');
ylabel('Factor left');
legend('data', 'fit');
title(['Nterms = ', num2str(Nmodes)]);
drawnow

end


% Solve best fit using global optimization and genetic algorithm
function optstart = optimize_ga(fitfcn, p0, logforce_nN, fractionLeft, weights, lb, ub)

    [costfunction, costerror] = calculated_error(p0, fitfcn, logforce_nN, fractionLeft, weights);

    opts = optimoptions(@ga, 'Display', 'final');
    problem = createOptimProblem('ga','x0',p0,'objective',costfunction,...
        'lb',lb,'ub',ub,options=opts);


    % Call the global optimizer
    [optstart, error] = ga(@(params) calculated_error(params, fitfcn, logforce_nN, fractionLeft, weights), ...
                           numel(p0), [], [], [], [], lb, ub, [], opts);
    
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



function optstart = optimize_lsqnonlin(fitfcn, p0, logforce_nN, fractionLeft, weights, lb, ub)

    if isempty(weights)
        weights = ones(size(logforce_nN));
    end

    costfunction = @(p) weights .* (fitfcn(p,logforce_nN)-fractionLeft).^2;

    probopts = optimoptions(@lsqnonlin, 'Display', 'off'); % Display: 'final' or 'off'
    
    problem = createOptimProblem('lsqnonlin','x0',p0,'objective',costfunction,...
        'lb',lb,'ub',ub,options=probopts);
    
    ms = MultiStart('PlotFcns',@gsplotbestf);
    ms = MultiStart("Display","off");
    [optstart,errormulti] = run(ms,problem,200);
end


function [weighted_errors, error] = calculated_error(params, fitfcn, logforce_nN, fractionLeft, weights)
    % params: Parameters to be optimized, [a am as bm bs]
    % logforce_nN: detachment force in nN
    % fractionLeft: fraction of beads still attached
    % weights: Weight values for each DETACHMENT FORCE


    % Calculate model predictions using params and xdata
    predicted_fractionLeft = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    weighted_errors = weights .* (predicted_fractionLeft - fractionLeft).^2;
    error = sum(weighted_errors);
end


