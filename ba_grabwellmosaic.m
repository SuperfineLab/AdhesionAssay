function mosaic = ba_grabwellmosaic(stage, Xpos, Ypos, exptime, fileout)
% BA_GRABWELLMOSAIC grabs a series of images to send to bead identification
%
% Usage: 
% mosaic = ba_grabwellmosaic(stage, Xpos, Ypos, exptime, fileout)
% 
% This function is responsible for acquiring a series of images located at
% Xpos & Ypos for an exposure time, exptime, in milliseconds. The images
% are stored in a matlab table object along with their prescibed and
% measured XY locations.
%
% Inputs
%    stage: pointer to ludl stage object
%    Xpos,Ypos: x and y locations in ludl stage coordinates
%    exptime: camera exposure time
%    fileout: output filename
%
% Output
%    mosaic: matlab table containing the fields PrescribedXY, ArrivedXY, 
%            and Image.
%

if nargin < 1 || isempty(scope)
    error('No scope object. Check to see if scope is running and/or use scope_open to connect first.');
end

if nargin < 2 || isempty(Xpos)
    error('Need X locations for frames.');
elseif nargin < 3 || isempty(Ypos)
    error('Need Y locations for frames.');
elseif size(Xpos) ~= size(Ypos)
    error('Size mismatch for X and Y position vectors.');
end

if nargin < 4 || isempty(exptime)
    exptime = 8; % [ms]
end

% Camera Setup
imaqmex('feature', '-previewFullBitDepth', true);
% vid = videoinput('pointgrey', 1, 'F7_Mono8_648x488_Mode0');
vid = videoinput('pointgrey', 2, 'F7_Raw16_1024x768_Mode2');
vid.ReturnedColorspace = 'grayscale';
% triggerconfig(vid, 'manual');
% vid.FramesPerTrigger = NFrames;

% Following code found in apps -> image acquisition
% More info here: http://www.mathworks.com/help/imaq/basic-image-acquisition-procedure.html
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

N = numel(Xpos);
PrescribedXY = [Xpos Ypos];

% (1) Move stage to beginning position.
logentry(['Microscope is collecting mosaic.']);


pause(2);
logentry('Starting collection...');

Image = cell(N, 1);
ArrivedXY = zeros(N,2);


for k = 1:N
    x = Xpos(k);
    y = Ypos(k);
    
    figure(f); 
    drawnow;

    logentry([' Moving to position X: ' num2str(x) ', Y: ' num2str(y) '. ']);
    stage_move_Ludl(stage, [x, y]);
    
    stout = stage_get_pos_Ludl(stage);
    ArrivedXY(k,:) = stout.Pos;
    logentry(['Arrived at position X: ' num2str(ArrivedXY(k,1)), ', Y: ' num2str(ArrivedXY(k,2)) '. ']);
    
    Image{k,1} = p.CData;

%     imwrite(im{k,1}, outfile);
%     logentry(['Frame grabbed to ' outfile '.']);
    
%     focus_score(k,1) = fmeasure(im{k,1}, 'GDER');
end

close(f);

mosaic = table(PrescribedXY, ArrivedXY, Image);
save(fileout, 'mosaic')
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
     headertext = [logtimetext 'ba_grabwellmosaic: '];
     
     fprintf('%s%s\n', headertext, txt);
     
     return