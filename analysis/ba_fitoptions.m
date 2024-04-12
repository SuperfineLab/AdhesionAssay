function opts = ba_fitoptions(method, weights, startpoint, lb, ub)
% OPTIMOPTIONS    

    opts = optimoptions(method);

    switch method
        case 'fmincon'
            opts.Algorithm = 'interior-point';
            opts.UseParallel = true;
        case 'lsqcurvefit'

        case 'lsqnonlin'
            opts.Display = 'Off';
            opts.MaxFunEvals = 26000;
            opts.MaxIter = 24000;
%             opts.Weights = weights;
            opts.TolFun = 1e-07;
            opts.TolX = 1e-07;
            opts.DiffMinChange = 1e-08;
            opts.DiffMaxChange = 0.01;
%             opts.StartPoint = startpoint;
%             opts.Lower = lb;
%             opts.Upper = ub;
        case 'ga'
            opts.MaxGenerations = 1500;
            opts.PopulationSize = pop_size;
            opts.FunctionTolerance = 1e-7;
            opts.PlotFcn = {'gaplotscores','gaplotbestf'};
            opts.UseParallel = true;
        case 'particleswarm'
            opts.HybridFcn = "fmincon";
            opts.SwarmSize = 100;
            opts.UseParallel = true;
            opts.Display = 'final';
        case 'patternsearch'            
            opts.StepTolerance = 1e-5;
            opts.MeshTolerance = 1e-5;
            opts.Algorithm = 'nups-mads';
            opts.Cache = "on";
            opts.PlotFcn = {'psplotbestf'};
            opts.UseParallel = true;
            opts.Display = 'final';
        otherwise
            error('Fitting method type undefined.');            
    end
end
