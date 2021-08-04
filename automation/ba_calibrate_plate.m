function outs = ba_calibrate_plate(ludl, platelayout)
% BA_CALIBRATE_PLATE uses the fiducial marking images taken by the camera and the
% location of the stage in ludl coordinates at that location to calculate
% the location of the sample on the ludl stage

if nargin < 2 || isempty(platelayout)
    platelayout = '15v2';
end

switch platelayout
    case '15v1'
        % 15 well plate version 1 (meganp)
        plate_length_mm = 69.6;
        plate_width_mm = 44.476;
    case '15v2'
        % 15 well plate version 2 (wollensack)
        plate_length_mm = 57.96;
        plate_width_mm = 43.2;
    otherwise
        error('Unknown plate layout defined.');
end

plate_length_ticks = mm2tick(plate_length_mm);
plate_width_ticks = mm2tick(plate_width_mm);

% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.
[pos, imstack] = fiducial_position_array(ludl, platelayout);

% Finds the ludl coordinates that would place the fiducial center in the
% center of the image
for k = 1:size(imstack,3)
    [x,y] = image_center_find(imstack(:,:,k), pos(k,1), pos(k,2));
    outs.centers(k,1) = x;
    outs.centers(k,2) = y;
end

% Find the angle of tilt in radians
Ftop_leftXY = outs.centers(1,:);
Ftop_rightXY = outs.centers(2,:);
Fbottom_rightXY = outs.centers(3,:);
Fbottom_leftXY = outs.centers(4,:);

outs.theta = atan(abs(Ftop_rightXY(1) - Ftop_leftXY(1))/abs(Ftop_rightXY(2) - Ftop_leftXY(2)));

% Create error matrix of side lengths, order sides as NSEW, with top length as "North"
errormatrix = zeros(4,2);

% Finds error in tick marks (col 1)
errormatrix(1,1) = pdist([Ftop_leftXY;Ftop_rightXY]) - plate_length_ticks;
errormatrix(2,1) = pdist([Fbottom_rightXY;Fbottom_leftXY]) - plate_length_ticks;
errormatrix(3,1) = pdist([Ftop_rightXY;Fbottom_rightXY]) - plate_width_ticks;
errormatrix(4,1) = pdist([Ftop_leftXY;Fbottom_leftXY]) - plate_width_ticks;

% Finds percent error (col 2)
errormatrix(1,2) = errormatrix(1,1)/plate_length_ticks * 100;
errormatrix(2,2) = errormatrix(2,1)/plate_length_ticks * 100;
errormatrix(3,2) = errormatrix(3,1)/plate_width_ticks * 100;
errormatrix(4,2) = errormatrix(4,1)/plate_width_ticks * 100;

outs.errormatrix = errormatrix;

return



function [x_center, y_center, x_disp, y_disp] = image_center_find(im, x_start, y_start)
% IMAGE_CENTER_FIND locates the center of each fiducial mark and determines 
% the ludl coordinates that the stage would need to be in such that the 
% center of each fiducial mark would be at the center of the image

    cameraname = 'Grasshopper3';
    switch lower(cameraname)
        case 'grasshopper3'
            image_width_pixels = 1024;
            image_height_pixels = 768;
            SE_radius = 22;
        case 'dragonfly2'
            image_width_pixels = 648;
            image_height_pixels = 488;
            SE_radius = 14;        
    end

    % Define structuring element
    SE = strel('disk', SE_radius);
    factor = 45;

    % Binarize and erode/dilate image
    test = im;
    test = imbinarize(test);
    
    if sum(test(:)) > 1/2 * (image_width_pixels * image_height_pixels)       
        test = imcomplement(test); 
    end
    
    test = imdilate(test,SE); 
    test = imerode(test,SE); 

    % (10:end-10,10:end-10)
    % Find/plot center of mass
    [x, y] = centerofmass(test);

    % Find pixel displacement from center and convert to ticks
    % x_disp = (635/2 - x) * -factor;
    % y_disp = (470/2 - y) * factor;

    x_disp = (image_width_pixels/2 - x) * -factor;
    y_disp = (image_height_pixels/2 - y) * factor;

    % Find coordinates for the center of the fiducial markings in ludl
    % coordinates
    x_center = x_start + x_disp;
    y_center = y_start + y_disp;

    % Debug plot (comment out later)
    figure; 
    imshow(test)
    hold on
        plot(x, y, 'or');
        plot(x_center, y_center, 'xg');   
    hold off
    legend('center of mass', 'center of field');

return


function [FidLudlLocs, imstack] = fiducial_position_array(ludl, platelayout)
% FIDUCIAL_POSITION_ARRAY opens a viewing window for the user to manually
% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.

    if nargin < 2 || isempty(platelayout)
        platelayout = '15v2';
    end
    
    % image_width_pixels = 648;
    % image_height_pixels = 488;

    image_width_pixels = 1024;
    image_height_pixels = 768;

    switch platelayout
        case '15v1'
            % Distances between fiducial marks
            % Version 1 (meganp)
            plate_length_mm = 69.6;
            plate_width_mm = 44.476;
        case '15v2'
            % Version 2 (david wollensak)
            plate_length_mm = 57.96;
            plate_width_mm = 43.2;
        otherwise
            error('Unknown platelayout.');
    end
    
    plate_length_ticks = mm2tick(plate_length_mm);
    plate_width_ticks = mm2tick(plate_width_mm);

    % WARNING: Adjust the size of imstack according to image size!
    imstack = zeros(image_height_pixels, image_width_pixels, 4);

    FiducialOffsets = [                  0,                   0 ; ...
                                         0, -plate_length_ticks ; ...
                        -plate_width_ticks, -plate_length_ticks ; ...
                        -plate_width_ticks,                   0 ];
    FidLudlLocs = zeros(4,2);



    % Get positions and images for each fiducial mark after 'Enter' is hit
    disp('Starting...')

    % preview(vid);
    f = ba_impreview;

    for k = 1:size(FiducialOffsets,1)

        disp(strcat('Locate Point #',num2str(k))) 

        if k == 1
            pause;
        else
            stage_move_Ludl(ludl, FidLudlLocs(1,:) + FiducialOffsets(k,:));
            pause;
        end

    %     frame = getsnapshot(vid);

        % This uses the ba_impreview function and relies on knowing the EXACT
        % configuration of the ba_impreview figure. The code should be changed
        % to something way more robust than this.
        sibs = f.Children;    
        for m = 1:length(sibs)
            mytag = sibs(m).Tag;        
            switch mytag
                case 'Live Image'
                    ax = sibs(m);
                case 'Image Histogram'

            end
        end

        frame = ax.Children.CData;

    %     imwrite(frame,strcat('im',num2str(k),'.tif'));
        imstack(:,:,k) = frame;
        ludl = stage_get_pos_Ludl(ludl);
        FidLudlLocs(k,:) = ludl.Pos;
    end

    % closepreview(vid);
    close(f);

    % Convert points into uint8
    switch class(frame)
        case 'uint8'
            imstack = uint8(imstack);
        case 'uint16'
            imstack = uint16(imstack);
    end

return