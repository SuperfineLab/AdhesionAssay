function [fitresult, gof] = ba_fit_erf(logforce, pct_left, weights, Nterms)

    if nargin < 4 || isempty(Nterms)
        Nterms = 2;
    end

%     % log transform the force
%     logforce = log10(force);
    [logforce, pct_left, weights] = prepareCurveData( logforce, pct_left, weights );
    
    % Set up fittype and options.
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );

    switch Nterms
        case 1
            ft = fittype( '1/2*(a*erfc(((x)-am)/(sqrt(2)*as)))', 'independent', 'x', 'dependent', 'y' );
            opts.StartPoint = [0.9 0.085 0.5];
            %             a  am   as  
            opts.Lower = [0 -Inf  0  ];
            opts.Upper = [1  Inf  Inf];
        case 2
            ft = fittype( '1/2*(a*erfc(((x)-am)/(sqrt(2)*as))+(1-a)*erfc(((x)-bm)/(sqrt(2)*bs)))', 'independent', 'x', 'dependent', 'y' );
            opts.StartPoint = [0.825816977489547 0.0781755287531837 0.442678269775446 0.106652770180584 0.961898080855054];
            %             a  am   as   bm   bs
            opts.Lower = [0 -Inf  0   -Inf  0  ];
            opts.Upper = [1  Inf  Inf  Inf  Inf];       
        otherwise
            error('Unknown number of terms. Select "1" or "2" terms.');
    end

    opts.Display = 'Off';
    opts.MaxFunEvals = 26000;
    opts.MaxIter = 24000;
    opts.Weights = weights;
    opts.TolFun = 1e-07;
    opts.TolX = 1e-07;
    opts.DiffMinChange = 1e-08;
    opts.DiffMaxChange = 0.01;
    
    % Fit model to data.
    try
        [fitresult, gof] = fit( logforce, pct_left, ft, opts );

        ci = confint(fitresult)';
    %     fr{k,1} = fitresult;
    %     gofout(k,1) = gof;
        outs.a = fitresult.a;
        outs.aconf = ci(1,:);
        outs.am = fitresult.am;
        outs.amconf = ci(2,:);
        outs.as = fitresult.as;
        outs.asconf = ci(3,:);
        outs.bm = fitresult.bm;
        outs.bmconf = ci(4,:);
        outs.bs = fitresult.bs;
        outs.bsconf = ci(5,:);
    catch
        fr = '';
        gofout.sse = NaN;
        gofout.rsquare = NaN;
        gofout.dfe = NaN;
        gofout.adjrsquare = NaN;
        gofout.rmse = NaN;
        outs.a = NaN;
        outs.aconf = [NaN NaN];
        outs.a = NaN;
        outs.aconf = [NaN NaN];
        outs.am = NaN;
        outs.amconf = [NaN NaN];
        outs.as = NaN;
        outs.asconf = [NaN NaN];
        outs.bm = NaN;
        outs.bmconf = [NaN NaN];
        outs.bs = NaN;
        outs.bsconf = [NaN NaN];
    end
end