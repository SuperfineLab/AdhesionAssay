% clear q
subplot = @(m,n,p) subtightplot(m, n, p, [0.01 0.005], [0.1 0.01], [0.1 0.01]);
% function h =     subtightplot(m, n, p, gap,         marg_h,     marg_w,   varargin)

well = 1:15;
exptime(1:15) = 8;
% calibum = 0.692;
calibum = 0.858;
% for k = 1:5

% fname = ['well-' num2str(well(k), '%02i') '_10x_' num2str(exptime(k)) 'ms'];
fname = 'well-*_10x*ms.mat';
fnamelist = dir(fname);

plotorder = [5:-1:1,10:-1:6,15:-1:11];
if ~exist("q","var")

    q = cell(15,1);

    for k = 1:length(fnamelist)
        
        m = load(fnamelist(k).name);

        well = regexpi(fnamelist(k).name, 'well-(\d*)', 'tokens');
        well = str2num(well{1}{1});
    
    
        m = m.mosaic;
        arrivedxy_ticks{k,1} = m.ArrivedXY;
%         im = imtile(m.Image, 'GridSize', [13 13]); 
        im = imtile(m.Image, 'GridSize', [8 6]); 
    %     imwrite(im, [fname '.tif'], 'tif');
    %     im = im(3500:7500, 4000:10000);  
        myscale = 0.2;
        im = imresize(im, myscale, 'bicubic');
        q{well,1} = im;
        sumIntensity(k,1) = sum(im(:));
        
        
        [height, width] = size(im);
        X_mm = [1:width]  * calibum/1000 / myscale;
        Y_mm = [1:height] * calibum/1000 / myscale;
    end
end

Pos = vertcat(Plate.fov(:).Pos);
[wellnum, xyoffset_mm] = plate2well(hw.ludl, Plate.calib, Pos);
imagecenterxy_mm = [max(X_mm)/2, max(Y_mm)/2];
magnetdrop_mm = imagecenterxy_mm + xyoffset_mm;

f = figure;
for k = 1:length(plotorder)
    figure(f);
    subplot(3,5,k);
    imagesc(X_mm, Y_mm, q{k,1});     
    colormap(gray); 
    axis image
    ax = gca; 
    ax.CLim = [4000 45000];    
    xlabel('[mm]');
    ylabel('[mm]');    

    if any(k == [2:5,7:10,12:15])
        ax.YTickLabel = '';
        ax.YLabel.String = '';
    end

    if any(k == [1:10]) > 0
        ax.XTickLabel = '';
        ax.XLabel.String = '';
    end
    figure(f);    
    hold on;
%     plot(imagecenterxy_mm(1,1), imagecenterxy_mm(1,2), 'g+');
    plot(magnetdrop_mm(k,1), magnetdrop_mm(k,2), 'o', 'Color', [1 1 0], 'MarkerSize', 10);
    plot(magnetdrop_mm(k,1), magnetdrop_mm(k,2), 'x', 'Color', [1 1 0], 'MarkerSize', 10);

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

