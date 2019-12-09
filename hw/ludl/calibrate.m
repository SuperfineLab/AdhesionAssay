function [centers, errormatrix] = calibrate(ludl)

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

% % Creat error matrix of side lengths, order sides as NSEW, with top length as "North"
% length = 1000;
% width = 1000;
% errormatrix = zeros(4,2);
% 
% % Finds error in tick marks (col 1)
% errormatrix(1,1) = abs(centers(1:1)-centers(2:1)) - length;
% errormatrix(2,1) = abs(centers(4:1)-centers(3:1)) - length;
% errormatrix(3,1) = abs(center(2:2)-centers(3:2)) - width;
% errormatrix(4,1) = abs(centers(1:2)-centers(4:2)) - width;
% 
% % Finds percent error (col 2)
% errormatrix(1,2) = errormatrix(1,1)/length * 100;
% errormatrix(2,2) = errormatrix(2,1)/length * 100;
% errormatrix(3,2) = errormatrix(3,1)/width * 100;
% errormatrix(4,2) = errormatrix(4,1)/width * 100;