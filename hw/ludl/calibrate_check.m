function fiderror = calibrate_check(ludl, centers)

% Finds fiducial positions
fiderror = zeros(4,2);
pos = zeros(4,2);

% Get positions of the images after 'Enter' is hit
for i = 1:4
    stage_move_Ludl(ludl,centers(i,1:2));
    disp('Locate point')
    pause;
    pos(i,1) = stage_get_pos_Ludl(ludl).Pos(1);
    pos(i,2) = stage_get_pos_Ludl(ludl).Pos(2);
end

% Read in images and put them into a matrix
im1 = imread("imC1.tif");
im2 = imread("imC2.tif");
im3 = imread("imC3.tif");
im4 = imread("imC4.tif");
points = cat(3,im1,im2,im3,im4);

% Find the position error from the intended positions
for im = 1:size(points,3)
    [x, y] = image_center_find(points(:,:,im), pos(im,1), pos(im,2));
    xerror = x - centers(im,1);
    yerror = y - centers(im,2);
    fiderror(im,1) = xerror;
    fiderror(im,2) = yerror;
end