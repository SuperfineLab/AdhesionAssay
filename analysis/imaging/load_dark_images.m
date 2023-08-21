function dark_image = load_dark_images(dark_imfiles)
    
    for k = 1:length(dark_imfiles)
        currfile = fullfile(dark_imfiles(k).folder,dark_imfiles(k).name);
        im(:,:,k) = imread(currfile);
    end

    dark_image.mean = mean(double(im),3);
    dark_image.std = std(double(im),[],3);
    dark_image.medfilt = medfilt2(dark_image.mean,[4 4],'symmetric');
    dark_image.raw = im;
    
end
