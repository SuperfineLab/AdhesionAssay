clear lsq_summary

Data = B.DetachForceTable;

if ~exist('lsq_summary', 'var')
    lsq_summary = table('Size', [0 7], ...
                       'VariableTypes', {'categorical', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                       'VariableNames', {'PlateID', 'StartPoint', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
end

Nmodes = 2;
Nsubsamples = 5;
fig = figure;

% colors for figures
c = lines(7);
chi = c*1.2; chi(chi>1)=1;
clo = c*0.8;

% Some number (m) of plates to process
for m = 1:height(Data)

    PlateID = Data.PlateID(m);
    rawdata = Data.RawData{m};
        
    logforce_nN = log10(rawdata.Force);
    logforceinterval = log10(rawdata.ForceInterval);
    fractionLeft = rawdata.FractionLeft; 
    weights = rawdata.Weights;

    % configure everything using current data (includes weights)
    fout  = ba_fit_setup(Nmodes, weights);
    costfunction = @(p) weights .* (fout.fcn(p,logforce_nN)-fractionLeft).^2;

    fout.opts.Display = 'off';
%     [myfit,myfiterror] = lsqnonlin(costfunction,fout.StartPoint,fout.lb,fout.ub,fout.opts);
%     [myfit,myfiterror] = lsqcurvefit(fout.fcn,fout.StartPoint,logforce_nN,fractionLeft,fout.lb,fout.ub, fout.opts);

    % Setting it up as a matlab "optimization problem"
    probopts = ba_fitoptions("lsqnonlin");
    problem = createOptimProblem('lsqnonlin','x0',fout.StartPoint,'objective',costfunction,...
                                 'lb',fout.lb,'ub',fout.ub,options=probopts);
%     probopts = ba_fitoptions("lsqcurvefit");
%     problem = createOptimProblem('lsqcurvefit','x0',fout.StartPoint,'objective',costfunction,...
%                                  'lb',fout.lb,'ub',fout.ub,options=probopts);

    ms = MultiStart("Display","off");

    tic
        [myfit,myfiterror,exitflag] = run(ms,problem,100);
    solvetime = toc;

    rchisq = red_chisquare(myfit, fout.fcn, logforce_nN, fractionLeft);

    lqtmp = table(PlateID, fout.StartPoint, solvetime, exitflag, myfit, myfiterror, rchisq, 'VariableNames', {'PlateID', 'StartPoint', 'SolveTime', 'ExitFlag', 'OptimizedParameters', 'TotalError', 'ReducedChiSq'});
    
    lsq_summary = vertcat(lsq_summary, lqtmp);

    figure(fig); 
    subplot(2,2,1); 
    hold on
    plot(logforce_nN, fractionLeft, 'Color', c(m,:), 'Marker', '.', 'LineStyle', 'none'); 
    plot(logforceinterval(:,1), fractionLeft, 'Color', chi(m,:), 'LineStyle', '-', 'LineWidth', 0.25); 
    plot(logforceinterval(:,2), fractionLeft, 'Color', chi(m,:), 'LineStyle', '-', 'LineWidth', 0.25); 
    hold off
    title(['origdata', ', Nmodes=', num2str(Nmodes)]); 
    xlabel('log_{10}(Force [nN])');
    ylabel('Fraction Removed');
    
    subplot(2,2,2); 
    hold on
    plot(logforce_nN, weights); 
    ax = gca;
    ax.YScale = "log";
    hold off
    title('weights vs logforce'); 

    subplot(2,2,3); 
    hold on
%     plot(logforce_nN, fractionLeft, 'Color', clo(m,:), 'Marker', '.', 'LineStyle', 'none');
    plot(logforce_nN, fout.fcn(myfit, logforce_nN), 'Color', clo(m,:), 'LineStyle', '-', 'LineWidth', 2); 
    plot(logforceinterval(:,1), fractionLeft, 'Color', chi(m,:), 'LineStyle', '-','LineWidth',0.25); 
    plot(logforceinterval(:,2), fractionLeft, 'Color', chi(m,:), 'LineStyle', '-','LineWidth',0.25); 
    hold off
    title(['fits', ', Nmodes=', num2str(Nmodes)]);
    xlabel('log_{10}(Force [nN])');
    ylabel('Fraction Removed');

    subplot(2,2,4); 
    hold on
    plot(logforce_nN, costfunction(logforce_nN), '.'); 
    ax = gca;
    ax.YScale = "log";
    hold off
    title('costfunction');
    
end