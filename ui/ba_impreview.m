function varargout = ba_impreview(hwhandle, viewOps)
% BA_IMPREVIEW UI for previewing the microscope's camera image.
%

    if nargin < 2 || isempty(viewOps)
        ExposureTime = 1000/60;
        focusTF = false;
        viewOps=struct('exptime', ExposureTime, ...
                       'focusTF', focusTF);
    end

    if nargin < 1 || isempty(hwhandle)
        zhand = tm_initz('Artemis');
        pause(3);
        %zhand = false;
        hwhandle=struct('zhand', zhand);
    end
    
    callback_function = @ba_livehist;
    
    ui_handle = vid_impreview(hwhandle, viewOps, callback_function);
    
    if nargout > 0
        varargout{1} = ui_handle;
    end


end
