function plot_fovRect_over_mosaic(Min, q)

imWidth = 1024;
imHeight = 768;

figure; 
imagesc(Min);
colormap(gray);
ax = gca;
ax.CLim = [3500 5000];
hold on; 
    plot(size(Min,2)/2, size(Min,1)/2, 'rx', 'MarkerSize', 12); 
    rectangle('Position',[q(1)-imWidth, q(2)-imHeight, imWidth*2, imHeight*2], ...
          'LineWidth', 1, ...
          'EdgeColor', 'g');
hold off

