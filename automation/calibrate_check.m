function fiderror = calibrate_check(ludl, plate)

% CALIBRATE_CHECK checks the calibration of the stage by moving to each fiducial 
% mark and calculating how far away they are from their calibration-determined
% coordinates

% Finds fiducial positions
% WARNING: Adjust 'points' according to image size!
fiderror = zeros(4,2);
pos = zeros(4,2);
points = zeros(488,648,4);
vid = videoinput('pointgrey', 1, 'F7_Mono8_648x488_Mode0');

centers = plate.calib.centers;

% Takes images of each of the four fiducial marks and finds their centers
% in ludl tickmarks
for i = 1:4
    stage_move_Ludl(ludl,centers(i,1:2));
    disp('Locate point')
    frame = getsnapshot(vid);
    imwrite(frame,strcat('imC',num2str(i),'.tif'));
    points(1:end,1:end,i) = frame;
    pos(i,1) = stage_get_pos_Ludl(ludl).Pos(1);
    pos(i,2) = stage_get_pos_Ludl(ludl).Pos(2);
end

% Convert points into uint8
points = uint8(points);

% Find the position error from the intended positions
for im = 1:size(points,3)
    [x, y] = image_center_find(points(:,:,im), pos(im,1), pos(im,2));
    xerror = x - centers(im,1);
    yerror = y - centers(im,2);
    fiderror(im,1) = xerror;
    fiderror(im,2) = yerror;
end