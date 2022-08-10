

% file_list = dir('well*50ms.mat');

edges1 = [0:2000:65500];
edges2 = [0:500:65500];

if ~exist('thinky', 'var')
    cd('C:\Users\cribb\Desktop\deleteme\2022.07.20__HBE_Thinky3x_protocol_mosaics');
    file_list = dir('well*50ms.mat');
    thinky.mp = load_mosaic(file_list);    
end
thinky.hc = plot_mosaic_hists(thinky.mp, edges1);
gcf; title('thinky');

if ~exist('nothinky', 'var')
    cd('C:\Users\cribb\Desktop\deleteme\2022.07.22__HBE_NoThinky_Retest');
    file_list = dir('well*50ms.mat');
    nothinky.mp = load_mosaic(file_list);
end
nothinky.hc = plot_mosaic_hists(nothinky.mp, edges1);
gcf; title('nothinky');

function mosaic_pixels = load_mosaic(file_list)
    % mask = (3500:7500, 4000:10000); 
    ysize = 7500-3500+1;
    xsize = 10000-4000+1;
    if ~exist('mosaic_pixels', 'var')
        well_frames = zeros(768,1024,13*13);
        frame_mean = zeros(169,15);
        mosaic_pixels = uint16(zeros(xsize*ysize,15));
        for m = 1:15
            well = load( file_list(m).name);

    %         N = height(well.mosaic);
            im = imtile(well.mosaic.Image, 'GridSize', [13 13]); 
            im = im(3500:7500, 4000:10000);  
            alltiles(:,:,m) = im;
    %         for k = 1:N
    %             tmp = double(well.mosaic.Image{k});
    %             well_frames(:,:,k) = tmp;
    %             frame_mean(k,m) = mean(tmp(:));
    %         end

            mosaic_pixels(:,m) = im(:);
            fprintf('m = %i\n',m);
        end
    end
    clear well_frames
end

function hc = plot_mosaic_hists(mosaic_pixels, edges)
    % f1 = figure;
    f2 = figure;
    for m = 1:15
    %     figure(f1)
    %     subplot(3,5,m)    
    %     histogram(frame_mean(:,m), edges1)
    %     ax = gca;
    % %     ax.YScale = 'log';
    %     ylim([0 25])
    %     xlim([5000 20000])
        hc(:,m) = histcounts(mosaic_pixels(:,m), edges);
    end
        figure(f2);
%         subplot(3,5,m);
        plot(edges(2:end), mean(hc,2));
        errorbar(edges(2:end), mean(hc,2), std(hc,[],2));
        ax = gca;
%         ax.YScale = 'log';
        xlim([5000 65500]);
%         ylim([1e0 2e7]);    
        ylim([0 10000]);    
    
end