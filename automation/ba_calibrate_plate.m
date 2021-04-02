function outs = ba_calibrate_plate(ludl)
% BA_CALIBRATE_PLATE uses the fiducial marking images taken by the camera and the
% location of the stage in ludl coordinates at that location to calculate
% the location of the sample on the ludl stage

% % 15 well plate version 1 (meganp)
% plate_length_mm = 69.6;
% plate_width_mm = 44.476;

% 15 well plate version 2 (wollensack)
plate_length_mm = 57.96;
plate_width_mm = 43.2;

plate_length_ticks = mm2tick(plate_length_mm);
plate_width_ticks = mm2tick(plate_width_mm);

% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.
[pos, imstack] = fiducial_position_array(ludl);

% Finds the ludl coordinates that would place the fiducial center in the
% center of the image
for k = 1:size(imstack,3)
    [x,y] = image_center_find(imstack(:,:,k), pos(k,1), pos(k,2));
    outs.centers(k,1) = x;
    outs.centers(k,2) = y;
end

% Find the angle of tilt in radians
Ftop_leftXY = outs.centers(1,:);
Ftop_rightXY = outs.centers(2,:);
Fbottom_rightXY = outs.centers(3,:);
Fbottom_leftXY = outs.centers(4,:);

outs.theta = atan(abs(Ftop_rightXY(1) - Ftop_leftXY(1))/abs(Ftop_rightXY(2) - Ftop_leftXY(2)));

% Create error matrix of side lengths, order sides as NSEW, with top length as "North"
errormatrix = zeros(4,2);

% Finds error in tick marks (col 1)
errormatrix(1,1) = pdist([Ftop_leftXY;Ftop_rightXY]) - plate_length_ticks;
errormatrix(2,1) = pdist([Fbottom_rightXY;Fbottom_leftXY]) - plate_length_ticks;
errormatrix(3,1) = pdist([Ftop_rightXY;Fbottom_rightXY]) - plate_width_ticks;
errormatrix(4,1) = pdist([Ftop_leftXY;Fbottom_leftXY]) - plate_width_ticks;

% Finds percent error (col 2)
errormatrix(1,2) = errormatrix(1,1)/plate_length_ticks * 100;
errormatrix(2,2) = errormatrix(2,1)/plate_length_ticks * 100;
errormatrix(3,2) = errormatrix(3,1)/plate_width_ticks * 100;
errormatrix(4,2) = errormatrix(4,1)/plate_width_ticks * 100;

outs.errormatrix = errormatrix;

