function varargout = ba_impreview(zhand, focusTF)
% BA_IMPREVIEW UI for previewing the microscope's camera image.
%

    if nargin < 2 || isempty(focusTF)
        focusTF = false;
    end

    if nargin < 1 || isempty(zhand)
%         zhand = ba_initz;
%         pause(3);
        zhand = false;
    end
    
    imaqmex('feature', '-previewFullBitDepth', true);    
    Camera.Name = 'Grasshopper 3';
    Camera.Model = 'GS3-U3-32S4M-C';
    Camera.Type = 'pointgrey';
    % The Camera "number" identifies which point-grey camera to use. 
    % Currently, the 2nd point-grey camera is the Grasshopper3, which is 
    % left of the ocular on Artemis (Chapman Hall B42)
    Camera.Number = 2; 
    Camera.Mode = 'F7_Raw16_1024x768_Mode2';
    vid = videoinput(Camera.Type, Camera.Number, Camera.Mode);
    
    vid.ReturnedColorspace = 'grayscale';
    
    src = getselectedsource(vid);
    
    src.Brightness = 5.8594;   
    src.ExposureMode = 'off';    
    src.GainMode = 'manual';
    src.Gain       = 14;
    src.GammaMode = 'manual';
    src.Gamma      = 1.15;
    src.FrameRateMode  = 'off';
%     src.FrameRate = 125;
    src.ShutterMode = 'manual';
    src.Shutter = 8;

    pause(0.1);
    
    
    imageRes = fliplr(vid.VideoResolution);   
    
    f = figure('Visible', 'off', 'Units', 'normalized');
    ax = subplot(2, 1, 1);
    set(ax, 'Units', 'normalized');
    set(ax, 'Position', [0.05, 0.4515, .9, 0.53]); 
    
    hImage = imshow(uint16(zeros(imageRes)));
    axis image

    edit_exptime = uicontrol(f, 'Position', [20 20 60 20], ...
                                'Style', 'edit', ...
                                'String', num2str(src.Shutter), ...
                                'Callback', @change_exptime);
    btn_grabframe = uicontrol(f, 'Position', [20 40 60 20], ...
                                 'Style', 'pushbutton', ...
                                 'String', 'Grab Frame', ...
                                 'Callback', @grab_frame);
%     edit_exptime.Position
%     btn_grabframe.Position
    
    hImage.UserData{1} = zhand;
    hImage.UserData{2} = focusTF;
    
    setappdata(hImage, 'UpdatePreviewWindowFcn', @ba_livehist);
%     hImage.CData = log10(double(hImage.CData));
    h = preview(vid, hImage);
    set(h, 'CDataMapping', 'scaled');

    switch nargout
        case 1
            varargout{1} = f;
    end
    
    
    
    function change_exptime(source,event)

        exptime = str2num(source.String);
        fprintf('New exposure time is: %4.2g\n', exptime);
        
        src.Shutter = exptime;
       
        edit_exptime.String = num2str(src.Shutter);
        
    end

    function grab_frame(source, event)
        imwrite(hImage.CData, 'grabframe.png');
        disp('Frame grabbed to grabframe.png');
    end


end
