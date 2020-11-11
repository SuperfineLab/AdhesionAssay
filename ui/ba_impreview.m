function varargout = ba_impreview(zhand, focusTF)
% BA_IMPREVIEW UI for previewing the microscope's camera image.
%

    if nargin < 2 || isempty(focusTF)
        focusTF = false;
    end

    if nargin < 1 || isempty(zhand)
        zhand = tm_initz('Artemis');
        pause(3);
        %zhand = false;
    end
    
    ExposureTime = 1000/60;
    
    hwhandle=struct('zhand', zhand, ...
    'exptime', ExposureTime, ...
    'focusTF', focusTF);
    %disp(hwhandle)
    
    callback_function = @ba_livehist;
    
    vid_impreview(hwhandle, callback_function, focusTF)


end
