function [FidLudlLocs, imstack] = fiducial_position_array(ludl)
% FIDUCIAL_POSITION_ARRAY opens a viewing window for the user to manually
% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.

% image_width_pixels = 648;
% image_height_pixels = 488;

image_width_pixels = 1024;
image_height_pixels = 768;

% Distances between fiducial marks
% Version 1 (meganp)
% plate_length_mm = 69.6;
% plate_width_mm = 44.476;

% Version 2 (david wollensak)
plate_length_mm = 57.96;
plate_width_mm = 43.2;

plate_length_ticks = mm2tick(ludl, plate_length_mm);
plate_width_ticks = mm2tick(ludl, plate_width_mm);

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

