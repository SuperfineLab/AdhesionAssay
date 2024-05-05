Nboot = 200;


fout = ba_fit_setup(2);
opts = ba_fitoptions('fit');

fiteq = '1/2*(a*erfc(((Fd)-am)/(sqrt(2)*as))+(1-a)*erfc(((Fd)-bm)/(sqrt(2)*bs)))';
ft = fittype( fiteq2, 'independent', 'Fd', 'dependent', 'y' );

opts.StartPoint = fout.StartPoint([1 2 3 5 6]);
opts.Upper = fout.ub([1 2 3 5 6]);
opts.Lower = fout.lb([1 2 3 5 6]);
opts.Weights = weights;

s = statset('UseParallel',true);

tic 
[bootstat, bootsam] = bootstrp(Nboot, @(x,y)mybootfun(x,y,ft,opts), logforce_nN, fractionLeft);
[bci, bootstatci] = bootci(Nboot, {@(x,y)mybootfun(x,y,ft,opts), logforce_nN, fractionLeft}, 'Type', 'percentile'); %, 'Options', s);
toc

% b = [bootstat(:,1:3); bootstat(:,4:6)];


function pg = mybootfun(logforce_nN, fractionLeft, ft, myopts)
    [logforce_nN, idx] = sort(logforce_nN);
    fractionLeft = fractionLeft(idx,:);

    [fitresult, gof] = fit( logforce_nN, fractionLeft, ft, myopts );
    p = coeffvalues(fitresult);

    p = [p(1:3) 1-p(1) p(4:5)];

    idx = p(:,2) >= p(:,5);
    p(idx,1:6) = [p(idx,4:6), p(idx,1:3)];

    g = [gof.sse gof.rsquare gof.dfe gof.adjrsquare gof.rmse];
    pg(1,:) = [p g];
end


% parameter_estimates = bootstrp(num_bootstraps, @(bootstrap_sample) fit(model, bootstrap_sample).Parameters, length(data), ...
% 'Options', statset('UseParallel',true), 'type','parametric', ...
% 'Options', statset('UseParallel',true));