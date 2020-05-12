function [x_center, y_center, x_disp, y_disp] = image_center_find(test, x_start, y_start)
% IMAGE_CENTER_FIND locates the center of each fiducial mark and determines 
% the ludl coordinates that the stage would need to be in such that the 
% center of each fiducial mark would be at the center of the image

% Define structuring element
SE = strel('disk', 14);
factor = 45;

% Binarize and erode/dilate image
test = test(10:end,10:645);
test = imbinarize(test);
test = imcomplement(test); 
test = imdilate(test,SE); 
test = imerode(test,SE); imshow(test)

% Find/plot center of mass
[x, y] = centerofmass(test);
hold on
plot(x, y, 'or');
hold off

% Find pixel displacement from center and convert to ticks
x_disp = (635/2 - x) * -factor;
y_disp = (470/2 - y) * factor;

% Find coordinates for the center of the fiducial markings in ludl
% coordinates
x_center = x_start + x_disp;
y_center = y_start + y_disp;