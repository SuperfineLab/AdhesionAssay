function WellRowCol = ba_wellnum2rc(WellNumber)
    
    r = ceil(WellNumber/5);
    c = mod(WellNumber,5);
    if c == 0
        c = 5;
    end
        
    WellRowCol(1,:) = [r,c];
    
    