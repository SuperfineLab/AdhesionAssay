function [fiducialpos, imstack] = fiducial_position_array(ludl)
% FIDUCIAL_POSITION_ARRAY opens a viewing window for the user to manually
% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.

% WARNING: Adjust 'points' according to image size!
plate_length_ticks = mm2tick(69.6);
plate_width_ticks = mm2tick(44.476);

imstack = zeros(488,648,4);

fiducialpos = [                  0,                   0 ; ...
                                 0, -plate_length_ticks ; ...
                -plate_width_ticks, -plate_length_ticks ; ...
                -plate_width_ticks,                   0 ];


vid = videoinput('pointgrey', 1, 'F7_Mono8_648x488_Mode0');

% Get positions and images for each fiducial mark after 'Enter' is hit
disp('Starting...')
for k = 1:size(fiducialpos,2)
    my_pos = fiducialpos(k,:);
    stage_move_Ludl(ludl, my_pos(k,:));
    disp(strcat('Locate Point',num2str(k)))
    preview(vid);
    pause;
    stoppreview(vid);
    frame = getsnapshot(vid);
    imwrite(frame,strcat('im',num2str(k),'.tif'));
    imstack(:,:,k) = frame;
    fiducialpos(k,:) = [stage_get_pos_Ludl(ludl).Pos(1), stage_get_pos_Ludl(ludl).Pos(2)];

end

% Convert points into uint8
imstack = uint8(imstack);

