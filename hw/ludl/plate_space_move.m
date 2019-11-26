%function plate_space_move(centers, wellcor)
function plate_space_move(centers)

% centers - location of center of fiducial marks
%
% wellcor - well location on the well location grid (ex. [1 1] for the top
% left well nearest to fiducial mark 1)

% Define origin as the location of fiducial mark 1 (top leftmost) in ludl coordinates
origin = centers(1,1:2);


   1.2074e+05

% Defining distances in mm
well_one_cent_x = 11.216;
well_one_cent_y = 6.037;
interwell_dist_x = 11.79; 
interwell_dist_y = 16.2;

% Convert mm to ticks
well_one_x_tick = mm_to_tick(well_one_cent_x);
well_one_y_tick = mm_to_tick(well_one_cent_y);
interwell_x_tick = mm_to_tick(interwell_dist_x);
interwell_y_tick = mm_to_tick(interwell_dist_y);

% Find sine and cosine values based off of fiducial mark positions
sin_theta = 

% Move the stage accordingly
%ludl = stage_open_ludl();
% stage_move_Ludl(ludl,[origin(1) origin(2)])