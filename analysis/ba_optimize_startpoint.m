function optstart = ba_optimize_startpoint(logforce_nN, fractionLeft, weights, Nmodes)
% XXX @jeremy TODO: Add documentation for this function.
%
% Assembles a "protofit" that optimizes the fitting startpoints for the
% secondary final fits outputted by ba_fit_erf. This approach was designed
% to help matlab find the best possible fit while still providing
% user-friendly outputs (fit objects) the rest of the ba code is already 
% designed to use..
%

fout = ba_setup_fit('erf-old', weights, Nmodes);

% optstart = optimize_startpoint(fitfcn, fout.StartPoint, logforce_nN, fractionLeft, fout.lb, fout.ub);
optstart = optimize_startpoint_w(fout.fcn, fout.StartPoint, logforce_nN, fractionLeft, weights, fout.lb, fout.ub);
% optstart = optimize_startpoint_ga(fout.fcn, fout.StartPoint, logforce_nN, fractionLeft, weights, fout.lb, fout.ub);

% f = figure;
% plot( logforce_nN, fractionLeft, 'r.', ...
%       logforce_nN, fout.fcn(optstart, logforce_nN), 'b-');
% xlabel('log_{10}(Force [nN])');
% ylabel('Factor left');
% legend('data', 'fit');
% title(['Nterms = ', num2str(Nmodes)]);
% drawnow

end


% Solve best fit using global optimization and genetic algorithm
function optstart = optimize_startpoint_ga(fitfcn, p0, logforce_nN, fractionLeft, weights, lb, ub)

    [costfunction, costerror] = calculated_error(p0, fitfcn, logforce_nN, fractionLeft, weights);

    opts = optimoptions(@ga, 'Display', 'final');
%     probopts = optimoptions(@lsqnonlin, 'Display', 'final');
    problem = createOptimProblem('ga','x0',p0,'objective',costfunction,...
        'lb',lb,'ub',ub,options=opts);


    % Call the global optimizer
    [optstart, error] = ga(@(params) calculated_error(params, fitfcn, logforce_nN, fractionLeft, weights), ...
                           numel(p0), [], [], [], [], lb, ub, [], opts);
    
end


function optstart = optimize_startpoint(fitfcn, p0, logforce_nN, fractionLeft, lb, ub)

    opts = optimset('Display', 'off');
    [xfitted,errorfitted] = lsqcurvefit(fitfcn,p0,logforce_nN,fractionLeft,lb,ub, opts);
    
    probopts = optimoptions(@lsqcurvefit, 'Display', 'off');

    problem = createOptimProblem('lsqcurvefit','x0',p0,'objective',fitfcn,...
        'lb',lb,'ub',ub,'xdata',logforce_nN,'ydata',fractionLeft, options=probopts);
    
%     ms = MultiStart('PlotFcns',@gsplotbestf);
    ms = MultiStart("Display","off");
    [optstart,errormulti] = run(ms,problem,100);
end


function optstart = optimize_startpoint_w(fitfcn, p0, logforce_nN, fractionLeft, weights, lb, ub)

    costfunction = @(p) weights .* (fitfcn(p,logforce_nN)-fractionLeft).^2;

    opts = optimset('Display',      'off', ...
                    'MaxFunEvals',   26000, ...
                    'MaxIter',       24000, ...
                    'TolFun',        1e-07, ...
                    'TolX',          1e-07, ...
                    'DiffMinChange', 1e-08, ...
                    'DiffMaxChange', 0.01);

    [myfit,myfiterror] = lsqnonlin(costfunction,p0,lb,ub,opts);
    
    probopts = optimoptions(@lsqnonlin, 'Display', 'off'); % Display: 'final' or 'off'
    
    problem = createOptimProblem('lsqnonlin','x0',p0,'objective',costfunction,...
        'lb',lb,'ub',ub,options=probopts);
    
%     ms = MultiStart('PlotFcns',@gsplotbestf);
    ms = MultiStart("Display","off");
    [optstart,errormulti] = run(ms,problem,100);
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


