function hnd = ba_initz(scopecodename, visibleUI_TF)
% BA_INITZ initializes the handle to the Thorlabs z-motor
% 

    if nargin < 1 || isempty(scopecodename)
        error('Need scope code name, ''Ixion'' or ''Artemis''.');
    end

    if nargin < 2 || isempty(visibleUI_TF)
        visibleUI_TF = false;
    end

    % The z-motor GUI gets docked into a matlab figure that's explicitly 
    % constructed using the Matlab's default figure properties (i.e. figure '0').
    fpos = get(0,'DefaultFigurePosition');
    fpos(3) = 650; % Figure width
    fpos(4) = 450; % Figure height
    f = figure('Position', fpos, 'Menu', 'None', 'Name', 'APT GUI');

    if visibleUI_TF
        f.Visible = 'on';
    else
        f.Visible = 'off';
    end

    % --- Create ActiveX Controller for the ThorLabs z-motor
    % This section is mostly taken from Thorlabs APT Matlab Guide, located at:
    % https://www.thorlabs.com/tutorials/APTProgramming.cfm (bottom link under
    % "Matlab" section). More information can be found here: 
    % http://www.mathworks.com/help/imaq/basic-image-acquisition-procedure.html
    %
    % Initialize Control GUI for Thorlabs z-motor control
    % !regsvr64 /s C:\Program Files (x86)\Thorlabs\APT\APT Server\MG17Motor.ocx
    hnd = actxcontrol('MGMOTOR.MGMotorCtrl.1',[20 20 600 400 ], f);
    hnd.StartCtrl;

    % The serial number for the motor is 83829797. Must set it here and
    % register/identify our connection to the motor.
    switch scopecodename
        case 'Artemis'
            set(hnd,'HWSerialNum', 83829797);
        case 'Ixion'
            set(hnd,'HWSerialNum', 83829573);
        otherwise
            error('Unrecognizable Scope.');
    end

    hnd.Identify; 
    drawnow;

return