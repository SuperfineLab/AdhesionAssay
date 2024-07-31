function stack = bead_mosaic_analysis(stack, threshold, kernel, radiuslowhi, overfill_factor, ringmaskTF)

    if nargin < 6 || isempty(ringmaskTF)
        ringmaskTF = false;
    end

    if nargin < 5 || isempty(overfill_factor)
        overfill_factor = 1;
    end
    
    if nargin < 4 || isempty(radiuslowhi)
        radiuslowhi = [10 25];
    end
    
    if nargin < 3 || isempty(kernel)
        kernel = strel("disk", 3);
    end
    
    if nargin < 2 || isempty(threshold)
        threshold = 3; % this value thresholds against the corrected image signal (where 1 = shade, >1 = signal)
    end

    stack.BinaryImage = cellfun(@(x1)clean_beadimage(x1, threshold, kernel), stack.CorrectedImage, 'UniformOutput', false);      

    [stack.BeadLocations, ...
     stack.BeadRadii] = cellfun(@(x1)imfindcircles(x1,radiuslowhi), stack.BinaryImage, 'UniformOutput', false);
    
    stack.BeadMask = cellfun(@(x1,x2,x3)calcBeadMask(x1,x2,x3,overfill_factor,ringmaskTF), stack.CorrectedImage, stack.BeadLocations, stack.BeadRadii, 'UniformOutput',false);
    
    stack.Nbeads = cellfun(@(x)size(x,1), stack.BeadLocations, 'UniformOutput',false);  
    
    stack.BeadPixels = cellfun(@(x1,x2)pullbeadpixels(x1,x2),stack.CorrectedImage, stack.BeadMask, 'UniformOutput',false);    

    BeadImageOverfill = 1.15;
    TrackerHalfSize = ceil(BeadImageOverfill*max(cell2mat(stack.BeadRadii)));
    stack.BeadImages = cellfun(@(x1,x2)pull_out_bead_images(x1,x2,TrackerHalfSize), stack.CorrectedImage, stack.BeadLocations, 'UniformOutput', false);

    MaskedImages = cellfun(@(x1,x2)(single(x1) .* single(x2)), stack.CorrectedImage, stack.BeadMask, 'UniformOutput', false);
    stack.MaskedBeadImages =  cellfun(@(x1,x2)pull_out_bead_images(x1,x2,TrackerHalfSize), MaskedImages, stack.BeadLocations, 'UniformOutput', false);
end



function imout = clean_beadimage(im_in, threshold, kernel)

    im_out = imbinarize(im_in, threshold); 
    im_out = imerode(im_out,kernel); 
    im_out = imclose(im_out,kernel); 
    imout = imdilate(im_out,kernel);
    
end


function beadmask = calcBeadMask(imagein, beadlocs, beadradii, overfill_factor, ringmaskTF)

    if nargin < 5 || isempty(ringmaskTF)
        ringmaskTF = false;
    end

    if nargin < 4 || isempty(overfill_factor)
        overfill_factor = 1;
    end

    beadmask = zeros(size(imagein));
        
    if isempty(beadlocs)
        beadmask = logical(zeros(size(imagein)));
    elseif ringmaskTF
        discmask = createCirclesMask(imagein, beadlocs, beadradii*overfill_factor);
        annulusmask = createCirclesMask(imagein, beadlocs, beadradii*0.33);
        beadmask = logical(discmask - annulusmask);
    else
        beadmask = createCirclesMask(imagein, beadlocs, beadradii*overfill_factor);
    end

%     beadim = imagein(mask);

end


function sigout = pullbeadpixels(cleanimage, beadmask)

    sigout = NaN(size(cleanimage));
    sigout(beadmask) = cleanimage(beadmask);
    sigout = sigout(:);    
    sigout = sigout( ~isnan(sigout));
end


function outs = pull_out_bead_images(CorrectedImage, BeadLocations, trackerHalfSize)
    video_tracking_constants;

    [r,c] = size(BeadLocations);

    if r>0
        tracking_mat = zeros(r,15);
        tracking_mat(:,ID) = 1:r;
        tracking_mat(:,X) = BeadLocations(:,1);
        tracking_mat(:,Y) = BeadLocations(:,2);
    
        tracker_stack = get_tracker_images(tracking_mat, CorrectedImage, trackerHalfSize, 'n');
        outs = tracker_stack.stack;
    else
        outs = [];
    end
end