function T = ba_fit_erf(logforce_nN, fractionLeft, weights, startpoint, Nmodes, fitmethod)
% XXX @jeremy TODO: Add documentation text
%
 
%
%
% NOTE: Starting points are tuned to the log10(force_in_nN). The units must
% match exactly in order for the fitting function to operate in an expected
% fashion within the number of MaxEvals set in the code.
% 


persistent Nrun

if isempty(Nrun)
    Nrun = 1;
else
    Nrun = Nrun + 1;
end

disp(['Nrun = ', num2str(Nrun)]);

    if size(startpoint,1) > 1
        startpoint = startpoint(1,:);
    end

    if iscell(startpoint)
        startpoint = cell2mat(startpoint);
    end

    if nargin < 3 || isempty(weights)
        weights = ones(numel(logforce_nN), 1);
    end

    if nargin < 2 || isempty(fractionLeft) || isempty(logforce_nN)
        error('Input data for either logforce and/or pct_left not provided.');
    end   

    [logforce_nN, fractionLeft, weights] = prepareCurveData( logforce_nN, fractionLeft, weights );
    
    T = table('Size', [1 10], ...
                 'VariableNames', {'FitParams', 'confFitParams', 'rsquare', 'adjrsquare', 'dfe', 'sse', 'rmse', 'FitSetup', 'FitOptions', 'BootstatT'}, ...
                 'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'double', 'double', 'struct', 'struct', 'double'});
    
    AvailModes = numel(startpoint)/3;
    fout = ba_fit_setup(AvailModes);
    fout.StartPoint = startpoint;

    opts = ba_fitoptions(fitmethod);
    
    NecessaryPointsN = fout.Nparams + 1;

    if numel(logforce_nN) > NecessaryPointsN

        switch fitmethod
            case 'fit'
                if AvailModes == 2
                    fout.fcn = @(p,Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3)))+(1-p(1))*erfc(((Fd)-p(5))/(sqrt(2)*p(6)))));
                end
                [result, BootstatT] = ba_bootstrap_fit(logforce_nN, fractionLeft, weights, fout, opts);
            case {'lsqcurvefit', 'lsqnonlin', 'fminunc'}
                result = use_unconstrained_method(logforce_nN, fractionLeft, weights, fout, opts, fitmethod);
                BootstatT = {[]};
            case {'fmincon'}
                result = use_constrained_method(logforce_nN, fractionLeft, weights, fout, opts, fitmethod);
                BootstatT = {[]};
            otherwise
                error('Fit method not implemented.');
        end
    
    else
        logentry('Not enough points to fit this model. Empty results.');  
        T.FitParams = {NaN(1,6)};
        T.confFitParams = {NaN(2,6)};
        T.rsquare = NaN; 
        T.adjrsquare = NaN;        
        T.dfe = NaN;
        T.sse = NaN;
        T.rmse = NaN;
        T.redchisq = NaN;
        T.FitSetup = fout;
        T.FitOptions = opts;
        T.BootstatT = {[]};
        return
%         TableOut.FitObject = {''};
%         TableOut.GoodnessOfFit = struct('sse', NaN, 'rsquare', NaN, 'dfe', NaN, 'adjrsquare', NaN, 'rmse', NaN);

    end
%     from gof: sse, rsquare, dfe, adjrsquare, rmse,
%     from xtra: numobs, numparam, exitflag, iterations, funcCount, stepsize



    T.FitParams = {result.p};
    T.confFitParams = {result.pconf};
    T.rsquare = result.rsquare; 
    T.adjrsquare = result.adjrsquare;
    T.dfe  = result.dfe;
    T.sse  = result.sse;
    T.rmse = result.rmse;
    T.redchisq = result.redchisq;
    T.FitSetup = fout;
    T.FitOptions = opts;
    T.BootstatT = {BootstatT};
end



