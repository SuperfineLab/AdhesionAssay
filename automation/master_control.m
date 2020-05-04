function master_control
% MASTER_CONTROL runs an experiment for a given plate once

%% Setup
% Open the stage, scope, zhand connections
stage = stage_open_Ludl(); % TODO: Check connections are actually open!
scope = scope_open();
h = ba_initz('Artemis');

% Turn on brightfield lamp
if scope_get_lamp_state(scope) == 0
    scope_set_lamp_state(scope,1);
end

% Check that LED lamp is on
disp('Confirm that the LED lamp on, then press Enter to continue');
pause;

% Calibrate stage
centers = calibrate(stage);

%% Data Collection
% Loop that runs ba_pulloff_auto for each well (assuming one test per well)
for k = 1:num
    
    % Setup rows/columns for given well
    row = 1+floor((k-1)/5);
    col = 1+mod((k-1),5);
    wellcor = [row col];
    plate_space_move(stage, centers, wellcor);
    
    % JON'S ALGORITHM SEARCHING CODE GOES HERE!
    
    % Setup inputs for ba_pulloff_auto
    filename = strcat('w',num2str(k)); % Rename as appropriate
    exptime = 8;
    metafile = well_metadata_script(row,col); % 'filename' should be the same between well_metadata_script and here
    
    % Run ba_pulloff_auto
    ba_pulloff_auto(h, filename,exptime, metafile);
end

%% Cleaning Up
% Turn off lights
if scope_get_lamp_state(scope) == 1:
    scope_set_lamp_state(scope,0);
end

% Prompt to turn LED lamp off
disp('Turn LED lamp off, then press Enter to continue');
pause;

% Close the stage and scope connections
stage_close(stage);
scope_close(scope);