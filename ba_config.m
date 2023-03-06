% config ixion for vid-capture on the command line
ExposureTime = 8; 

hw.zhand = NaN;

viewOps.cmin = 0;
viewOps.cmax = 65535;
viewOps.gain = 12;
viewOps.focusTF = false;
viewOps.exptime = ExposureTime;
viewOps.autoscaleTF = true;

Video = flir_config_video('Grasshopper3', 'F7_Raw16_1024x768_Mode2', ExposureTime);

clear ExposureTime

% % % ba_config
% % 
% % [~, hostname] = system('hostname');
% % 
% % switch(hostname)
% %     case 'zinc'
% %         scopename = 'Artemis';
% %     case 'cromium'
% %         scopename = 'Ixion';
% %     otherwise
% %         error('This system is not configured. Edit ba_config.');
% % end
% % 
% % 
% % 
% % switch(scopename)
% %     case 'Ixion'
% %         hw.zhand = NaN;
% %         viewOps.cmin = 0;
% %         viewOps.cmax = 65535;
% %         viewOps.gain = 12;
% %         viewOps.focusTF = false;
% %         viewOps.exptime = 8;
% %     case 'Artemis'
% %         
% % end
% % 
% % 
