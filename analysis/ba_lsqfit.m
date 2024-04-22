%%% attempting to figure out which fitting method is the best for our data.
function lsqout = ba_lsqfit(dftable,startpoint)
addpath('/Users/stevesnare/code/AdhesionAssay/analysis')
Data = dftable ;

fitname = 'erf-new';
Nmodes = 2;
Nsubsamples = 1;
%fig = figure;
options = ba_fitoptions("lsqnonlin");

% Some number (m) of plates to process
for m = 1:height(Data)
    clear temptable

    tic
    PlateID = Data.PlateID(m); 
    rawdata = Data.RawData{m};
    
    force = rawdata.Force;
    errforce = diff(rawdata.ForceInterval,[],2)/2;
    %errforce = rawdata.ForceError;
    fractionLeft = rawdata.FractionLeft; 
    weights = rawdata.Weights;

    logforce_nN = log10(force);
    errbarlength  = log10(force + errforce)-log10(force);
    % configure everything using current data (includes weights)
    fout  = ba_fit_setup(Nmodes, weights);
    costfunction = @(p) weights .* (fout.fcn(p,logforce_nN)-fractionLeft);

    opts = optimset('Display', 'off');
    [myfit,myfiterror] = lsqnonlin(costfunction,startpoint,fout.lb,fout.ub,opts);
    t = toc;
    % [xfitted,errorfitted] = lsqcurvefit(fitfcn,fout.StartPoint,logforce_nN,factorLeft,lb,ub, opts);

%     % Setting it up as a matlab "optimization problem"
%     probopts = optimoptions(@lsqnonlin, 'Display', 'final');
%     problem = createOptimProblem('lsqnonlin','x0',fout.StartPoint,'objective',costfunction,...
%                                  'lb',fout.lb,'ub',fout.ub,options=probopts);
%     ms = MultiStart
%     [x,f] = run(ms,problem,20);

    temptable.PlateID = PlateID;
    temptable = struct2table(temptable);
    temptable.OptimizedParameters = myfit;
    temptable = [temptable,array2table(myfiterror)];
    temptable.SolveTime = t;
    

%    [optimized_params(k,:), error(k,1), exitflag(k,1)] = lsqnonlin(@(p) objectiveFunction(p, fout.fcn, logforce_nN, fractionLeft, weights), ...
 %                                       fout.Nparams, fout.Aeq, fout.beq, [], [], fout.lb, fout.ub, [], options);
        
    rchisq(m,:) = red_chisquare(myfit(1,:), fout.fcn, logforce_nN, fractionLeft);
        

   
    lsqout{m,1} = [temptable,array2table(rchisq(m,:))];
    pause(0.1)
    


end

lsqout = vertcat(lsqout{:});
lsqout.Properties.VariableNames = {'PlateID', 'OptimizedParameters','fiterror','SolveTime','RedChisq'};

end


function error = objectiveFunction(params, fitfcn, logforce_nN, fractionLeft, weights)
    % params: Parameters to be optimized, [a am as bm bs]
    % xdata: Independent variable data
    % ydata: Dependent variable data
    % weights: Weight values for each data point


    % Calculate model predictions using params and xdata
    model_predictions = fitfcn(params, logforce_nN);

    % Calculate weighted squared error
    weighted_errors = weights .* (model_predictions - fractionLeft).^2;
%     weighted_errors = smooth(weighted_errors,5);
    error = sum(weighted_errors);
end