function varargout = ba_findfocus(scope, lohifocus, stepsize, exptime, saveimagesTF)
% BA_TESTAUTOFOCUS 
%
% [maxfocus, focustable] = ba_findfocus(scope, lohifocus, stepsize, exptime, saveimagesTF)
% first output argument is maximum focus value (no peak modeling yet)
% second output argment is

if nargin < 1 || isempty(scope)
    logentry('No scope object. Connecting to scope now...');
    try
        scope = scope_open;
        pause(3);
    catch
        error('No connection established. Is scope running?');
    end

end

if nargin < 2 || isempty(lohifocus)
    error('Need [low,high] locations for focus. Try [20000 40000].');
end

if nargin < 3 || isempty(stepsize)
    error('Need distance between frames. Try 500.');
end

if nargin < 4 || isempty(exptime)
    exptime = 8; % [ms]
end

if nargin < 5 || isempty(saveimagesTF)
    saveimagesTF = false;
end

% Camera Setup
CameraName = 'Grasshopper3';
% CameraFormat = 'F7_Raw16_2048x1536_Mode7';
CameraFormat = 'F7_Raw16_1024x768_Mode2';
ExposureTime = exptime;
Video = flir_config_video(CameraName, CameraFormat, ExposureTime);
[cam, src] = flir_camera_open(Video);
vidRes = cam.VideoResolution;
imageRes = fliplr(vidRes);


f = figure;%('Visible', 'off');
pImage = imshow(uint16(zeros(imageRes)));


axis image
setappdata(pImage, 'UpdatePreviewWindowFcn', @ba_pulloffview)
p = preview(cam, pImage);
set(p, 'CDataMapping', 'scaled');


% ----------------
% Controlling the Hardware and running the experiment
%
focus_locations = [ min(lohifocus) : stepsize : max(lohifocus) ];
N = numel(focus_locations);

% (1) Move stage to beginning position.
startingFocus = scope_get_focus(scope);
logentry(['Microscope is currently at ' num2str(startingFocus)]);
pause(2);

% Start one step below the minimum so that we are always approaching from
% the same direction (help mitigate backlash in the z/focus motor)
scope_set_focus(scope, focus_locations(1) - stepsize);

logentry('Starting collection...');

im = cell(N, 1);
arrived_locs = zeros(N,1);
focus_score = zeros(N,1);

for k = 1:N
    this_focus = focus_locations(k);
    
    figure(f); 
    drawnow;

    logentry(['Moving scope to step' num2str(k) ' located at ' num2str(this_focus) '. ']);
    scope_set_focus(scope, this_focus);    
    arrived_locs(k,1) = scope_get_focus(scope);
    logentry(['Focus location: ' num2str(arrived_locs(k,1))]);
    
    im{k,1} = p.CData;
    outfile = ['focus', num2str(k, '%03i'), '.png'];
    if saveimagesTF
        imwrite(im{k,1}, outfile);
    end
    logentry(['Frame grabbed to ' outfile '.']);
    
    focus_score(k,1) = fmeasure(im{k,1}, 'GDER');
end

close(f);

varargout{1} = focus_locations( focus_score == max(focus_score) );
varargout{2} = table(im, arrived_locs, focus_score);
logentry('Done!');

return


% function for writing out stderr log messages
function logentry(txt)
    logtime = clock;
    logtimetext = [ '(' num2str(logtime(1),  '%04i') '.' ...
                   num2str(logtime(2),        '%02i') '.' ...
                   num2str(logtime(3),        '%02i') ', ' ...
                   num2str(logtime(4),        '%02i') ':' ...
                   num2str(logtime(5),        '%02i') ':' ...
                   num2str(floor(logtime(6)), '%02i') ') '];
     headertext = [logtimetext 'ba_testautofocus: '];
     
     fprintf('%s%s\n', headertext, txt);
     
     return