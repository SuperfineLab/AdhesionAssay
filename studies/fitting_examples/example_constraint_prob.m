% fit with constraints
clear ps

Nmodes = 2;

PlateID = 'ba_240125coohni';
cooh = Data.RawData(Data.PlateID == PlateID);
cooh = cooh{1};


logforce_nN = log10(cooh.Force);
logforceinterval = log10(cooh.ForceInterval);
fractionLeft = cooh.FractionLeft; 
weights = cooh.Weights;

fout = ba_fit_setup(Nmodes, weights);


gray = [0.5 0.5 0.5];

f = 200 + Nmodes;
figure(f); 
clf;
hold on
    plot( logforce_nN, fractionLeft, 'Color', gray, 'Marker', '.', 'LineStyle', 'none');
    plot( logforceinterval(:,1), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');
    plot( logforceinterval(:,2), fractionLeft, 'Color', gray+0.3, 'LineStyle', '-');      
hold off
xlabel('log_{10}(Force [nN])');
ylabel('Fraction left');
legend('data', 'fit');
title(join([string(PlateID) ', ' num2str(Nmodes) ' modes'], ''), 'Interpreter','none'); 
drawnow


opts = optimoptions(@fmincon,'Algorithm','interior-point', 'UseParallel', true);

objectiveFcn = @(params) objectiveFunction(params, logforce_nN, fractionLeft, weights);

problem = createOptimProblem('fmincon', 'x0', fout.StartPoint, ...
          'objective',@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
          'lb', fout.lb, 'ub', fout.ub, 'Aineq', fout.Aeq, 'bineq', fout.beq, 'options', opts)

[x,fval,exitflag,output] = fmincon(problem);

hold on
    plot(logforce_nN, fout.fcn(output.bestfeasible.x,logforce_nN), 'r--');
    drawnow
hold off


function error = objectiveFunction(params, fitfcn, logforce_nN, fractionLeft, weights)
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
