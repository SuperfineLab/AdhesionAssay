function fout = ba_setup_fit(fitname, weights, Nmodes, startpoint)
% XXX @jeremy TODO: Write documentation
%
    if nargin < 1 || isempty(fitname)
        fitname = 'erf-new';
    end

%
% XXX @jeremy TODO: strip out all of this "old-erf" modeling stuff. This
% requires setting up the goodness of fit metrics for an lsqcurvefit (or
% nlinlsqcurve fit with constraints on input parameters a, b, c, etc
%
    % new form
    [fitfcn, Nparams] = ba_fitfcn(fitname, Nmodes);

    switch lower(fitname)
        case 'erf-old'
            switch Nmodes
                case 1
                    lb = [0, -Inf, 0];
                    ub = [1,  Inf, Inf];
                case 2
                    lb = [0, -Inf,   0, -Inf, 0];
                    ub = [1,  Inf, Inf,  Inf, Inf];
            end

        case 'erf-new'
            % Upper and Lower bounds for *ONE MODE* parameter fitting
            %     [a,   am,  as]
            lb1 = [0, -Inf,   0];
            ub1 = [1,  Inf, Inf];
            
            % Tile out bounds according to how many modes in the fit
            lb = repmat(lb1, 1, Nmodes);
            ub = repmat(ub1, 1, Nmodes);
    end


    %
    % Handling startpoints
    %

    % **OLD** default starting points and bounds-setting if none are available    
    if strcmpi(fitname, 'erf-old') && (nargin < 4 || isempty(startpoint))
        logentry('Using predefined startpoint for old erfmode fits.')
        switch Nmodes
            case 1
                pstart = [0.82582 0.07818 0.44268];
            case 2
                pstart = [0.82582 0.07818 0.44268 0.10666 0.96190];
            otherwise
                error('Old erf fit equation not defined for Nmodes>2.')
        end

    elseif nargin < 4 || isempty(startpoint) || numel(startpoint) ~= Nparams
        % Handle (i.e., guess) the starting locations for parameters according 
        % to the number of modes and equally spaced from low-high limits,
        % which are assumed to be between 10^-1.5 and 10^2 nanoNewtowns.
        logforcelimitLow = -1.5;
        logforcelimitHigh = 2;
        logforcerange = abs(logforcelimitHigh - logforcelimitLow);
        logforcestep = logforcerange / (Nmodes+1);
    
        p0 =  [1/Nmodes, logforcelimitLow+0*logforcestep, 0.5; ...
               1/Nmodes, logforcelimitLow+1*logforcestep, 0.5; ...
               1/Nmodes, logforcelimitLow+2*logforcestep, 0.5];
    
        % Spin out starting locations according to number of modes
        pstart(1,:) = reshape(transpose(p0),1,[]);
        pstart = pstart(1:Nparams);
        
    else
        pstart = startpoint;
    end

    % limit constraints (if necessary)
    Aeq = repmat([1 0 0], 1, Nmodes);
    beq = 1;

    % Assemble default options structure 
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.MaxFunEvals = 26000;
    opts.MaxIter = 24000;
    opts.Weights = weights;
    opts.TolFun = 1e-07;
    opts.TolX = 1e-07;
    opts.DiffMinChange = 1e-08;
    opts.DiffMaxChange = 0.01;
    opts.StartPoint = pstart;
    opts.Lower = lb;
    opts.Upper = ub;

    fout.fitname = fitname;
    fout.fcn = fitfcn;    
    fout.Nmodes = Nmodes;
    fout.Nparams = Nparams;
    fout.opts = opts;
%     fout.logforcelimitHigh = logforcelimitHigh;
%     fout.logforcelimitLow = logforcelimitLow;
    fout.StartPoint = pstart;
    fout.lb = lb;
    fout.ub = ub;

    fout.Aeq = Aeq;
    fout.beq = beq;
end


function varargout = ba_fitfcn(fitname, Nmodes)

    % old form
    fitfcn{1} = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3)))));
    fitfcn{2} = @(p, Fd)(1/2*(  p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3))) + ...
                             (1-p(1))*erfc(((Fd)-p(4))/(sqrt(2)*p(5)))));

    % new form
    fitfcnNew{1} = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3)))));
    fitfcnNew{2} = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3))) + ...
                                 p(4)*erfc(((Fd)-p(5))/(sqrt(2)*p(6))))); 
    fitfcnNew{3} = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3))) + ...
                                 p(4)*erfc(((Fd)-p(5))/(sqrt(2)*p(6))) + ...
                                 p(7)*erfc(((Fd)-p(8))/(sqrt(2)*p(9))))); 

    switch fitname
        case "erf-old"
            if Nmodes > 2
                warning('This model not defined for more than 2 modes. Resetting to two modes.');
                Nmodes = 2;
            end
            fiteq = fitfcn{Nmodes};
            Nparams = 2*Nmodes + 1;
        case "erf-new"
            fiteq = fitfcnNew{Nmodes};
            Nparams = 3*Nmodes;
        otherwise
            error('Fit type not defined.');           
    end


    switch nargout
        case 1
            varargout{1} = fiteq;
        case 2
            varargout{1} = fiteq;
            varargout{2} = Nparams;
    end

end





% function opts = setup_fitoptions(weights, Nmodes, startpoint)
% 
%     opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
% 
%     opts.Display = 'Off';
%     opts.MaxFunEvals = 26000;
%     opts.MaxIter = 24000;
%     opts.Weights = weights;
%     opts.TolFun = 1e-07;
%     opts.TolX = 1e-07;
%     opts.DiffMinChange = 1e-08;
%     opts.DiffMaxChange = 0.01;
% 
%     % Lower and upper bounds for each parameter
%     %    [a  am   as   bm   bs ]
%     lb = [0 -Inf  0   -Inf  0  ];
%     ub = [1  Inf  Inf  Inf  Inf];
%     
%     % Default starting points if none are available
%     % p0 = [0.82582 0.07818 0.44268 0.10666 0.96190];
%     p0 = [0.85 -1.5 0.5 0.75 1];
% 
%     k = Nmodes*2 + 1;
% 
%     opts.StartPoint = startpoint(1:k);
%     opts.Lower = lb(1:k);
%     opts.Upper = ub(1:k);
% 
% end