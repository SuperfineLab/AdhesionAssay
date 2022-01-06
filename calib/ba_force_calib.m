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
    viewOps.gain = 15;
end

if nargin < 4 || isempty(collect_position)
    error('Please provide the ludl stage position, i.e. where the capillary is "engaged" with the magnet.');
end

if nargin < 5 || isempty(duration)
    error('Please provide duration.');
end


% check for open impreview window
h = findobj('Name', 'vid_impreview');
if ~isempty(h)
    logentry('Found open preview window. Closing.')
    close(h);
    pause(0.1);
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
Video.Gain = viewOps.gain

ba_collect_video(filename, Video, duration);

% Return capillary to starting position (deemed as safe)
safe_pos = stage_move_Ludl(hw.ludl,safe_pos.Pos);

% switch to brightfield and take an image to identify location of pole tip
% and capillary.

% If we had a preview, restore it once we're done collecting data
if ~isempty(h)
    ba_impreview(hw, viewOps);
end

outs = 0;


return