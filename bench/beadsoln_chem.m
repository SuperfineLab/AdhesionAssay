% beadsoln_chem
function x = beadsoln_chem(Bead, stockpercent, dilution_factor)

    x.startpercent = stockpercent;
    x.dilution_factor = dilution_factor;
    x.percent = stockpercent / dilution_factor;
    x.mgpermL = x.percent * 10;
    x.count_per_mL = x.mgpermL ./ (Bead.Mass_kg * 1e6); 
    x.count_per_uL = x.count_per_mL ./ 1e3;
    
    % In aqueous solutions, 1 mL = 1 cm^3
    count_per_cm3 = x.count_per_mL;
    meanfreepath_cm = 1 ./ (count_per_cm3 .^ 0.3333);
    x.meanfreepath_um = meanfreepath_cm * (1e6/1e2);
    x.N_beaddiameters = x.meanfreepath_um ./ Bead.Diameter_um - 1; 

end


% function x = bead_soln(bead, stockpercent, dilution_factor)
%   
% end

