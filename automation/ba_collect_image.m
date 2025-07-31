function ba_collect_image(hw, viewOps, exptime, filename)

    % Camera Setup
    CameraName = 'Grasshopper3';
    CameraFormat = 'F7_Raw16_1024x768_Mode2';
    imagetype = 'uint16';
    ExposureTime = exptime;
    Video = flir_config_video(CameraName, CameraFormat, ExposureTime);
    [cam, src] = flir_camera_open(Video);
    % % trigconf = triggerconfig(cam, 'manual');
    % triggerconfig(cam, 'manual');
    % cam.FramesPerTrigger = NFrames;
    
    vidRes = cam.VideoResolution;
    imageRes = fliplr(vidRes);
    pause(0.1);


    filename = [filename, '_', num2str(vidRes(1)), 'x', ...
                               num2str(vidRes(2)), '_uint16', ...
                               '.png'];

    f = figure;%('Visible', 'off');
    pImage = imshow(uint16(zeros(imageRes)));
    
    axis image
    setappdata(pImage, 'UpdatePreviewWindowFcn', @ba_pulloffview)
    p = preview(cam, pImage);
    set(p, 'CDataMapping', 'scaled');

    pause(2);

    

    % ----------------
    % Controlling the Hardware and running the experiment
    %
    
    % pause(2);
    % logentry('Collecting image...');
    % start(cam);
    % pause(2);
    
    if ~isempty(dir(filename))
        error('That file already exists. Change the filename and try again.');
    else
        imwrite(p.CData, filename, 'png');
    end

    delete(cam);
    clear vid
    close(f)
    

end
