% ba_config

% This script configures and prepares the matlab environment for accessing 
% the instrumentation used in the adhesion assay. It searches for the
% machine hostname (configured for three different setups) and opens
% connections to the Nikon microscope, Ludl stage, Grasshopper camera, and
% the Thorlabs Zmotor. Once this script concludes, the next steps would be
% to create a data directory using ba_mkdatadir, and running a video
% collection with ba_pulloff
%

% config ixion for vid-capture on the command line

[~, hostname] = system('hostname');

switch upper(strip(hostname))
    case "ZINC"
        scopename = 'Artemis';
        scope_comport = 'COM2';
        ludl_comport = 'COM6';
    case "CERIUM"
        scopename = 'Artemis';
        scope_comport = 'COM2';
        ludl_comport = 'COM4';
    case "CROMIUM"
        scopename = 'Ixion';        
    otherwise
        error('This system is not configured. Edit ba_config.');
end



switch(scopename)
    case 'Ixion'
        hw.zhand = NaN;

    case 'Artemis'
        % initialize the Thorlabs Zmotor connection
        hw.zhand = tm_initz('Artemis');

        % initialize the Ludl stage connection
        hw.ludl = stage_open_Ludl(ludl_comport);
        hw.ludl.speed = 20000;
        hw.ludl.accel = 0.01;
        
        % initialize the Nikon scope connection
        hw.scope = scope_open(scope_comport);


end

% Set default viewing options for camera preview
viewOps.cmin = 0;
viewOps.cmax = 65535;
viewOps.gain = 14;
viewOps.focusTF = false;
viewOps.exptime = 8; 

% configure the camera for use in collecting adhesion video
Video = flir_config_video('Grasshopper3', 'F7_Raw16_1024x768_Mode2', viewOps.exptime);

