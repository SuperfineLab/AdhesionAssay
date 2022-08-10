clear q
subplot = @(m,n,p) subtightplot(m, n, p, [0.01 0.005], [0.1 0.01], [0.1 0.01]);
% function h =     subtightplot(m, n, p, gap,         marg_h,     marg_w,   varargin)

well = 1:15;
exptime(1:15) = 8;
calibum = 0.692;
for k = 1:5
% for k = [5:-1:1,10:-1:6,15:-1:11]
    
    fname = ['well-' num2str(well(k), '%02i') '_10x_' num2str(exptime(k)) 'ms'];
    
    m = load([fname '.mat']);
    m = m.mosaic;
    im = imtile(m.Image, 'GridSize', [13 13]); 
    imwrite(im, [fname '.tif'], 'tif');
    im = im(3500:7500, 4000:10000);  
    q(:,:,k) = im;
    sumIntensity(k,1) = sum(im(:));
    myscale = 0.25;
    im = imresize(im, myscale);
    [height, width] = size(im);
    X_mm = [1:width]  * calibum/1000 / myscale;
    Y_mm = [1:height] * calibum/1000 / myscale;
end

f = figure;
for k = [5:-1:1]%, 10:-1:6, 15:-1:11]
    figure(f);
    subplot(3,5,k);
    imagesc(X_mm, Y_mm, q(:,:,k)); 
    colormap(gray); 
    ax = gca; 
    ax.CLim = [3500 5000];    
    xlabel('[mm]');
    ylabel('[mm]');    
end


% for k = [5:-1:1, 10:-1:6, 15:-1:11]
%     figure(f);
%     subplot(3,5,k);
%     colormap(gray); 
%     ax = gca; 
%     ax.CLim = [4000 6000];    
%     xlabel('[mm]');
%     ylabel('[mm]');    
% end

