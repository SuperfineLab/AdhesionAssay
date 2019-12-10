function fiderror = calibrate_check(ludl, centers)

% Finds fiducial positions
% WARNING: Adjust 'points' according to image size!
fiderror = zeros(4,2);
pos = zeros(4,2);
points = zeros(488,648,4);
vid = videoinput('pointgrey', 1, 'F7_Mono8_648x488_Mode0');

% Get positions of the images after 'Enter' is hit
for i = 1:4
    stage_move_Ludl(ludl,centers(i,1:2));
    disp('Locate point')
    pause;
    frame = getsnapshot(vid);
    imwrite(frame,strcat('imC',num2str(i),'.tif'));
    points(1:end,1:end,i) = frame;
    pos(i,1) = stage_get_pos_Ludl(ludl).Pos(1);
    pos(i,2) = stage_get_pos_Ludl(ludl).Pos(2);
end

% % Read in images and put them into a matrix
% im1 = imread("imC1.tif");
% im2 = imread("imC2.tif");
% im3 = imread("imC3.tif");
% im4 = imread("imC4.tif");
% points = cat(3,im1,im2,im3,im4);

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