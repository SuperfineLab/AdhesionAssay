function [fiducialpos, points] = fiducial_position_array(ludl)
% Note: Images must be taken before hitting 'Enter' and named accordingly

fiducialpos = zeros(4,2);

% Get positions of the images after 'Enter' is hit
for i = 1:4
    disp('Locate point')
    pause;
    fiducialpos(i,1) = stage_get_pos_Ludl(ludl).Pos(1);
    fiducialpos(i,2) = stage_get_pos_Ludl(ludl).Pos(2);
end

% Read in images and put them into a matrix
im1 = imread("im1.tif");
im2 = imread("im2.tif");
im3 = imread("im3.tif");
im4 = imread("im4.tif");
points = cat(3,im1,im2,im3,im4);