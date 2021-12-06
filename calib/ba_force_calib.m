function outs = ba_force_calib(filename, hw, viewOps, collect_position, duration)

ludl = hw.ludl;

if nargin < 1 || isempty(filename)
    error('Need a filename.');
end

if nargin < 2 || isempty(hw)
    error('Need a hardware input structure.');
end

if nargin < 3 || isempty(viewOps)
    viewOps.focusTF = false;
    viewOps.cmin = 3500;
    viewOps.cmax = 65535;
    viewOps.exptime = 8;
end

if nargin < 4 || isempty(collect_position)
    error('Please provide the ludl stage position, i.e. where the capillary is "engaged" with the magnet.');
end

if nargin < 5 || isempty(duration)
    error('Please provide duration.');
end


% Record current Ludl stage position as a "safe" location, meaning that the
% capillary tube is not subjected to sufficent magnetic forces to be an
% issue.
safe_pos = stage_get_pos_Ludl(ludl);


% Move capillary to inputted stage position
stage_move_Ludl(hw.ludl,collect_position.Pos);


% Wait/delay for settling time (vibrating cantilever, free fluid, etc
% pause(0.1);

% collect video
Video = flir_config_video('Grasshopper3', 'F7_Raw16_1024x768_Mode2', viewOps.exptime);
ba_collect_video(filename, Video, duration);

% Return capillary to starting position (deemed as safe)
safe_pos = stage_move_Ludl(hw.ludl,safe_pos.Pos);

% switch to brightfield and take an image to identify location of pole tip
% and capillary.


outs = 0;


return