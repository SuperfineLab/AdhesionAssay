% config ixion for vid-capture on the command line
% ba_config

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
        hw.zhand = tm_initz('Artemis');

        hw.ludl = stage_open_Ludl(ludl_comport);
        hw.ludl.speed = 20000;
        hw.ludl.accel = 0.01;
        
        hw.scope = scope_open(scope_comport);


end


viewOps.cmin = 0;
viewOps.cmax = 65535;
viewOps.gain = 14;
viewOps.focusTF = false;
viewOps.exptime = 8; 

Video = flir_config_video('Grasshopper3', 'F7_Raw16_1024x768_Mode2', viewOps.exptime);

