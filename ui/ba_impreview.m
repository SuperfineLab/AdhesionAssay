function varargout = ba_impreview(zhand, focusTF)
% BA_IMPREVIEW UI for previewing the microscope's camera image.
%

    if nargin < 2 || isempty(focusTF)
        focusTF = false;
    end

    if nargin < 1 || isempty(zhand)
%         zhand = tz_initz;
%         pause(3);
        zhand = false;
    end
    
    hwhandle.zhand;
    callback_function = @ba_livehist;
    
    vid_impreview(hwhandle, callback_function, focusTF)


end
