clear lsq_summary

Data = B.DetachForceTable;

if ~exist('lsq_summary', 'var')
    lsq_summary = table('Size', [0 7], ...
                       'VariableTypes', {'categorical', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                       'VariableNames', {'PlateID', 'StartPoint', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
end

Nmodes = 4;
Nsubsamples = 5;
fig = figure;


% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m);
    rawdata = Data.RawData{m};
    
    
    logforce_nN = log10(rawdata.Force);
    logforce_interval = log10(rawdata.ForceInterval);
    fractionLeft = rawdata.FractionLeft; 
    weights = rawdata.Weights;

    % configure everything using current data (includes weights)
    fout  = ba_setup_fit(Nmodes, weights);
    costfunction = @(p) weights .* (fout.fcn(p,logforce_nN)-fractionLeft);

    fout.opts.Display = 'off';
%     [myfit,myfiterror] = lsqnonlin(costfunction,fout.StartPoint,fout.lb,fout.ub,fout.opts);
    [myfit,myfiterror] = lsqcurvefit(fout.fcn,fout.StartPoint,logforce_nN,fractionLeft,lb,ub, fout.opts);

    % Setting it up as a matlab "optimization problem"
    probopts = optimoptions(@lsqnonlin, 'Display', 'final');
    problem = createOptimProblem('lsqnonlin','x0',fout.StartPoint,'objective',costfunction,...
                                 'lb',fout.lb,'ub',fout.ub,options=probopts);
    ms = MultiStart("Display","off");
    [x,f] = run(ms,problem,20);


    figure(fig); 
    subplot(2,2,1); 
    hold on
    plot(logforce_nN, fractionLeft, '.'); 
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
    plot(logforce_nN, fractionLeft, '.', ...
         logforce_nN, fout.fcn(myfit, logforce_nN), '--'); 
    hold off
    title('fits against rawdata');

end