function outs = use_old_fit_method(logforce_nN, fractionLeft, weights, fout, opts)
    % Hacking the "curve-fitting toolbox" version of the equation here and
    % then merging the parameter list into a more universal expression for
    % later computational analysis downstream.

    fiteq1 = '1/2*(erfc(((Fd)-am)/(sqrt(2)*as)))';
    ft1 = fittype( fiteq1, 'independent', 'Fd', 'dependent', 'y' );

    options1 = opts;
    options1.Normalize = 'On';    
    options1.Weights = weights;
    options1.Lower = fout.lb([2 3]);
    options1.Upper = fout.ub([2 3]);
    options1.StartPoint = fout.StartPoint([2 3]);
    options1.Robust = 'On';

    [fitresult1, gof1] = fit( logforce_nN, fractionLeft, ft1, options1 );

    fiteq2 = '1/2*(a*erfc(((Fd)-am)/(sqrt(2)*as))+(1-a)*erfc(((Fd)-bm)/(sqrt(2)*bs)))';
    ft2 = fittype( fiteq2, 'independent', 'Fd', 'dependent', 'y' );

    options2 = opts;
    options2.Normalize = 'On';
    options2.Weights = weights;
    options2.Lower = fout.lb([1 2 3 5 6]);
    options2.Upper = fout.ub([1 2 3 5 6]);
    options2.StartPoint = fout.StartPoint([1 2 3 5 6]);
    options2.Robust = 'On';
    
    [fitresult2, gof2] = fit( logforce_nN, fractionLeft, ft2, options2 );

    p1= coeffvalues(fitresult1);
    pconf1 = confint(fitresult1);

    p2 = coeffvalues(fitresult2);
    pconf2 = confint(fitresult2);

    pause(0.1);
%     if any(isnan(pconf))
%         opts.Lower = fout.lb([2 3]);
%         opts.Upper = fout.ub([2 3]);
%         opts.StartPoint = fout.StartPoint([2 3]);
% 
%         [fitresult, gof] = fit( logforce_nN, fractionLeft, ft{1}, opts );
%         p = coeffvalues(fitresult);
%         pconf = confint(fitresult);
%     end

    % This two mode model is constrained by definition, but that doesn't
    % mean that we cannot wrap the old-style TWO-MODE ONLY parameters into 
    % the new-style parameter vector, i.e. [a am as b bm bs]. This will
    % allow for more integrated analysis later in the toolchain if and when
    % we choose to revisit multiple modes beyond Nmodes=2
    p4 = 1-p(1);
    confp4 = flipud(1-pconf(:,1));

    outs.p = [p(1:3) p4 p(4:5)];
    outs.pconf = [pconf(:,1:3) confp4 pconf(:,4:5)];
    outs.sse = gof.sse;
    outs.rsquare = gof.rsquare;
    outs.dfe = gof.dfe;
    outs.adjrsquare = gof.adjrsquare;
    outs.rmse = gof.rmse;
    
end


function outs = use_constrained_method(logforce_nN, fractionLeft, weights, fout, opts, fitmethod)

    % constrained
    opts.Display = 'off';

    objective = @(p)objective_sse(p, logforce_nN, fractionLeft, weights, fout.fcn);
    problem = createOptimProblem(fitmethod,'x0',fout.StartPoint,'objective',objective,...
                                 'lb', fout.lb,'ub', fout.ub, ...
                                 'Aineq', fout.Aineq, 'bineq', fout.bineq, ...
                                 'xdata',logforce_nN,'ydata',fractionLeft, ...
                                 options=opts);


%     problem = createOptimProblem(fitmethod,'x0',fout.StartPoint,'objective',objective,...
%         'lb',fout.lb,'ub',fout.ub,'xdata',logforce_nN,'ydata',fractionLeft, options=opts);

    ms = MultiStart("Display","off");
    [x,fval,exitflag,output] = run(ms,problem,200);

    outs = fitstats(logforce_nN, fractionLeft, fout.fcn(x,fractionLeft), x, fval);

end


