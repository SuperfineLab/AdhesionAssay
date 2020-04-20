function ba_pulloff_auto(zhand, filename,exptime, metafile)
% BA_PULLOFF_AUTO(zhand,filename,exptime,metafile) lowers the magnet at a
% given location and records a video as a .bin file for a specific duration

% Prior to starting experiment, make sure the magnet is centered.  Lower
% the magnet to 0 and use the vertical micrometer to ensure the tips of the
% magnet will touch the top of a glass slide (to apply maximum force to
% bead).  Click on the apps tab and open image acquisition.  Use the
% horizontal micrometers to line up the magnet gap with the field of view.
% If done correctly, you will not see the tips of the magnets show up.  You
% may have to adjust the focus and increase the gain to see the gap with
% fluorescence.  Close image acquisition, then run the first two sections
% of this script.  Raise the motor back to 12mm by clicking the height box
% in the gui and typing the desired height.  Carefully place the sample
% under the magnet, making sure the magnet will not contact and edge of the
% chamber when it is lowered.  Close the gui, then reopen image acqusition.
% Find a region that has 20-40 beads.  Beads within a diameter from
% each other or an edge will probably not work well when tracking. Focus the region, then
% close image acquisition again.  Run the script.

%% Checking for empty inputs

if nargin < 1 || isempty(zhand)
    disp('No z-controller object. Connecting to z-motor now...');
    try
        zhand = ba_initz;
    catch
        error('No connection. Is motor connected and running?');
    end
    disp('Connected.');
end

if nargin < 2 || isempty(filename)
    error('Need file name.')
end

if nargin < 4 || isempty(metafile)
    error('Need metafile.');
end

if nargin < 3 || isempty(exptime)
    exptime = 8; % [ms]
end

%% Import metadata
% Note: metafile should be a .m file generated using the
% WELL_METADATA_SCRIPT function

m = load(metafile);


%% Setting Parameters

% Zmotor Parameters
starting_height = m.Zmotor.StartingHeight;
motor_velocity = m.Zmotor.Velocity; % [mm/sec]
abstime{1,1} = [];
framenumber{1,1} = [];
TotalFrames = 0;
znow = starting_height;

% Following code found in apps -> image acquisition
% More info here: http://www.mathworks.com/help/imaq/basic-image-acquisition-procedure.html
vid = videoinput('pointgrey', 1, 'F7_Mono8_648x488_Mode0');
src = getselectedsource(vid); 
src.ExposureMode = m.Video.ExposureMode; 
src.FrameRateMode = m.Video.FrameRateMode;
src.ShutterMode = m.Video.ShutterMode;
src.Gain = m.Video.Gain;
src.Gamma = m.Video.Gamma;
src.Brightness = m.Video.Brightness;
src.Shutter = exptime;

%% Old code

PSF_filename = m.Bead.PointSpreadFunctionFilename;
impsf = imread(PSF_filename);

Name = {'Lactose', 'Galactose', 'GalNAc', 'GlcNac', 'Sialic Acid', 'PEG20k'}';
Conc = {0.0365, 0.0365, 0.0365, 0.0365, 0.0365, 0.2}';
ConcUnits = {'mol/L', 'mol/L', 'mol/L', 'mol/L', 'mol/L', 'mass fraction'}';
Int25k = table(Name, Conc, ConcUnits);
clear Name Conc ConcUnits

Name = {'PEG20k'}';
Conc = {0.2}';
ConcUnits = {'mass fraction'}';
NoInt = table(Name, Conc, ConcUnits);
clear Name Conc ConcUnits

Nsec = starting_height/motor_velocity + 1;
Fps = 1 / (exptime/1000);
% NFrames = ceil(Fps * Nsec);
% NFrames = 7625;
NFrames = 40; % Originally 1800

imaqmex('feature', '-previewFullBitDepth', true);
vid.ReturnedColorspace = 'grayscale';
triggerconfig(vid, 'manual');
vid.FramesPerTrigger = NFrames;

vidRes = vid.VideoResolution;
frame = getsnapshot(vid);
imagetype = class(frame);

imageRes = fliplr(vidRes);

filename_vid = [filename, '_', num2str(vidRes(1)), 'x', ...
                           num2str(vidRes(2)), 'x', ...
                           num2str(NFrames), '_', imagetype];

f = figure;%('Visible', 'off');
if strcmp(class(frame),'uint8')
    pImage = imshow(uint8(zeros(imageRes)));
elseif strcmp(class(frame),'uint16')
    pImage = imshow(uint16(zeros(imageRes)));
else
    disp(':(')
end
pImage.UserData = znow;

axis image
setappdata(pImage, 'UpdatePreviewWindowFcn', @ba_pulloffview)
p = preview(vid, pImage);
set(p, 'CDataMapping', 'scaled');

%% Controlling the Hardware and running the experiment
%

pause(2);
logentry('Starting video...');
start(vid);
pause(2);

NFramesAvailable = 0;

% XXX TODO: Change bin filename to include frame width, height, depth, Nframes
binfilename = [filename_vid,'.bin'];
if ~isempty(dir(binfilename))
    delete(vid);
    clear vid
    close(f)
    error('That file already exists. Change the filename and try again.');
