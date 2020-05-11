function Video = ba_config_video(CameraName)
% BA_CHECKMETADATA ensures the metadata structure matches the specification.
%

    switch CameraName
        case 'Grasshopper3'
            Video.CameraName = CameraName;
            Video.ExposureMode = 'off';
            Video.FrameRateMode = 'off';
            Video.ShutterMode = 'manual';
            Video.Gain = 10;
            Video.Gamme = 1.15;
            Video.Brightness = 5.8594;
            Video.Format = [];
            Video.Height = 768;
            Video.Width = 1024;
            Video.Depth = 16;
            Video.ExposureTime = 0.008;
        case 'Dragonfly2'
            Video.CameraName = CameraName;
            Video.ExposureMode = 'off';
            Video.FrameRateMode = 'off';
            Video.ShutterMode = 'manual';
            Video.Gain = 10;
            Video.Gamme = 1.15;
            Video.Brightness = 5.8594;
            Video.Format = [];
            Video.Height = 768;
            Video.Width = 1024;
            Video.Depth = 16;
            Video.ExposureTime = 0.016;
            error('This needs developing because we moved away from Ixion.');
        otherwise
            error('Scope codename not recognized.');
    end
    

