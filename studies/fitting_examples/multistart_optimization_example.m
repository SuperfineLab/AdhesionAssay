%
% % Testing fitting with random data and our fitting equations
%

% Old model equation
% p = [a am as bm bs]
%                  1/2*(a   *erfc(((Fd)-am  )/(sqrt(2)*as  ))+(1-a   )*erfc(((Fd)-bm  )/(sqrt(2)*bs  )))
% fitfcn1 = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3)))));
% fitfcn2 = @(p, Fd)(1/2*(p(1)*erfc(((Fd)-p(2))/(sqrt(2)*p(3)))+(1-p(1))*erfc(((Fd)-p(4))/(sqrt(2)*p(5)))));

rng default

N = 50; % Number of data points

fout1 = ba_setup_fit(1, [], []);
fout2 = ba_setup_fit(2, [], []);

% For this fitting study, we simulate based on model equation with *known*
% parameter values, i.e., ground-truth parameters 
% For Nmodes up to 3, these will be...
%       [amp  mean  std]
ptrue = [0.33  -1   0.5;
         0.33   0   0.5;
         0.33   1   0.5];
ptrue = reshape(transpose(ptrue), 1, []);

xdata = sort(5.5*rand(N,1) - 3); % Data points (range from log10(0.001 nN) to log10(300 nN);

ydata1_sim = fout1.fcn(ptrue(1:3),xdata);
ydata1 = ydata1_sim + 0.025*randn(N,1); % Response data with noise

ydata2_sim = fout2.fcn(ptrue(1:6),xdata);
ydata2 = ydata2_sim + 0.025*randn(N,1); % Response data with noise

beststart1 = optimize_startpoint(fout1.fcn, fout1.StartPoint, xdata, ydata1, fout1.lb, fout1.ub);
beststart2 = optimize_startpoint(fout2.fcn, fout2.StartPoint, xdata, ydata2, fout1.lb, fout1.ub);


figure;
subplot(1,2,1);
plot_results(xdata, ydata1_sim, ydata1, fout1.fcn, beststart1);
title('One mode fit');
subplot(1,2,2);
plot_results(xdata, ydata2_sim, ydata2, fout2.fcn, beststart2);
title('Two mode fit');


function beststart = optimize_startpoint(fitfcn2, p0, xdata, ydata, lb, ub)

    [xfitted,errorfitted] = lsqcurvefit(fitfcn2,p0,xdata,ydata,lb,ub);
    
    problem = createOptimProblem('lsqcurvefit','x0',p0,'objective',fitfcn2,...
        'lb',lb,'ub',ub,'xdata',xdata,'ydata',ydata);
    
    ms = MultiStart('PlotFcns',@gsplotbestf);
    ms = MultiStart;
    [beststart,errormulti] = run(ms,problem,200);
end


function plot_results(xdata, ydata_sim, ydata, fitfcn, bestparams)
    plot(xdata, ydata_sim, 'b-', xdata, ydata, 'r.');
    hold on;
    plot(xdata, fitfcn(bestparams, xdata), 'g--');
    legend('sim input', 'sim input + noise', 'optimized fit');
    hold off;
end