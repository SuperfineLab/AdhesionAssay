function mosaic = ba_grabwellmosaic(stage, calib, wellrc, exptime, fileout)
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

if nargin < 1 || isempty(stage)
    error('No stage object. Check to see if scope is running and/or use scope_open to connect first.');
end

if nargin < 2 || isempty(calib)
    error('Need stage/plate calibration.');
end

if nargin < 3 || isempty(wellrc)
    error('Need Well locations for frames.');
end

if nargin < 4 || isempty(exptime)
    exptime = 8; % [ms]
end

% % Artemis, 4x objective, 1x multiplier, ~40% overlap = interval 0.5 mm
% Xlocs = [-3 : 0.5 : 3];
% Ylocs = [-3 : 0.5 : 3]';
%

% % % % Artemis calib_4x_2048x1536 = 0.858 [um/pix], 10% overlap = 1.6x1.32 [mm] interval
% % Xlocs = [-3*1.58 : 1.58 : 3*1.58];
% % Ylocs = [-3*1.32 : 1.32 : 3*1.32]';
% Xlocs = [-10*1.58 : 1.58 : 10*1.58]; 
% Ylocs = [-10*1.32 : 1.32 : 10*1.32]';
% Xlocs = linspace(-3.15, 3.15, 11);
% Ylocs = transpose(linspace(-3.15, 3.15, 11));

% % Artemis, 4x objective, 1x multiplier, 1024x768, 0.583 um/pix, 3% overlap = interval 0.579 mm
% Xlocs = [-6*0.579 : 0.579 : 6*0.579];
% Ylocs = [-6*0.434  : 0.434  : 6*0.434]';


% Artemis, 10x objective, 1x multiplier, 2048x1536, 0.346 um/pix, 3% overlap = interval 0.687 mm
Xlocs = [-6*0.6873 : 0.6873 : 6*0.6873];
Ylocs = [-6*0.515  : 0.515  : 6*0.515]';

% % % % Artemis, 10x objective, 1x multiplier, 1024x768, 0.692 um/pix, 3% overlap = interval 0.687 mm
% % Xlocs = [-25*0.6873 : 0.6873 : 25*0.6873];
% % Ylocs = [-25*0.515  : 0.515  : 25*0.515]';


% Xlocs = linspace(-3.15, 3.15, 11);
% Ylocs = transpose(linspace(-3.15, 3.15, 11));

Xmat = repmat(Xlocs, size(Ylocs,1), 1)';
Ymat = repmat(Ylocs, 1, size(Xlocs,2))';
Xlocs = Xmat(:);
Ylocs = Ymat(:);

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

N = numel(Xlocs);
PrescribedXY = [Xlocs Ylocs];

% (1) Move stage to beginning position.
logentry(['Microscope is collecting mosaic.']);


pause(2);
logentry('Starting collection...');

Image = cell(N, 1);
ArrivedXY = zeros(N,2);


for k = 1:N
    x = Xlocs(k);
    y = Ylocs(k);
    
    figure(f); 
    drawnow;

    logentry([' Moving to position X: ' num2str(x) ', Y: ' num2str(y) '. ']);
%     stage_move_Ludl(stage, [x, y]);
    plate_space_move(stage, calib, wellrc, [x y]);
    
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