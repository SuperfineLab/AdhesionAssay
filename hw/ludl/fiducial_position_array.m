function [fiducialpos, points] = fiducial_position_array(ludl)
% FIDUCIAL_POSITION_ARRAY opens a viewing window for the user to manually
% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.

% WARNING: Adjust 'points' according to image size!
fiducialpos = zeros(4,2);
points = zeros(488,648,4);
length = mm_to_tick(69.6);
width = mm_to_tick(44.476);

vid = videoinput('pointgrey', 1, 'F7_Mono8_648x488_Mode0');

% Get positions and images after 'Enter' is hit
for i = 1:4
    switch i
        case 1
            disp('Starting...')
        case 2
            stage_move_Ludl(ludl,[fiducialpos(1,1) fiducialpos(1,2)-length]);
        case 3
            stage_move_Ludl(ludl,[fiducialpos(1,1)-width fiducialpos(1,2)-length]);
        case 4
            stage_move_Ludl(ludl,[fiducialpos(1,1)-width fiducialpos(1,2)]);
    end
    disp(strcat('Locate Point',num2str(i)))
    preview(vid);
    pause;
    stoppreview(vid);
    frame = getsnapshot(vid);
    imwrite(frame,strcat('im',num2str(i),'.tif'));
    points(1:end,1:end,i) = frame;
    fiducialpos(i,1) = stage_get_pos_Ludl(ludl).Pos(1);
    fiducialpos(i,2) = stage_get_pos_Ludl(ludl).Pos(2);
end

% Convert points into uint8
points = uint8(points);