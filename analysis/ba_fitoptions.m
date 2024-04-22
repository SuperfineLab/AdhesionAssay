function opts = ba_fitoptions(method)
% XXX @jeremy TODO: Write documentation
%  method: {fit}, fmincon, lsqcurvefit, lsqnonlin, ga, particleswarm, patternsearch

    if nargin < 1 || isempty(method)
        method = 'fit';
    end

    % Special case: when using the 'fit' function from the curve-fitting toolbox
    if strcmpi(method,'fit')
        opts = fitoptions;
        opts.Normalize = 'off';
        opts.Disply = 'off';
        opts.Algorithm = 'trust-region-reflective';
        opts.Robust = 'off';
        opts.MaxFunEvals = 26000;
        opts.MaxIter = 24000;
        opts.TolFun = 1e-07;
        opts.TolX = 1e-07;
        opts.DiffMinChange = 1e-08;
        opts.DiffMaxChange = 0.01;
        return
    end


    % Otherwise, default OPTIMOPTIONS for other matlab fitting methods
    opts = optimoptions(method);

    switch method
        case 'fmincon'
            opts.Algorithm = 'interior-point';
            opts.UseParallel = true;
        case 'lsqcurvefit'
            opts.Display = 'Off'; % Display='final';
        case 'lsqnonlin'
            opts.Display = 'Off'; % Display='final';
            opts.MaxFunEvals = 26000;
            opts.MaxIter = 24000;
            opts.TolFun = 1e-07;
            opts.TolX = 1e-07;
            opts.DiffMinChange = 1e-08;
            opts.DiffMaxChange = 0.01;
        case 'ga'
            opts.MaxGenerations = 1500;
            opts.PopulationSize = 10;
            opts.FunctionTolerance = 1e-7;
            opts.PlotFcn = {'gaplotscores','gaplotbestf'};
            opts.UseParallel = true;
        case 'particleswarm'
            opts.HybridFcn = "fmincon";
            opts.SwarmSize = 100;
            opts.UseParallel = true;
            opts.Display = 'Off'; % Display='final';
        case 'patternsearch'            
            opts.StepTolerance = 1e-5;
            opts.MeshTolerance = 1e-5;
            opts.Algorithm = 'nups-mads';
            opts.Cache = "on";
            opts.PlotFcn = {'psplotbestf'};
            opts.UseParallel = true;
            opts.Display = 'Off'; % Display='final';
        otherwise
            error('Fitting method type undefined.');            
    end
end
