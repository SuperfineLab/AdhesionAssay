function varargout = ba_wellnum2rc(WellNumber)
    
    well = double(WellNumber);

    r = ceil(well/5);
    c = mod(well,5);
    
    c(c == 0) = 5;

    WellRowCol = [r(:),c(:)];
    
    switch nargout
        case 1
            varargout{1} = WellRowCol;
        case 2
            varargout{1} = WellRowCol(:,1);
            varargout{2} = WellRowCol(:,2);
        otherwise
            error('This function is undefined for more than two outputs.');
    end