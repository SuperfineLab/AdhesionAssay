function ba_collect_video(filename, Video, Nsec)

if nargin < 1 || isempty(filename)
    error('Need filename.');
end

if nargin < 2 || isempty(Video)
    error('Need output from Video = flir_config_video(CameraName, exptime)');
end

if nargin < 3 || isempty(Nsec)
    Nsec = 10; % [s]
end

abstime{1,1} = [];
framenumber{1,1} = [];
TotalFrames = 0;

Fps = 1 / (Video.ExposureTime/1000);
NFrames = ceil(Fps * Nsec);
% NFrames = 1000;

[cam, src] = flir_camera_open(Video);

triggerconfig(cam, 'manual');
cam.FramesPerTrigger = NFrames;


imagetype = strcat('uint', num2str(Video.Depth));

vidRes = cam.VideoResolution;
imageRes = fliplr(vidRes);

filename = [filename, '_', num2str(vidRes(1)), 'x', ...
                           num2str(vidRes(2)), 'x', ...
                           num2str(NFrames), '_' imagetype];

f = figure;%('Visible', 'off');
switch Video.Depth
    case 8
        pImage = imshow(uint8(zeros(imageRes)));    
    case 16
        pImage = imshow(uint16(zeros(imageRes)));
end


axis image
setappdata(pImage, 'UpdatePreviewWindowFcn', @ba_pulloffview)
p = preview(cam, pImage);
set(p, 'CDataMapping', 'scaled');


% ----------------
% Controlling the Hardware and running the experiment
%

pause(0.1);
logentry('Starting video...');
start(cam);
pause(0.1);

NFramesAvailable = 0;


binfilename = [filename, '.bin'];
if ~isempty(dir(binfilename))
    delete(cam);
    clear cam
    close(f)
    error('That file already exists. Change the filename and try again.');
else
end
fid = fopen(binfilename, 'w');

logentry('Triggering video collection...');
cnt = 0;
trigger(cam);

% start timer for video timestamps
t1 = tic; 

 
pause(4/Fps);
NFramesTaken = 0;
% while(vid.FramesAvailable > 0)
while(NFramesTaken < NFrames)
    cnt = cnt + 1;            
    
    NFramesAvailable(cnt,1) = cam.FramesAvailable;
    NFramesTaken = NFramesTaken + NFramesAvailable(cnt,1);
%     disp(['Num Grabbed Frames: ' num2str(NFramesAvailable(cnt,1)) '/' num2str(NFramesTaken)]);

    [data, ~, meta] = getdata(cam, NFramesAvailable(cnt,1));    
    
    if isempty(data)
%         logentry('Bypassing empty data buffer, i.e. no frames to pull.');
        continue;
    end
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
stop(cam);
pause(1);
    
% Close the video .bin file
fclose(fid);

NFramesCollected = sum(NFramesAvailable);
AbsFrameNumber = cumsum([1 ; NFramesAvailable(:)]);
AbsFrameNumber = AbsFrameNumber(1:end-1);

logentry(['Total Frame count: ' num2str(NFramesCollected)]);
logentry(['Total Elapsed time: ' num2str(elapsed_time)]);

Time = cellfun(@datenum, abstime, 'UniformOutput', false);
Time = vertcat(Time{:});

% Max = vertcat(maxval{:});
% Mean = vertcat(meanval{:});
% StDev = vertcat(stdval{:});
% Min = vertcat(minval{:});

Fid = ba_makeFid;
[~,host] = system('hostname');


m.File.Fid = Fid;
m.File.SampleName = filename;
% m.File.SampleInstance = SampleInstance;
m.File.Binfile = binfilename; 
m.File.Binpath = pwd;
m.File.Hostname = strip(host);

% m.Bead.Diameter = 24;
% m.Bead.SurfaceChemistry = BeadChemistry;

% m.Scope = Scope;

m.Video = Video;

m.Results.ElapsedTime = elapsed_time;
% m.Results.TimeHeightVidStatsTable = table(Time, ZHeight, Max, Mean, StDev, Min);
m.Results.TimeStatsTable = table(Time);
m.Results.FirstFrame = firstframe;
m.Results.LastFrame = lastframe;

save([filename, '.meta.mat'], '-STRUCT', 'm');

delete(cam);
clear cam

close(f);
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
     headertext = [logtimetext 'ur_collect_video: '];
     
     fprintf('%s%s\n', headertext, txt);
     
     return
