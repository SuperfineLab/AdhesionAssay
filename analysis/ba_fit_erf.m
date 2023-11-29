function [fitresult, gof] = ba_fit_erf(logforce, pct_left, weights, Nterms, plotTF)

    if nargin < 5 || isempty(plotTF)
        plotTF = false;
    end

    if nargin < 4 || isempty(Nterms)
        Nterms = 2;
    end

    % log transform the force
%     logforce = log10(force);
    [logforce, pct_left, weights] = prepareCurveData( logforce, pct_left, weights );
    
%     [tmpa,tmpb] = get_good_startpoint(logforce, pct_left, weights);
                    
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
    

    % Fit model to data.
    [fitresult, gof] = fit( logforce, pct_left, ft, opts );

    if plotTF
        % Plot fit with data.
        figure( 'Name', 'erf fit' );
        h = plot( fitresult, logforce, pct_left, 'predobs' );
        legend( h, 'y vs. x with w', 'hbe', 'Lower bounds (hbe)', 'Upper bounds (hbe)', 'Location', 'NorthEast', 'Interpreter', 'none' );
        % Label axes
        xlabel( 'log(force [nN])', 'Interpreter', 'none' );
        ylabel( 'Fraction Left', 'Interpreter', 'none' );
        grid on

        errlength = log10(10.^logforce + 1./weights);
        e = errorbar( gca, logforce, pct_left, errlength, 'horizontal');
        e.LineStyle = 'none';
        e.Color = 'b';

    end

end