function [x_center y_center x_disp y_disp] = image_center_find(test, x_start, y_start)

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
[x y sx sy] = centerofmass(test);
hold on
plot(x,y,'or');

% Find pixel displacement from center and convert to ticks
x_disp = (635/2 - x) * - factor;
y_disp = (470/2 - y) * factor;

% Find coordinates for the center of the fiducial markings in ludl
% coordinates
x_center = x_start + x_disp;
y_center = y_start + y_disp;