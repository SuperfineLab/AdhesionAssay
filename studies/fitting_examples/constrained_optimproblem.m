% fit with constraints
clear ps

Nmodes = 2;





force = cooh.Force;
errforce = diff(cooh.ForceInterval,[],2)/2;
factorLeft = cooh.PctLeft; 
weights = cooh.Weights;
logforce_nN = log10(force);
errbarlength  = log10(force + errforce)-log10(force);

fout = ba_setup_fit(Nmodes, weights);


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
