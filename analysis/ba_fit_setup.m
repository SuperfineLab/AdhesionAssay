function fout = ba_fit_setup(Nmodes, startpoint)
% BA_FIT_SETUP sets up the standard Adhesion Assay fitting equation (erf)
% 
%   fout = ba_fit_setup(Nmodes, startpoint)
%
% Output: 
%   fout - output structure containing fitting equation object, upper and
%          lower fitting bounds, parameter constraints, starting guesses, 
%          and the numbers of fitting modes and equation parameters.
%
% Inputs:
%   Nmodes - number of fitting modes (three fitting parameters per node.)
%   startpoint - first guess for parameters in fitting function.
%

    % new form
    fitfcn = ba_fitfcn(Nmodes);
    Nparams = Nmodes * 3;


    % Upper and Lower bounds for *ONE MODE* parameter fitting
    %     [a,   am,  as]
    lb1 = [0, -Inf,   0];
    ub1 = [1,  Inf, Inf];
    
    % Tile out bounds according to how many modes in the fit
    lb = repmat(lb1, 1, Nmodes);
    ub = repmat(ub1, 1, Nmodes);


    %
    % Handling startpoints
    %
    % Default parameters are set according to the number of modes and 
    % equally spaced from low-high limits, which are assumed to be 
    % between 10^-1.5 and 10^2 nanoNewtowns.
    % Note: historically well-functioning startpoints for the early
    % 5-parameter fits were:
    %         startpoint = [0.825817697748955, ...   % a
    %                       0.078175528753184, ...   % am
    %                       0.442678269775446, ...   % as
    %                       0.106652770180584, ...   % bm
    %                       0.961898080855054 ];     % bs
    logforcelimitLow  = -1.5;
    logforcelimitHigh =  2.0;
    logforcerange = abs(logforcelimitHigh - logforcelimitLow);
    logforcestep = logforcerange / (Nmodes+1);

    if nargin < 2 || isempty(startpoint) || numel(startpoint) ~= Nparams
    
        p0 = repmat([1/Nmodes, NaN, 0.5], Nmodes, 1);
        p0(:,2) = logforcelimitLow+transpose(0:Nmodes-1)*logforcestep;
    
        % Spin out starting locations according to number of modes
        pstart(1,:) = reshape(transpose(p0),1,[]);        
        
    else
        pstart = startpoint;
    end

    % limit constraints (if necessary) (The sum of all amplitudes should be
    % less than or equal to one since the "fractionLeft" is normalized by default.)
    Aeq = repmat([1 0 0], 1, Nmodes);
    beq = 1;
    Aineq = repmat([1 0 0], 1, Nmodes);
    bineq = 1;
    
    fout.fcn = fitfcn;    
    fout.Nmodes = Nmodes;
    fout.Nparams = Nparams;
    fout.logforcelimitHigh = logforcelimitHigh;
    fout.logforcelimitLow = logforcelimitLow;
    fout.StartPoint = pstart;
    fout.lb = lb;
    fout.ub = ub;
    fout.Aeq = Aeq;
    fout.beq = beq;
    fout.Aineq = Aineq;
    fout.bineq = bineq;

end


