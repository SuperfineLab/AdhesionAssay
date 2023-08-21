function shade_image = load_shade_images(shade_imfiles)

    for k = 1:length(shade_imfiles)
        currfile = fullfile(shade_imfiles(k).folder,shade_imfiles(k).name);
        im(:,:,k) = imread(currfile);
    end

    shade_image.mean = mean(double(im),3);
    shade_image.std = std(double(im),[],3);
    shade_image.medfilt = medfilt2(shade_image.mean,[4 4],"symmetric");
    shade_image.raw = im;
    
end
