function [vid, src] = ba_video_setup

Video = ba_config_video('Grasshopper3');

vid = videoinput('pointgrey', 1, 'F7_Raw16_1024x768_Mode2');
src = getselectedsource(vid); 
src.ExposureMode = Video.ExposureMode; 
src.FrameRateMode = Video.FrameRateMode;
src.ShutterMode = Video.ShutterMode;
src.Gain = Video.Gain;
src.Gamma = Video.Gamma;
src.Brightness = Video.Brightness;
src.Shutter = 7.99;