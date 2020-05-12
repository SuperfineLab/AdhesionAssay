function master_control(plate_filename)
% MASTER_CONTROL runs an experiment for a given plate once

%-- Setup

% Constants
ON = 1; OFF = 0;

% (1) Load metadata 
Scope  = ba_config_scope('Artemis');
Video  = ba_config_video('Grasshopper3');
Zmotor = ba_config_zmotor('Z25B');
Plate  = ba_read_plate_layout(plate_filename);


% (2) Create experiment manifest
visit_list = ba_well_visitorder(Plate, 'sorted');
N = numel(visit_list);

% Initialize hardware by opening the stage, scope, and z-motor connections
logentry('Connecting to Ludl stage...');
Ludl = stage_open_Ludl(); % TODO: Check connections are actually open!

logentry('Connecting to Nikon scope...');
scope = scope_open();

logentry('Connecting to Thorlabs Z-motor...')
h = ba_initz('Artemis');

% Turn on brightfield lamp
if scope_get_lamp_state(scope) == OFF
    logentry('Turning ON brightfield lamp.');
    scope_set_lamp_state(scope, ON);
end

% Calibrate stage
logentry('Calibrating Ludl Stage...');
Plate.calibration = ba_calibrate_plate(Ludl);

% Turn off lights
if scope_get_lamp_state(scope) == ON
    logentry('Turning OFF brightfield lamp.');
    scope_set_lamp_state(scope, OFF);
end

% Check that LED lamp is on
logentry('Beginning automated data collection.')
logentry('Turn ON the LED lamp, then PRESS ANY KEY to continue');
pause;

% Focus whole plate at one time by focusing the corners
logentry('Focusing Plate. This may take a few minutes.')
focus_metric = ba_focusplate(Scope, Ludl, Plate, 500, 8);
if max(focus_metric) > 5 * (min(focus_metric))
end

%
% % --*** Data Collection ***---
%
% Loop that runs ba_pulloff_auto for each well (assuming one test per well)
for k = 1:N
    
    mywell = visit_list(k);
    
    % Setup rows/columns for given well
    row = 1+floor((mywell-1)/5);
    col = 1+mod((mywell-1),5);
    wellcor = [row col];    

    logentry('Moving Stage to center of well (1,1) ...');
    plate_space_move(Ludl, plate, [1 1]);
    
    % JON'S ALGORITHM SEARCHING CODE GOES HERE!
    % 
    % 

    
    
    % Setup inputs for ba_pulloff_auto
    filename = strcat('w', num2str(k)); % Rename as appropriate
    exptime = 8;
%     metafile = well_metadata_script(row,col); % 'filename' should be the same between well_metadata_script and here
    
    % Run ba_pulloff_auto
    logentry('Collecting data for well XXX');
%     ba_pulloff_auto(h, filename,exptime, metafile);
end

%-- Cleaning Up


% Prompt to turn LED lamp off
disp('Turn OFF the LED lamp, then PRESS ANY KEY to continue');
pause;

% Close the stage and scope connections
logentry('Closing connection to Ludl stage...');
% stage_close(stage);
logentry('Closing connectino to Nikon scope...');
% scope_close(scope);

