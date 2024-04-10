% fit with constraints
clear ps

Nmodes = 2;
Nparams = 3*Nmodes;

logforcelimitHigh = 2;
logforcelimitLow = -1.5;

logforcerange = abs(logforcelimitHigh - logforcelimitLow);
logforcestep = logforcerange / (Nmodes+1);

lb1 = [0       ,             -Inf               , 0  ];
ub1 = [1       ,              Inf               , Inf];
p0 =  [1/Nmodes, logforcelimitLow+0*logforcestep, 0.5; ...
       1/Nmodes, logforcelimitLow+1*logforcestep, 0.5; ...
       1/Nmodes, logforcelimitLow+2*logforcestep, 0.5];

% p0 = [0.5 -1.25 0.15; 0.2 -0.75 0.25; 0.2 0.3 1.1];

lb = repmat(lb1, 1, Nmodes);
ub = repmat(ub1, 1, Nmodes);

ps(1,:) = reshape(transpose(p0),1,[]);
ps = ps(1:3*Nmodes);

Aeq = repmat([1 0 0], 1, Nmodes);
beq = 1;

force = cooh.Force;
errforce = diff(cooh.ForceInterval,[],2)/2;
factorLeft = cooh.PctLeft; 
weights = cooh.Weights;

logforce_nN = log10(force);
errbarlength  = log10(force + errforce)-log10(force);

f = 200 + Nmodes;

figure(f); 
clf
hold on
plot(logforce_nN, factorLeft, 'b.');
e = errorbar( gca, logforce_nN, factorLeft, errbarlength, 'horizontal', '.', 'CapSize',2);
e.LineStyle = 'none';
e.Color = 'b';




opts = optimoptions(@fmincon,'Algorithm','interior-point', 'UseParallel', true);

objectiveFcn = @(params) objectiveFunction(params, logforce_nN, factorLeft, weights);

problem = createOptimProblem('fmincon', 'x0', ps, ...
          'objective',@(p) objectiveFunction(p, fitfcnNew{Nmodes}, logforce_nN, factorLeft, weights), ...
          'lb', lb, 'ub', ub, 'Aineq', Aeq, 'bineq', beq, 'options', opts)

[x,fval,exitflag,output] = fmincon(problem);

plot(logforce_nN, fitfcnNew{Nmodes}(output.bestfeasible.x,logforce_nN), 'k--');


function error = objectiveFunction(params, fitfcn, logforce_nN, factorLeft, weights)
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
