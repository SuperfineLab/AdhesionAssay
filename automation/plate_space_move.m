function plate_space_move(ludl, plate, wellcor, movegrid_plate, platelayout)
% PLATE_SPACE_MOVE moves to the center of a given well

% centers - location of center of fiducial marks
%
% wellcor - well location on the well location grid in the format [row_num 
% column_num] (ex. [1 1] for the top left well nearest to fiducial mark 1)
%
% movegrid - an optional parameter which indicates where the view should
% be moved relative to the center of the well in units of millimeters

%% Selecting Well-Layout

% Note: For distances x and y are reversed and both negative when written in 
% Ludl space. Distances are in units of mm.

switch platelayout
    case 1  % Phase 1 case
        well_one_cent = [6.037 11.216];
        interwell_dist = [16.2 11.79];
    case 2  % Phase 2 case
        well_one_cent = [4.24 7.8];
        interwell_dist = [9.0 9.0];
end

%% Determining Distances

centers = plate.calib.centers;
theta = plate.calib.theta;

% Define origin as the location of fiducial mark 1 (top leftmost) in ludl coordinates
origin = centers(1,:);

% Defining distances in mm
% Note: x and y are reversed and both negative -> written in Ludl
% coordinates
% well_one_cent_x = 6.037;
% well_one_cent_y = 11.216;
% interwell_dist_x = 16.2;
% interwell_dist_y = 11.79; 

% Convert mm to ticks
% well_one_x_tick = mm2tick(well_one_cent_x);
% well_one_y_tick = mm2tick(well_one_cent_y);
% interwell_x_tick = mm2tick(interwell_dist_x);
% interwell_y_tick = mm2tick(interwell_dist_y);
well_one_tick = mm2tick(well_one_cent);
interwell_tick = mm2tick(interwell_dist);

% Find moving distance
% dist_x = -(well_one_x_tick + (wellcor(1) - 1) * interwell_x_tick);
% dist_y = -(well_one_y_tick + (wellcor(2) - 1) * interwell_y_tick);
dist_x = -(well_one_tick(1) + (wellcor(1) - 1) * interwell_tick(1));
dist_y = -(well_one_tick(2) + (wellcor(2) - 1) * interwell_tick(2));


% Correction factor in x direction

xcor = abs(dist_y) * sin(theta);
ycor = abs(dist_x) * sin(theta);


% Find moving distance
dist_x_final = dist_x + xcor;
dist_y_final = dist_y - ycor;

% Move the stage accordingly
% Note: x and y are reversed

if nargin < 4 || isempty(movegrid_plate)
    movegrid_plate = [0 0];
end

movegrid_ludl = plate2ludl(movegrid_plate);

stage_move_Ludl(ludl,[(origin(1) + dist_x_final + movegrid_ludl(1)) (origin(2) + dist_y_final) + movegrid_ludl(2)]);