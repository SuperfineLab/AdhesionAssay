function [centers, theta, errormatrix] = ba_calibrate_plate(ludl)
% BA_CALIBRATE_PLATE uses the fiducial marking images taken by the camera and the
% location of the stage in ludl coordinates at that location to calculate
% the location of the sample on the ludl stage

% Finds fiducial positions
centers = zeros(4,2);
[pos, points] = fiducial_position_array(ludl);

% Finds the ludl coordinates that would place the fiducial center in the
% center of the image
for im = 1:size(points,3)
    [x, y] = image_center_find(points(:,:,im), pos(im,1), pos(im,2));
    centers(im,1) = x;
    centers(im,2) = y;
end

% Find the angle of tilt in radians
theta = atan(abs(centers(2,1)-centers(1,1))/abs(centers(2,2)-centers(1,2)));

% Creat error matrix of side lengths, order sides as NSEW, with top length as "North"
length = mm2tick(69.6);
width = mm2tick(44.476);
errormatrix = zeros(4,2);

% Finds error in tick marks (col 1)
errormatrix(1,1) = pdist([centers(1,1:2);centers(2,1:2)]) - length;
errormatrix(2,1) = pdist([centers(3,1:2);centers(4,1:2)]) - length;
errormatrix(3,1) = pdist([centers(2,1:2);centers(3,1:2)]) - width;
errormatrix(4,1) = pdist([centers(1,1:2);centers(4,1:2)]) - width;
 
% Finds percent error (col 2)
errormatrix(1,2) = errormatrix(1,1)/length * 100;
errormatrix(2,2) = errormatrix(2,1)/length * 100;
errormatrix(3,2) = errormatrix(3,1)/width * 100;
errormatrix(4,2) = errormatrix(4,1)/width * 100;