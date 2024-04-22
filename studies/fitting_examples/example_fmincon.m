% [x,resnorm,residual,exitflag,output,lambda,jacobian] = lsqnonlin(___)
% [x,resnorm,residual,exitflag,output,lambda,jacobian] = lsqcurvefit(___)
% [x,fval,exitflag,output,population,scores] = ga(___)




% data
logForce = [-1.466,-1.372,-1.358,-1.350,-1.339,-1.327,-1.313,-1.307,-1.295,-1.288,-1.284,-1.276,-1.267,-1.263,-1.248,-1.228,-1.202,-1.194,-1.183,-1.166,-1.164,-1.159,-1.149,-1.140,-1.129,-1.124,-1.108,-1.102,-1.097,-1.093,-1.091,-1.085,-1.072,-1.057,-1.040,-1.019,-1.006,-0.997,-0.975,-0.958,-0.880,-0.845,-0.796,-0.738,-0.696,-0.625,-0.572,-0.528,-0.482];
logForce_weights = [1.000,0.409,0.706,0.168,0.623,0.759,0.194,0.327,0.200,0.309,0.245,1.000,1.000,0.177,0.245,0.307,0.200,0.196,0.219,1.000,0.076,0.342,0.205,0.252,0.157,0.422,0.011,0.162,0.117,0.408,0.016,0.198,0.084,0.031,0.632,0.093,0.432,0.355,0.012,0.057,0.104,0.003,0.147,0.026,0.113,0.003,0.005,0.002,0.007];
fractionLeft = [0.995,0.981,0.967,0.953,0.938,0.924,0.910,0.896,0.882,0.867,0.853,0.839,0.825,0.810,0.796,0.782,0.768,0.754,0.739,0.725,0.711,0.697,0.682,0.668,0.654,0.640,0.626,0.611,0.597,0.583,0.569,0.555,0.540,0.526,0.512,0.498,0.483,0.469,0.455,0.441,0.427,0.412,0.398,0.384,0.370,0.355,0.341,0.318,0.294];

% fit specs
% p = [a1 b1 c1 a2 b2 c2]; (parameter labels from equation)
fcn = @(p,Fd)(1/2*(p(1)*erfc((Fd-p(2))/(sqrt(2)*p(3)))+p(4)*erfc((Fd-p(5))/(sqrt(2)*p(6)))));
ps = [0.5 -1.5 0.5 0.5 -0.33 0.5];  % starting guess for parameters
lb = [0 -Inf   0   0  -Inf    0];  % lower bounds
ub = [1  Inf Inf   1   Inf  Inf];  % upper bounds
Aeq = [1 0 0 1 0 0]; % constraint (with beq)
beq = 1; 

% execute fit
opts = optimoptions('fmincon');
problem = createOptimProblem('fmincon', 'x0', ps, ...
          'objective',@(p) cost_func(p, fcn, logForce, fractionLeft, logForce_weights), ...
          'lb', lb, 'ub', ub, 'Aineq', Aeq, 'bineq', beq, 'options', opts);
[pfit,fval,exitflag,output] = fmincon(problem);

% plot output
figure; 
plot(logForce, fractionLeft, '.', logForce, fcn(pfit,logForce), '-');
xlabel('logForce'); ylabel('fractionLeft'); legend('data', 'fit');

% optimization error-cost function
function fiterr = cost_func(p, fcn, x, y, w)
    prediction = fcn(p, x);
    wt_err = w .* (prediction - y).^2;
    fiterr = sum(wt_err);
end
