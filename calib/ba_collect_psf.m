function outs = ba_collect_psf(zhand, outputStackDir, exptime)
% BA_COLLECT_PSF drives the hardware when collecting point-spread functions
% 

if nargin < 1 || isempty(zhand) || ~contains(class(zhand), 'COM.MGMOTOR_MGMotorCtrl_1')
    error('Handle to the z-motor was incorrect type or not provided. Type "help tm_initz" for details.');    
end

% This only works if all of the modes are set before Matlab gets ahold of
% the camera object. To make sure this is the case, run FLIR's (Point
% Gray) Flycap software and set the ExposureMode and FrameRateMode to "off"
% and the ShutterMode to 'manual'. To some extent, Matlab setting these
% particular properties is merely a "formality" until a bug is fixed in
% Matlab that doesn't allow changes to these modes to persist after setting
% them.

% Pull the current working directory
rootdir = pwd;
imageType = 'pgm';

% Check for existence of stackdir. We don't want to overwrite any previous
% data.
if ~isempty(dir(outputStackDir))
    error('Stack Directory exists already. Choose another name to avoid overwriting dats.');
end

mkdir(outputStackDir);
cd(outputStackDir);

%
% % Controlling the Hardware
%

% Camera Setup
CameraName = 'Grasshopper3';
CameraFormat = 'F7_Raw16_1024x768_Mode2';
ExposureTime = exptime;
Video = flir_config_video(CameraName, CameraFormat, ExposureTime);
[cam, src] = flir_camera_open(Video);
vidRes = cam.VideoResolution;
imageRes = fliplr(vidRes);
pause(0.1);

% trigconf = triggerconfig(cam, 'manual');
triggerconfig(cam, 'manual');
cam.FramesPerTrigger = Inf;
% preview(cam);
pause(.2)
outs = struct;

% Initialize vector for height and time at each frame
nSteps = 300;
stepsize = 0.001; % [mm]

% Set method/mode for jogging instead of continuous motion
zhand.SetJogStepSize(0,stepsize);
zhand.SetJogVelParams(0,1,5,2);

% Pre-fill the outputs
ztvector = zeros(nSteps,1); 
max_intensity = NaN(nSteps,1);
imgstack = cell(nSteps,1);

% imgstack = uint16(zeros(768,1024,nSteps));
height = 0;


% Loop occurs until motor position reaches 0
for k = 1:nSteps
    
    %take snapshot and save image matrix into imgstack
    [pic, metadata(k)] = getsnapshot(cam); 
    
    % Saving images as a stack 
    filestring = ['psfHeight-' num2str(k, '%04i') '.' imageType];
    outfile = fullfile(rootdir, outputStackDir, filestring);
    imwrite(pic, outfile, imageType);
    
    % Add image to cell array for table output
    imgstack{k} = pic;
    
    % Get position of motor and store in ztvector
    height = tm_getz(zhand); 
    ztvector(k,1) = height;

    % Calculate and share image's maximum intensity
    max_intensity(k,1) = max(pic(:));
    fprintf('pos = %i, max_intensity = %i \n', k, max_intensity(k,1));
    
    % Jog the position of the motor by one step (up)
    zhand.MoveJog(0,1); %1 raises magnet, 2 lowers magnet    
    pause(1);
    
end

cd(rootdir);

outs = table(ztvector, max_intensity, imgstack, ...
       'VariableNames', {'ZposAboveSurface', 'MaxIntensity', 'BeadImage'});
outs.Properties.VariableUnits = {'[mm]','',''};
% xlswrite([outputFileName '.xlsx'],ztvector)



