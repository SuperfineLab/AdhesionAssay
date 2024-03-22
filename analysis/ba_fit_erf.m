function f = ba_fit_erf(logforce, pct_left, weights, startpoint, Nmodes)
%
%
%
%
% NOTE: Starting points are tuned to the log10(force_in_nN). The units must
% match exactly in order for the fitting function to operate in an expected
% fashion within the number of MaxEvals set in the code.
% 

    if nargin < 5 || isempty(startpoint)
        % start with default starting locations on two-mode fit
%         startpoint = [0.825817697748955, ...   % a
%                       0.078175528753184, ...   % am
%                       0.442678269775446, ...   % as
%                       0.106652770180584, ...   % bm
%                       0.961898080855054 ];     % bs
    end

    if nargin < 3 || isempty(weights)
        weights = ones(numel(logforce), 1);
    end

    if nargin < 2 || isempty(pct_left) || isempty(logforce)
        error('Input data for either logforce and/or pct_left not provided.');
    end
   

    [logforce, pct_left, weights] = prepareCurveData( logforce, pct_left, weights );
    
    f = fit_erf_model(logforce, pct_left, Nmodes, weights, startpoint(1,:));

end


function outs = fit_erf_model(logforce, pct_left, Nmodes, weights, startpoint)

    opts = setup_fitoptions(weights, Nmodes, startpoint);
    
    f{1} = '1/2*(a*erfc(((Fd)-am)/(sqrt(2)*as)))';
    f{2} = '1/2*(a*erfc(((Fd)-am)/(sqrt(2)*as))+(1-a)*erfc(((Fd)-bm)/(sqrt(2)*bs)))';

    outs = table('Size', [1 4], ...
                 'VariableNames', {'Nmodes', 'FitObject', 'GoodnessOfFit', 'FitOptions'}, ...
                 'VariableTypes', {'double', 'cell', 'struct', 'struct'});

    outs.Nmodes = Nmodes;
    outs.FitOptions = opts;

    NecessaryPointsN = (Nmodes*2 + 1) + 1;
    ft = fittype( f{Nmodes}, 'independent', 'Fd', 'dependent', 'y' );

    if numel(logforce) > NecessaryPointsN
        [fitresult, gof] = fit( logforce, pct_left, ft, opts );

        outs.FitObject = {fitresult};
        outs.GoodnessOfFit = gof;
    
    else
        logentry('Not enough points to fit this model. Returning NaN.')
    
        outs.FitObject = {};
        outs.GoodnessOfFit = [];
        
    end

%     outs = table(Nmodes, {fitresult}, gof, opts, ...
%                  'VariableNames', {'Nmodes', 'FitObject', 'GoodnessOfFit', 'FitOptions'});

end



function opts = setup_fitoptions(weights, Nmodes, startpoint)

    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );

    opts.Display = 'Off';
    opts.MaxFunEvals = 26000;
    opts.MaxIter = 24000;
    opts.Weights = weights;
    opts.TolFun = 1e-07;
    opts.TolX = 1e-07;
    opts.DiffMinChange = 1e-08;
    opts.DiffMaxChange = 0.01;

    % Lower and upper bounds for each parameter
    %    [a  am   as   bm   bs ]
    lb = [0 -Inf  0   -Inf  0  ];
    ub = [1  Inf  Inf  Inf  Inf];
    
    % Default starting points if none are available
    % p0 = [0.82582 0.07818 0.44268 0.10666 0.96190];
    p0 = [0.85 -1.5 0.5 0.75 1];

    k = Nmodes*2 + 1;

    opts.StartPoint = startpoint(1:k);
    opts.Lower = lb(1:k);
    opts.Upper = ub(1:k);

end
