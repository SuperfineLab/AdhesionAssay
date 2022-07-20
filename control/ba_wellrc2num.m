function WellNumber = ba_wellrc2num(rc)
    r = rc(:,1);
    c = rc(:,2);
    
    if c < 1 || c > 5 || r < 1 || r > 3
        error('Improper coordinates for this plate design.');
    end
        
    WellNumber = 5*(r-1) + c;
    
    