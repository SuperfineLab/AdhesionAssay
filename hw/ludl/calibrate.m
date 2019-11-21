function fiducialcenters = calibrate()

% Finds fiducial positions
fiducialcenters = zeros(4,2);
[pos, points] = fiducial_position_array;

% Finds the ludl coordinates that would place the fiducial center in the
% center of the image
for im = 1:size(points,3)
    [x, y] = image_center_find(points(:,:,im), pos(im,1), pos(im,2));
    fiducialcenters(im,1) = x;
    fiducialcenters(im,2) = y;
end