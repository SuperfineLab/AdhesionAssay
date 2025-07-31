function [StatOutT, BootstatT] = ba_bootstrap_fit(logforce_nN, fractionLeft, weights, fout, opts)
% BA_BOOTSTRAP_FIT  use fits on force-curve subsets to get confidence intervals
%
% [StatOutT, BootstatT] = ba_bootstrap_fit(logforce_nN, fractionLeft, weights, fout, opts)
%
% Outputs: StatOutT reports the aggregate statistic for the bootstrap run
%          BootstatT contains the individual fitting runs for further analysis
%
% Inputs:  logforce_nN is the base-10 log of the force in nanoNewtons
%          fractionLeft is the fraction of beads left on the substrate
%          weights is the reported weight given the uncertainty in the force
%          fout is the AdhesionAssay fitting structure (from ba_setup_fit)
%          opts is the fitting algorithm options structure (from ba_fit_options)
%


    % Hacking the "curve-fitting toolbox" version of the equation here and
    % then merging the parameter list into a more universal expression for
    % later computational analysis downstream.

    switch fout.Nmodes
        case 1
            fiteq = '1/2*(erfc(((Fd)-am)/(sqrt(2)*as)))';
            usethese = [2 3];
        case 2
            fiteq = '1/2*(a*erfc(((Fd)-am)/(sqrt(2)*as))+(1-a)*erfc(((Fd)-bm)/(sqrt(2)*bs)))';
            usethese = [1 2 3 5 6];
    end
    ft = fittype( fiteq, 'independent', 'Fd', 'dependent', 'y' );
    
    Nparams = fout.Nparams;

    opts.Weights = weights;
    opts.Lower = fout.lb(usethese);
    opts.Upper = fout.ub(usethese);
    opts.StartPoint = fout.StartPoint(usethese);

    Nboot = 200;
    tic
    [bci, bootstat] = bootci(Nboot, {@(x,y)ba_bootstat_fun(x,y,ft,opts), logforce_nN, fractionLeft}, 'Type', 'percentile'); %, 'Options', s);        
    toc

    Nb = size(bootstat,1);
    qtmp = mat2cell(bootstat, Nb, [Nparams ones(1,12)]);

    BootstatT = table(qtmp{:}, ...
                'VariableNames', { 'FitParams', ...
                                   'sse', 'rsquare', 'dfe', 'adjrsquare', 'rmse', ...
                                   'redchisq', ...
                                   'numobs', 'numparam', 'exitflag', 'iterations', 'funcCount', 'stepsize'});
    
    % To convert the FitParams into a cell array of 1xNparams for each fit...
    tmp = arrayfun(@(x)BootstatT.FitParams(x,:), (1:height(BootstatT))', 'UniformOutput', false);

    BootstatT.FitParams = tmp;

    StatOutT = table('Size', [1 9], ...
                     'VariableTypes', ["cell", "cell", repmat("double",1,7)], ...
                     'VariableNames', ["p", "pconf", "sse", "rsquare", "adjrsquare", "dfe", "rmse", "redchisq", "sumrelwidth"]);

    outp = median(bootstat(:,1:Nparams),1,'omitnan');
    outpconf = bci(:,1:Nparams);
    % XXX @jeremy TODO: Fix the outputs starting from sse and ending with
    % redchisq because right now they are reporting the median of
    % everything outputted from the Bootstat table, which is mathetically
    % nonsensical. Instead, use the median parameters to compute the difference 
    % between data and fout.fiteq(data) and derive further values from there.    
    StatOutT.p{1} = outp;
    StatOutT.pconf{1} = outpconf;
    StatOutT.sse = median(bootstat(:,Nparams+1),1,'omitnan');
    StatOutT.rsquare = median(bootstat(:,Nparams+2),1,'omitnan');
    StatOutT.dfe = median(bootstat(:,Nparams+3),1,'omitnan');
    StatOutT.adjrsquare = median(bootstat(:,Nparams+4),1,'omitnan');
    StatOutT.rmse = median(bootstat(:,Nparams+5),1,'omitnan');
    StatOutT.redchisq = median(bootstat(:,Nparams+6), 1, 'omitnan');
    StatOutT.sumrelwidth = sum(ba_relwidthCI(outp, outpconf),"all");

end


function pge = ba_bootstat_fun(logforce_nN, fractionLeft, ftfcn, myopts)
% ba_bootstat_fun dictates the procedure used on the data chosen by
% matlab's bootstrp and bootci functions. Herein lies the fitting for
% individual subsets and the reporting of those fitting results. Matlab
% runs whatever number of these selected by the user. Included here is the
% computation for the reduced chi-square statistic. 
%

    % Ensure the dataset is ordered based on increasing force.
    [logforce_nN, idx] = sort(logforce_nN);
    fractionLeft = fractionLeft(idx,:);

    % Perform the fit and extract the best fitting parameters for each
    [fitresult, gof, xtra] = fit( logforce_nN, fractionLeft, ftfcn, myopts );
    ptmp = coeffvalues(fitresult);

    %
    % Weighted reduced chi-square computation https://en.wikipedia.org/wiki/Reduced_chi-squared_statistic
    % XXX @jeremy TODO: Another function in the AdhesionAssay codebase also does 
    % the reduced chi-square computation. Should we use it here instead? If
    % we do, then our redchisquare will need to change such that its inputs
    % require the already calculated residuals (to avoid weird differences
    % between fit objects for "fit" versus anonymous fitting functions used
    % everywhere else.
    r = xtra.residuals; 
    W = diag(myopts.Weights);
    dfe = numel(logforce_nN) - numel(ptmp);
    redchisq = r' * W * r / dfe;

    switch numel(ptmp)
        case 2  
            % The one mode, constrained, i.e., ModeScale = 1
            p(1,:) = [1 ptmp];
        case 3
            % The one mode, unconstrained, results should just report what it sees.
            p(1,:) = ptmp;
        case 5
            % This two mode model is constrained by definition (because of 
            % limitations of Matlab's Curve-Fitting Toolbox, but that doesn't
            % mean that we cannot wrap the old-style TWO-MODE ONLY parameters into 
            % the new-style parameter vector, i.e. [a am as b bm bs]. This will
            % allow for more integrated analysis later in the toolchain if and when
            % we choose to revisit multiple modes beyond Nmodes=2
            p(1,:) = [ptmp(1:3), 1-ptmp(1), ptmp(4:5)];
        
            % Reorganize the modes so that the smallest one goes first. Perhaps
            % this should be changed to be something else, but I don't know what
            % yet.
            idx = p(:,2) >= p(:,5);
            p(idx,1:6) = [p(idx,4:6), p(idx,1:3)];
        otherwise
            error('Not implemented for more than 2 modes at this time.');
    end


    % Setting up the outputs...

    % %     % This doesn't work. Table output isn't defined, maybe?
    % %     p = table(p, 'VariableNames', {'FitParam'});
    % %     g = struct2table(gof);
    % %     xtra = struct2table(xtra_output, 'AsArray', true);
    
    % %     % This also doesn't work. Still complains about an isfinite error
    % %     g(1,:) = struct2cell(gof);
    % %     extra(1,:) = struct2cell(xtra);
    % %     pout = horzcat(p, g, extra);

    % We'll just list them out. Looks gross, but it works.
    g(1,:) = [gof.sse gof.rsquare gof.dfe gof.adjrsquare gof.rmse];
    e(1,:) = [xtra.numobs, xtra.numparam, xtra.exitflag, xtra.iterations, xtra.funcCount, xtra.stepsize];

    pge(1,:) = horzcat(p, g, redchisq, e);
end