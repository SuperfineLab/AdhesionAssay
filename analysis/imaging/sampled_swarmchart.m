function h = sampled_swarmchart(x, ymat, samplesize)

rng('shuffle');

ycount = sum(~isnan(ymat),1);

for k = 1:size(ymat,2)
    nnn = ~isnan(ymat(:,k));
    ytmp = ymat(nnn, k);
    ridx = randi([1, sum(nnn)], samplesize, 1);
    ysamp(:,k) = ytmp(ridx,1);    
end
ysamp = single(ysamp);

% yout = ycell(ridx{,:);



figure;
swarmchart(x, ysamp);
ax = gca;
% ax.XLim = [0 10];
% ax.XTick = [1:9];
% ax.XTickLabels = {'01blank','01/g20blank','02stain','03stain','04mucus','06mucstain','06/g20mucstain','10mucstain','13mucstain'};
grid
xlabel('Well');
ylabel('signal');
% title('fluoPAS stain 2023.a03.29 Hill-Olympus-ORCA');
% -----------------