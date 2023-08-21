function corr_im = correct_stack(dark_image, shade_image, stackImages)
    
    dark = single(dark_image.medfilt);
    shade = single(shade_image.medfilt);

    minval = abs(min(shade - dark, [], 'all'));
    corr_im = cellfun(@(im)((single(im) - dark) ./ (shade - dark + minval)), stackImages, 'UniformOutput', false);
    corr_im = cellfun(@eliminate_badpoints, corr_im, 'UniformOutput', false);
    
end

function im = eliminate_badpoints(im)
    im(~isfinite(im)) = 0;
end

