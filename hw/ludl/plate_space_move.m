function plate_space_move(centers, wellcor)

% centers - location of center of fiducial marks
%
% wellcor - well location on the well location grid (ex. [1 1] for the top
% left well nearest to fiducial mark 1)

% Define origin as the location of fiducial mark 1 (top leftmost) in ludl coordinates
origin = centers(1,1:2);

% Defining distances in mm
% Note: x and y are reversed and both negative
well_one_cent_x = 6.037;
well_one_cent_y = 11.216;
interwell_dist_x = 16.2;
interwell_dist_y = 11.79; 


% Convert mm to ticks
well_one_x_tick = mm_to_tick(well_one_cent_x);
well_one_y_tick = mm_to_tick(well_one_cent_y);
interwell_x_tick = mm_to_tick(interwell_dist_x);
interwell_y_tick = mm_to_tick(interwell_dist_y);

% Find moving distance
dist_x = -(well_one_x_tick + (wellcor(1) - 1) * interwell_x_tick);
dist_y = -(well_one_y_tick + (wellcor(2) - 1) * interwell_y_tick);

% TODO: Find correction factor

% Move the stage accordingly
% Note: x and y are reversed
ludl = stage_open_Ludl();
stage_move_Ludl(ludl,[(origin(1) + dist_x) (origin(2) + dist_y)]);