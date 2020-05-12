function outs = ba_focusplate(scope, ludl, plate, stepsize, exptime)
% BA_FOCUSPLATE
%

if nargin < 1 || isempty(scope)
    logentry('No scope object. Connecting to scope now...');
    try
        scope = scope_open;
        pause(3);
    catch
        error('No connection established. Is scope running?');
    end

end

% if nargin < 2 || isempty(lohifocus)
%     error('Need [low,high] locations for focus. Try [20000 40000].');
% end

if nargin < 4 || isempty(stepsize)
    error('Need distance between frames. Try 500.');
end

if nargin < 5 || isempty(exptime)
    exptime = 8; % [ms]
end

% [centers, errormatrix, theta] = ba_calibrate_plate(ludl);
centers = plate.calib.centers;

% Camera Setup
imaqmex('feature', '-previewFullBitDepth', true);
vid = videoinput('pointgrey', 1, 'F7_Mono8_648x488_Mode0');
vid.ReturnedColorspace = 'grayscale';

src = getselectedsource(vid); 
src.ExposureMode = 'off'; 
src.FrameRateMode = 'off';
src.ShutterMode = 'manual';
src.Gain = 10;
src.Gamma = 1.15;
src.Brightness = 5.8594;
src.Shutter = exptime;

vidRes = vid.VideoResolution;

imageRes = fliplr(vidRes);


f = figure;%('Visible', 'off');
pImage = imshow(uint16(zeros(imageRes)));

axis image
setappdata(pImage, 'UpdatePreviewWindowFcn', @ba_pulloffview)
p = preview(vid, pImage);
set(p, 'CDataMapping', 'scaled');


% ----------------
% Controlling the Hardware and running the experiment
%
plate_space_move(ludl, centers, [1 1]);
disp('Optimize focus manually and press any key to continue.');
pause;

focus_start = scope_get_focus(scope);
lohifocus = [focus_start-5000 focus_start+5000];
focus_locations = [ min(lohifocus) : stepsize : max(lohifocus) ];
N = numel(focus_locations);

% (1) Move stage to beginning position.
startingFocus = scope_get_focus(scope);
logentry(['Microscope is currently at ' num2str(startingFocus)]);


pause(2);
logentry('Starting collection...');

im = cell(N, 1);
arrived_locs = zeros(N,4);
focus_score = zeros(N,4);

corners = [1 1; 1 5; 3 1; 3 5]; % well coordinates for the plate corners
for c = 1:4
    plate_space_move(ludl, centers, corners(c,:));
    pause(5);
    for k = 1:N
        this_focus = focus_locations(k);

        figure(f); 
        drawnow;

        logentry(['Moving scope to step ' num2str(k) ' located at ' num2str(this_focus) '. ']);
        scope_set_focus(scope, this_focus);   
        
        arrived_locs(k,c) = scope_get_focus(scope);
        logentry(['Focus location: ' num2str(arrived_locs(k,1))]);

        im{k,c} = p.CData;
        outfile = ['corner-' num2str(c) 'focus-', num2str(k, '%03i'), '.png'];
        imwrite(im{k,c}, outfile);
        logentry(['Frame grabbed to ' outfile '.']);

        focus_score(k,c) = fmeasure(im{k,c}, 'GDER');
    end
end

close(f);

outs = table(im, arrived_locs, focus_score);

figure; 
plot(outs.arrived_locs, outs.focus_score);
legend('TL', 'TR', 'BL', 'BR');
xlabel('Focus location');
ylabel('Focus measure');

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
     headertext = [logtimetext 'ba_focusplate: '];
     
     fprintf('%s%s\n', headertext, txt);
     
     return