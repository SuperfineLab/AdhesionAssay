clear lsq_summary
addpath '/Users/stevesnare/code/AdhesionAssay/analysis'
Data = B.DetachForceTable;

if ~exist('lsq_summary', 'var')
    lsq_summary = table('Size', [0 7], ...
                       'VariableTypes', {'categorical', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                       'VariableNames', {'PlateID', 'StartPoint', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
end
fitname = 'erf-new';
Nmodes = 2;
Nsubsamples = 5;
fig = figure;


% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m); 
    rawdata = Data.RawData{m};
    
    force = rawdata.Force;
    %errforce = diff(rawdata.ForceInterval,[],2)/2;
    errforce = rawdata.ForceError;
    factorLeft = rawdata.PctLeft; 
    weights = rawdata.Weights;

    logforce_nN = log10(force);
    errbarlength  = log10(force + errforce)-log10(force);
    % configure everything using current data (includes weights)
    fout  = ba_setup_fit(fitname, weights, Nmodes);
    costfunction = @(p) weights .* (fout.fcn(p,logforce_nN)-factorLeft);

    opts = optimset('Display', 'off');
    [myfit,myfiterror] = lsqnonlin(costfunction,fout.StartPoint,fout.lb,fout.ub,opts);
    % [xfitted,errorfitted] = lsqcurvefit(fitfcn,fout.StartPoint,logforce_nN,factorLeft,lb,ub, opts);

%     % Setting it up as a matlab "optimization problem"
%     probopts = optimoptions(@lsqnonlin, 'Display', 'final');
%     problem = createOptimProblem('lsqnonlin','x0',fout.StartPoint,'objective',costfunction,...
%                                  'lb',fout.lb,'ub',fout.ub,options=probopts);
%     ms = MultiStart
%     [x,f] = run(ms,problem,20);


    figure(); 
    subplot(2,2,1); 
    hold on
    plot(logforce_nN, factorLeft, '.'); 
    hold off
    title('rawdata: pctleft vs force'); 
    
    subplot(2,2,2); 
    hold on
    plot(logforce_nN, weights); 
    ax = gca;
    ax.YScale = "log";
    hold off
    title('weights vs logforce'); 
    
    subplot(2,2,3); 
    hold on
    plot(logforce_nN, costfunction(logforce_nN), '.'); 
    ax = gca;
    ax.YScale = "log";
    hold off
    title('costfunction');
    
    subplot(2,2,4); 
    hold on
    plot(logforce_nN, factorLeft, '.', ...
         logforce_nN, fout.fcn(myfit, logforce_nN), '--'); 
    hold off
    title('fits against rawdata');

end