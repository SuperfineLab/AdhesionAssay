

file_list = dir('well*50ms.mat');
f1 = figure;
f2 = figure;
for m = 1:15
    well = load( file_list(m).name);
    
    N = height(well.mosaic);
    for k = 1:N
        tmp = double(well.mosaic.Image{k});
        well_frames(:,:,k) = tmp;
        frame_mean(k,m) = mean(tmp(:));
    end

    mosaic_pixels(:,m) = well_frames(:);

end

% figure(f1)
% subplot(3,5,m)
% histogram(frame_mean(:,m))
% ylim([0 110])
% xlim([4000 8000])
% 
% figure(f2)
% subplot(3,5,m)
% histogram(well_frames(:));
% ax = gca;
% ax.YScale = 'log';

% clear frame
% figure;
% for m = 1:15
% 
% end
% 
% figure; 