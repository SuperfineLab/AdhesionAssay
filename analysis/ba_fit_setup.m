function fout = ba_fit_setup(Nmodes, weights, startpoint)
% XXX @jeremy TODO: Write documentation
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
    logforcelimitLow  = -1.5;
    logforcelimitHigh =  2.0;
    logforcerange = abs(logforcelimitHigh - logforcelimitLow);
    logforcestep = logforcerange / (Nmodes+1);

    if nargin < 3 || isempty(startpoint) || numel(startpoint) ~= Nparams
    
        p0 = repmat([1/Nmodes, NaN, 0.5], Nmodes, 1);
        p0(:,2) = logforcelimitLow+transpose(0:Nmodes-1)*logforcestep;
    
        % Spin out starting locations according to number of modes
        pstart(1,:) = reshape(transpose(p0),1,[]);        
        
    else
        pstart = startpoint;
    end

    % limit constraints (if necessary) (The sum of all amplitudes should be
    % equal to one since the "fractionLeft" is normalized by default.)
    Aeq = repmat([1 0 0], 1, Nmodes);
    beq = 1;

    % Assemble default options structure 
    opts = ba_fitoptions('lsqnonlin', [], pstart, lb, ub);

    
    fout.fcn = fitfcn;    
    fout.Nmodes = Nmodes;
    fout.Nparams = Nparams;
%     fout.opts = opts;
    fout.logforcelimitHigh = logforcelimitHigh;
    fout.logforcelimitLow = logforcelimitLow;
    fout.StartPoint = pstart;
    fout.lb = lb;
    fout.ub = ub;
    fout.Aeq = Aeq;
    fout.beq = beq;
end