end
fid = fopen(binfilename, 'w');

% set motor velocity to .2 mm/sec
zhand.SetVelParams(0, 0, 1, motor_velocity); 

% move from starting position in mm down to 0 mm
zhand.SetAbsMovePos(0, 0); 
pause(2);
logentry('Moving motor...');
zhand.MoveAbsolute(0, 1==0);

logentry('Triggering video collection...');
cnt = 0;
trigger(vid);

% start timer for video timestamps
t1=tic; 

% Check and store the motor position every 100 ms until it reaches zero. 
pause(4/Fps);
NFramesTaken = 0;
% while(vid.FramesAvailable > 0)
while(NFramesTaken < NFrames)
       
    if vid.FramesAvailable==0
        disp('Looping through.');
        continue;
    end
    
    cnt = cnt + 1;
    znow = zhand.GetPosition_Position(0);
    zheight(cnt,1) = znow;
    pImage.UserData = znow;
    
    NFramesAvailable(cnt,1) = vid.FramesAvailable;
    NFramesTaken = NFramesTaken + NFramesAvailable(cnt,1);
%     disp(['Num Grabbed Frames: ' num2str(NFramesAvailable(cnt,1)) '/' num2str(NFramesTaken)]);

    [data, ~, meta] = getdata(vid, NFramesAvailable(cnt,1));    
    
    abstime{cnt,1} = vertcat(meta(:).AbsTime);
    framenumber{cnt,1} = meta(:).FrameNumber;


    [rows, cols, rgb, frames] = size(data);

%     numdata = double(squeeze(data));
% 
%     squashedstack = reshape(numdata,[],frames);
%     meanval{cnt,1} = transpose(mean(squashedstack));
%     stdval{cnt,1}  = transpose(std(squashedstack));
%     maxval{cnt,1}  = transpose(max(squashedstack));
%     minval{cnt,1}  = transpose(min(squashedstack));
    
    if cnt == 1
        firstframe = data(:,:,1);
    end
        
    fwrite(fid, data, imagetype);

    if ~mod(cnt,5)
        drawnow;
    end

end

lastframe = data(:,:,1,end);

elapsed_time = toc(t1);

logentry('Stopping video collection...');
stop(vid);
pause(1);
    
% Quickly move the ThorLabs z-motor to the starting height
ba_movez(zhand, starting_height, 'fast')

% Close the video .bin file
fclose(fid);

NFramesCollected = sum(NFramesAvailable);
AbsFrameNumber = cumsum([1 ; NFramesAvailable(:)]);
AbsFrameNumber = AbsFrameNumber(1:end-1);

logentry(['Total Frame count: ' num2str(NFramesCollected)]);
logentry(['Total Elapsed time: ' num2str(elapsed_time)]);

Time = cellfun(@datenum, abstime, 'UniformOutput', false);
Time = vertcat(Time{:});

% The z-position of the Thorlabs motor is not queried at every frame, so to
% put the measurements on the same "clock", I'm going to interpolate motor
% position between the frame clusters grabbed from the vid object and
% combine time and z-position into a single table.
ZHeight(:,1) = interp1(AbsFrameNumber, zheight, 1:NFramesCollected, 'linear', 'extrap');
ZHeight(1:AbsFrameNumber(1),1) = zheight(1);
% Max = vertcat(maxval{:});
% Mean = vertcat(meanval{:});
% StDev = vertcat(stdval{:});
% Min = vertcat(minval{:});

%% Compile Remaining Metadata

Fid = ba_makeFid;

m.File.Fid = Fid;

% m.Medium.Name = MediumName;
% switch m.Medium.Name
%     case 'Int'
%         % 07.11.2019 Data (SNA, WGA, PEG beads on BSM-slides)
%         m.Medium.Viscosity = 0.0605;  
%         m.Medium.Components = Int25k;
%         m.Medium.ManufactureDate = '09-25-2019';   
%     case 'NoInt'
%         % 07.11.2019 Data (SNA, WGA, PEG beads on BSM-slides)
%         m.Medium.Viscosity = 0.0527;  
%         m.Medium.Components = NoInt;
%         m.Medium.ManufactureDate = '07-10-2019';   
%     otherwise
%         logentry('Unknown Case for Medium.');
% end    
% m.Medium.Buffer = 'PBS';

m.Video.Format = vid.VideoFormat;
m.Video.ExposureTime = src.Shutter;
m.Video.Resolution = vid.VideoResolution;
m.Video.NFrames = NFrames;
m.Video.ImageType = imagetype;

m.Results.ElapsedTime = elapsed_time;
% m.Results.TimeHeightVidStatsTable = table(Time, ZHeight, Max, Mean, StDev, Min);
m.Results.TimeHeightVidStatsTable = table(Time, ZHeight);
m.Results.FirstFrame = firstframe;
m.Results.LastFrame = lastframe;


save([filename, '.meta.mat'], '-STRUCT', 'm');

delete(vid);
clear vid

close(f)
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
     headertext = [logtimetext 'ba_pulloff: '];
     
     fprintf('%s%s\n', headertext, txt);
     
     return