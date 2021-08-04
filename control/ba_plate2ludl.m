function xyLudl_ticks = ba_plate2ludl(ludl, cal, xyWellCoord, xyOffset_mm, platelayout)
% BA_PLATE2LUDL converts plate locations to Ludl coords given a calibration
%

% ludl - handle to ludl stage
% cal - output from stage_center
%
% wellcor - well location on the well location grid in the format [row_num 
% column_num] (ex. [1 1] for the top left well nearest to fiducial mark 1)
%
% movegrid - an optional parameter which indicates where the view should
% be moved relative to the center of the well in units of millimeters

% Selecting Well-Layout
if nargin < 5 || isempty(platelayout)
    platelayout = '15v2';
end

if nargin < 4 || isempty(xyOffset_mm)
    xyOffset_mm = [0 0];
end

if numel(xyWellCoord) == 1
    xyWellCoord = ba_wellnum2rc(xyWellCoord);
end

% Note: For distances x and y are reversed and both negative when written in 
% Ludl space. Distances are in units of mm.
switch platelayout
    case '15v1' % nunc spec.
%         plate.well_one_center = [14.32 11.25];
        plate.well_one_center = [7.2 10.9];
        plate.interwell_dist = [16.2, 11.79];
    case '15v2'
        plate.well_one_center = [5.4, 5.4];
        plate.interwell_dist  = [16.2, 11.79];
        
end

% % Determining Distances
[cid, rid] = meshgrid(1:5,1:3);

x_centers = transpose(plate.well_one_center(1) + plate.interwell_dist(1) * (cid-1));
y_centers = transpose(plate.well_one_center(1) + plate.interwell_dist(2) * (rid-1));

% well_centers_platespace_ticks = [x_centers(:) y_centers(:)];
% center = calib.center;

theta = cal.theta;

% Convert mm to ticks
well_one_tick = mm2tick(plate.well_one_center);
interwell_tick = mm2tick(plate.interwell_dist);

% Define origin as the location of top-left edge of the nunc plate
PlateOrigin = cal.centers(1,:);


% Find moving distance
dist_x = -(well_one_tick(1) + (xyWellCoord(1) - 1) * interwell_tick(1));
dist_y = -(well_one_tick(2) + (xyWellCoord(2) - 1) * interwell_tick(2));


% Correction factors due to stage xy rotation
xcor = abs(dist_y) * sin(theta);
ycor = abs(dist_x) * sin(theta);

% Find moving distance
dist_x = dist_x + xcor;
dist_y = dist_y - ycor;

% Convert offsets to ticks. Remember x and y are reversed between plate and
% ludl coordinate systems
xyOffset_ticks = mm2tick(fliplr(xyOffset_mm));

xyLudl_ticks = [PlateOrigin(1) + dist_x - xyOffset_ticks(1), ...
                PlateOrigin(2) + dist_y - xyOffset_ticks(2)];

return