function outs = use_unconstrained_method(logforce_nN, fractionLeft, weights, fout, opts, fitmethod)

    % unconstrained (no Aeq, beq, Aineq, or bineq)
    opts.Display = 'off';
    problem = createOptimProblem(fitmethod,'x0',fout.StartPoint,'objective',fout.fcn,...
                                 'lb', fout.lb,'ub', fout.ub, ...
                                 'xdata',logforce_nN,'ydata',fractionLeft, ...
                                 options=opts);

%     objective = @(p,fractionLeft) sqrt(weights) .* (fout.fcn(p,fractionLeft)-fractionLeft);
%     problem = createOptimProblem(fitmethod,'x0',fout.StartPoint,'objective',objective,...
%         'lb',fout.lb,'ub',fout.ub,'xdata',logforce_nN,'ydata',fractionLeft, options=opts);

    ms = MultiStart("Display","off");
    [p,fval,exitflag,output] = run(ms,problem,200);

    outs = fitstats(logforce_nN, fractionLeft, fout.fcn(p,logforce_nN), p, fval);
   
end


function sum_square_error = objective_sse(params, logforce_nN, fractionLeft, weights, fitfcn)
    % params: Parameters to be optimized, [a am as bm bs]
    % logforce_nN: detachment force in nN
    % fractionLeft: fraction of beads still attached
    % weights: Weight values for each DETACHMENT FORCE


    % Calculate model predictions using params and xdata
    predicted_fractionLeft = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    weighted_errors = weights .* (predicted_fractionLeft - fractionLeft).^2;
    sum_square_error = sum(weighted_errors);
end

function outs = fitstats(xdata, ydata, yfit, params, sse)
% A fair amount of the code below was lifted and modified from mathworks' 
% "fit" function, namely the "goodnessofFit" structure.
%
% Other references used for computing rsquare and adjrsquare
% https://www.mathworks.com/matlabcentral/answers/521423-how-can-calculate-r-square-using-lsqcurvefit    
% https://en.wikipedia.org/wiki/Coefficient_of_determination
    
    residuals = ydata - yfit;
%     SStot = sum((sample_y-mean_y).^2); % total sum of squares
%     SSres = sum(residuals.^2); % residual sum of squares
%     rsquare = 1-SSres/SStot;

    Ns = numel(xdata); % number of samples
    Np = numel(params); % number of parameters   
    dft = Ns - 1; % degrees of freedom of est pop variance around the *mean*
    dfe = Ns - Np - 1; % degrees of freedom of est pop variance around *model*


    
    if isempty( weights )
        % If there are no weights, then they are assumed to be all ones.
        mean_y = mean( ydata );
        SStot = sum( (ydata - mean_y).^2 );
    else
        mean_y = sum(ydata.*weights)/sum(weights);
        SStot = sum(weights.*(ydata - mean_y).^2);
    end
    
    % Compute SSE if not given
    if nargin < 6
        sse = norm(residuals)^2;
    end
    
    % Compute R-squared, but avoid divide by zero warning
    if ~isequal(SStot,0)
        rsquare = 1 - sse/SStot;
    elseif isequal(SStot,0) && isequal( sse, 0 )
        rsquare = NaN;
    else % sst==0 && sse ~== 0
        % This is unusual, so try to determine if sse is just round-off error
        if sqrt(abs(sse))<sqrt(eps)*mean(abs(ydata))
            rsquare = NaN;
        else
            rsquare = -Inf;
        end
    end

    % Compute adjusted R-squared and RMSE
    if dfe > 0
        adjrsquare = 1-(1-rsquare)*(dft/dfe); 
        mse = sse/dfe;
        rmse = sqrt( mse );
    else
        dfe = 0;
        adjrsquare = NaN;
        rmse = NaN;
    end
    
    outs.p = reshape(params,1,[]);
    outs.pconf = NaN(2,numel(params)); % placeholder for confidence intervals
    outs.sse = sse;
    outs.rsquare = rsquare;
    outs.dfe = dfe;
    outs.adjrsquare = adjrsquare;
    outs.rmse = sqrt(mean(residuals.^2));
end




