function opts = ba_fitoptions(method)
% XXX @jeremy TODO: Write documentation
%  method: {fit}, fmincon, lsqcurvefit, lsqnonlin, ga, particleswarm, patternsearch

    if nargin < 1 || isempty(method)
        method = 'fit';
    end

    % Special case: when using the 'fit' function from the curve-fitting toolbox
    if strcmpi(method,'fit')
        opts = fitoptions('Method', 'NonlinearLeastSquares');
        opts.Normalize = 'Off';
        opts.Display = 'Off';
        opts.Algorithm = 'Trust-Region';
        opts.Robust = 'Off';
        opts.MaxFunEvals = 26000;
        opts.MaxIter = 24000;
        opts.TolFun = 1e-08;
        opts.TolX = 1e-08;
        opts.DiffMinChange = 1e-09;
        opts.DiffMaxChange = 0.001;
        return
    end


    % Otherwise, default OPTIMOPTIONS for other matlab fitting methods
    opts = optimoptions(method);

    switch method
        case 'fmincon' % "con" here refers to "constrained"
            % "trust-region-reflective" requires more info on the input or
            % limits the ability to use constraints AND bounds.
            opts.Algorithm = 'interior-point';
            opts.UseParallel = true;
        case 'lsqcurvefit'
            opts.Display = 'Off'; % Display='final';
        case 'lsqnonlin'
            opts.Display = 'Off'; % Display='final';
            opts.Algorithm = 'levenberg-marquardt';
            opts.MaxFunEvals = 26000;
            opts.MaxIter = 24000;
            opts.TolFun = 1e-07;
            opts.TolX = 1e-07;
            opts.DiffMinChange = 1e-08;
            opts.DiffMaxChange = 0.01;
        case 'ga'
            opts.MaxGenerations = 7000; % 6000;            
            opts.PopulationSize = 10;
            opts.FunctionTolerance = 1e-7;
            opts.MutationFcn = @mutationadaptfeasible;
            opts.ConstraintTolerance = 1e-4;
            opts.CrossoverFraction = 0.50;
            opts.HybridFcn = 'fmincon';
            opts.PlotFcn = {}; % {'gaplotscores','gaplotbestf'};
            opts.UseParallel = true;
        case 'particleswarm'
            opts.HybridFcn = "fmincon";
            opts.SwarmSize = 100;
            opts.UseParallel = true;
            opts.Display = 'Off'; % Display='final';
        case 'patternsearch'            
            opts.InitialMeshSize = 0.1;
            opts.StepTolerance = 1e-6;
            opts.MeshTolerance = 1e-6;
            opts.Algorithm = 'nups-mads';
            opts.Cache = "on";
            opts.PlotFcn = {'psplotbestlogf'};
            opts.UseParallel = true;
            opts.Display = 'Off'; % Display='final';
            
        otherwise
            error('Fitting method type undefined.');            
    end
end
