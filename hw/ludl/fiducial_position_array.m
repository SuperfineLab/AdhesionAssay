function [FidLudlLocs, imstack] = fiducial_position_array(ludl)
% FIDUCIAL_POSITION_ARRAY opens a viewing window for the user to manually
% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.


plate_length_mm = 69.6;
plate_width_mm = 44.476;

plate_length_ticks = mm2tick(plate_length_mm);
plate_width_ticks = mm2tick(plate_width_mm);

% WARNING: Adjust the size of imstack according to image size!
imstack = zeros(488, 648, 4);

FiducialOffsets = [                  0,                   0 ; ...
                                     0, -plate_length_ticks ; ...
                    -plate_width_ticks, -plate_length_ticks ; ...
                    -plate_width_ticks,                   0 ];
FidLudlLocs = zeros(4,2);

vid = videoinput('pointgrey', 1, 'F7_Mono8_648x488_Mode0');

% Get positions and images for each fiducial mark after 'Enter' is hit
disp('Starting...')

preview(vid);

for k = 1:size(FiducialOffsets,1)

    disp(strcat('Locate Point #',num2str(k))) 
    
    if k == 1
        pause;
    else
        stage_move_Ludl(ludl, FidLudlLocs(1,:) + FiducialOffsets(k,:));
        pause;
    end
    
    frame = getsnapshot(vid);
%     imwrite(frame,strcat('im',num2str(k),'.tif'));
    imstack(:,:,k) = frame;
    ludl = stage_get_pos_Ludl(ludl);
    FidLudlLocs(k,:) = ludl.Pos;
end

closepreview(vid);


% Convert points into uint8
imstack = uint8(imstack);

