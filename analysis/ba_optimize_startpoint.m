function optstart = ba_optimize_startpoint(logforce_nN, factorLeft, weights, Nterms)
% Assembles a "protofit" that optimizes the fitting startpoints for the
% secondary final fits outputted by ba_fit_erf. This approach was designed
% to help matlab find the best possible fit while still providing
% user-friendly outputs (fit objects) the rest of the ba code is already 
% designed to use..
%

% p = [a am as bm bs]
%                  1/2*(a   *erfc(((Fd)-am  )/(sqrt(2)*as  ))+(1-a   )*erfc(((Fd)-bm  )/(sqrt(2)*bs  )))
fitfcn{1}= @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3)))));
fitfcn{2} = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3)))+(1-p(1))*erfc(((Fd)-p(4))/(sqrt(2)*p(5)))));

%    [a  am   as   bm   bs ]
lb = [0 -Inf  0   -Inf  0  ];
ub = [1  Inf  Inf  Inf  Inf];

% p0 = [0.82582 0.07818 0.44268 0.10666 0.96190];
p0 = [0.85 -1.5 0.5 0.75 1];

k = 2*Nterms + 1;

% optstart = optimize_startpoint(fitfcn{Nterms}, p0(1:k), logforce_nN, factorLeft, lb(1:k), ub(1:k));
optstart = optimize_startpoint_w(fitfcn{Nterms}, p0(1:k), logforce_nN, factorLeft, weights, lb(1:k), ub(1:k));
% optstart = optimize_startpoint_ga(fitfcn{Nterms}, p0(1:k), logforce_nN, factorLeft, weights, lb(1:k), ub(1:k));

f = figure;
plot( logforce_nN, factorLeft, 'r.', ...
      logforce_nN, fitfcn{Nterms}(optstart, logforce_nN), 'b-');
xlabel('log_{10}(Force [nN])');
ylabel('Factor left');
legend('data', 'fit');
title(['Nterms = ', num2str(Nterms)]);
drawnow

end

% Solve best fit using global optimization and genetic algorithm
function optstart = optimize_startpoint_ga(fitfcn, p0, logforce_nN, factorLeft, weights, lb, ub)

    [costfunction, costerror] = calculated_error(p0, fitfcn, logforce_nN, factorLeft, weights);

    opts = optimoptions(@ga, 'Display', 'final');
%     probopts = optimoptions(@lsqnonlin, 'Display', 'final');
    problem = createOptimProblem('ga','x0',p0,'objective',costfunction,...
        'lb',lb,'ub',ub,options=opts);


    % Call the global optimizer
    [optstart, error] = ga(@(params) calculated_error(params, fitfcn{Nterms}, logforce_nN, factorLeft, weights), ...
                           numel(p0), [], [], [], [], lb, ub, [], opts);



    
%     ms = MultiStart('PlotFcns',@gsplotbestf);
%     ms = MultiStart("Display","off");
%     ms = MultiStart('UseParallel', true, 'Display', 'iter');
%     [optstart,errormulti] = run(ms,problem);
end



function optstart = optimize_startpoint(fitfcn, p0, logforce_nN, factorLeft, lb, ub)

    opts = optimset('Display', 'off');
    [xfitted,errorfitted] = lsqcurvefit(fitfcn,p0,logforce_nN,factorLeft,lb,ub, opts);
    
    probopts = optimoptions(@lsqcurvefit, 'Display', 'off');
    problem = createOptimProblem('lsqcurvefit','x0',p0,'objective',fitfcn,...
        'lb',lb,'ub',ub,'xdata',logforce_nN,'ydata',factorLeft, options=probopts);
    
%     ms = MultiStart('PlotFcns',@gsplotbestf);
    ms = MultiStart("Display","off");
    [optstart,errormulti] = run(ms,problem,100);
end


function optstart = optimize_startpoint_w(fitfcn, p0, logforce_nN, factorLeft, weights, lb, ub)

    costfunction = @(p) weights .* (fitfcn(p,logforce_nN)-factorLeft).^2;

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


% function optstart = optimize_startpoint_g(fitfcn, p0, logforce_nN, factorLeft, weights, lb, ub)
% 
%     [costfunction, err] = calculated_error(p0, fitfcn, logforce_nN, factorLeft, weights);
% 
%     opts = optimset('Display',       'off', ...
%                     'MaxFunEvals',   26000, ...
%                     'MaxIter',       24000, ...
%                     'TolFun',        1e-07, ...
%                     'TolX',          1e-07, ...
%                     'DiffMinChange', 1e-08, ...
%                     'DiffMaxChange', 0.01);
% 
%     [myfit,myfiterror] = lsqnonlin(costfunction,p0,lb,ub,opts);
% 
%     probopts = optimoptions(@lsqnonlin, 'Display', 'off'); % Display: 'final' or 'off'
%     problem = createOptimProblem('lsqnonlin','x0',p0,'objective',costfunction,...
%         'lb',lb,'ub',ub,options=probopts);
%     
% %     ms = MultiStart('PlotFcns',@gsplotbestf);
%     ms = MultiStart("Display","off");
%     [optstart,errormulti] = run(ms,problem,100);
% end



function [weighted_errors, error] = calculated_error(params, fitfcn, logforce_nN, factorLeft, weights)
    % params: Parameters to be optimized, [a am as bm bs]
    % logforce_nN: detachment force in nN
    % factorLeft: fraction of beads still attached
    % weights: Weight values for each DETACHMENT FORCE


    % Calculate model predictions using params and xdata
    predicted_factorLeft = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    weighted_errors = weights .* (predicted_factorLeft - factorLeft).^2;
    error = sum(weighted_errors);
end


function opts = setup_fitoptions(weights, Nmodes, startpoint)

    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );

    opts.Display = 'Off';
    opts.MaxFunEvals = 26000;
    opts.MaxIter = 24000;
    opts.Weights = weights;
    opts.TolFun = 1e-07;
    opts.TolX = 1e-07;
    opts.DiffMinChange = 1e-08;
    opts.DiffMaxChange = 0.01;

    % Lower and upper bounds for each parameter
    %    [a  am   as   bm   bs ]
    lb = [0 -Inf  0   -Inf  0  ];
    ub = [1  Inf  Inf  Inf  Inf];
    
    % Default starting points if none are available
    % p0 = [0.82582 0.07818 0.44268 0.10666 0.96190];
    p0 = [0.85 -1.5 0.5 0.75 1];

    k = Nmodes*2 + 1;

    opts.StartPoint = startpoint(1:k);
    opts.Lower = lb(1:k);
    opts.Upper = ub(1:k);

end