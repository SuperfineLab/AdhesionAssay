function myfit = ba_fit_erf(logforce, pct_left, weights, Nterms, startpoint)
%
%
%
%
% NOTE: Starting points are tuned to the log10(force_in_nN). The units must
% match exactly in order for the fitting function to operate in an expected
% fashion within the number of MaxEvals set in the code.
% 

    if nargin < 4 || isempty(Nterms)
        Nterms = 2;
    end

    [logforce, pct_left, weights] = prepareCurveData( logforce, pct_left, weights );
    
    % Set up fittype and options.
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );

    myfit = initialize_fit_output(Nterms);

    switch Nterms
        case 1
            ft = fittype( '1/2*(a*erfc(((Fd)-am)/(sqrt(2)*as)))', 'independent', 'Fd', 'dependent', 'y' );

            if nargin < 5 || isempty(startpoint)
                opts.StartPoint = [0.9 0.085 0.5];
            else
                opts.StartPoint = startpoint;
            end            
            %             a  am   as  
            opts.Lower = [0 -Inf  0  ];
            opts.Upper = [1  Inf  Inf];

            NecessaryPointsN = 4;
        case 2
            ft = fittype( '1/2*(a*erfc(((Fd)-am)/(sqrt(2)*as))+(1-a)*erfc(((Fd)-bm)/(sqrt(2)*bs)))', 'independent', 'Fd', 'dependent', 'y' );
            
            if nargin < 5 || isempty(startpoint)
                opts.StartPoint = [0.825816977489547 0.0781755287531837 0.442678269775446 0.106652770180584 0.961898080855054];
            else
                opts.StartPoint = startpoint;
            end

            %             a  am   as   bm   bs
            opts.Lower = [0 -Inf  0   -Inf  0  ];
            opts.Upper = [1  Inf  Inf  Inf  Inf];       

            NecessaryPointsN = 5;
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
    
    if numel(logforce) > NecessaryPointsN
        [fitresult, gof] = fit( logforce, pct_left, ft, opts );
        ci = confint(fitresult)';
    else
        logentry('Not enough points to fit this model. Returning NaN.')
        return
    end


    % Fit model to data.
    myfit.FitObject = fitresult;
    myfit.sse = gof.sse;
    myfit.rsquare = gof.rsquare;
    myfit.dfe = gof.dfe;
    myfit.adjrsquare = gof.adjrsquare;
    myfit.rmse = gof.rmse;
    myfit.a = fitresult.a;
    myfit.aconf = ci(1,:);
    myfit.am = fitresult.am;
    myfit.amconf = ci(2,:);
    myfit.as = fitresult.as;
    myfit.asconf = ci(3,:);

    switch Nterms
        case 1
            myfit.bm = NaN;
            myfit.bmconf = [NaN NaN];
            myfit.bs = NaN;
            myfit.bsconf = [NaN NaN];
        case 2
            myfit.bm = fitresult.bm;
            myfit.bmconf = ci(4,:);
            myfit.bs = fitresult.bs;
            myfit.bsconf = ci(5,:);
    end

    myfit.Nterms = Nterms;

%    plotTF = true;
%    if plotTF
%        figh = ba_plot_fit(fitresult, 10.^logforce, [], pct_left);        
%    end
end


function InitFit = initialize_fit_output(Nterms)

    InitFit.FitObject = '';
    InitFit.sse = NaN;
    InitFit.rsquare = NaN;
    InitFit.dfe = NaN;
    InitFit.adjrsquare = NaN;
    InitFit.rmse = NaN;
    InitFit.a = NaN;
    InitFit.aconf = [NaN NaN];
    InitFit.a = NaN;
    InitFit.aconf = [NaN NaN];
    InitFit.am = NaN;
    InitFit.amconf = [NaN NaN];
    InitFit.as = NaN;
    InitFit.asconf = [NaN NaN];
    InitFit.bm = NaN;
    InitFit.bmconf = [NaN NaN];
    InitFit.bs = NaN;
    InitFit.bsconf = [NaN NaN];
    InitFit.Nterms = Nterms;

end
