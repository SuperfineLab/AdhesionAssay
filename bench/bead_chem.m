function outs = bead_chem(stockpercent, diameter, density, dilution_factor, FOVwidthheight, calibum)
% stock_conc of bead in [% w/v]
% diameter of bead in [um]
% mass density of beads in [kg/m^3]
% dilution factor of beads in final solution, % [unitless]
% FOVwidthheight [width height] in [pixels], e.g. [1024 768]
% calibum is FOV calibration in [um/pixel]

NA = 6.023e23; % [count/mol]

FOV.width = FOVwidthheight(1);
FOV.height = FOVwidthheight(2);
FOV.calibum = calibum;
FOV.width_um = FOV.width * FOV.calibum;
FOV.height_um = FOV.height * FOV.calibum;
FOV.area_um2 = FOV.width_um .* FOV.height_um;

bead.diameter_um = diameter;
bead.density_kgm3 = density;

r_m = bead.diameter_um/2 * 1e-6;
bead.volume_m3 = (4/3) * pi * r_m^3; % [m^3]
bead.surfacearea_m2 = 4 * pi * r_m^2; % [m^2]
bead.Xsection_m2 = pi * r_m^2; % cross-sectional area in [m^2]
bead.mass_kg = bead.volume_m3 .* bead.density_kgm3; % [kg]

% bead.activegroup.conc_molkg = 0.15; % [mol/kg] OR [mmol/g] FLUOSPHERES
bead.activegroup.conc_molkg = 0.05; % [mol/kg] OR [mmol/g] SPHEROTECH 24UM
bead.activegroup.conc_Nperkg = bead.activegroup.conc_molkg * NA; % [activesites/kg]
bead.activegroup.conc_Nperbead = bead.activegroup.conc_Nperkg * bead.mass_kg; % [activesites/bead]
bead.activegroup.areaper_m2 = bead.surfacearea_m2 / bead.activegroup.conc_Nperbead;

% Spatial distribution of beads in solution
bead.stock = bead_stats(stockpercent, 1, bead.mass_kg, bead.diameter_um, FOV.area_um2);
bead.soln = bead_stats(stockpercent, dilution_factor, bead.mass_kg, bead.diameter_um, FOV.area_um2);


outs.FOV = FOV;
outs.bead = bead;
% outs.solution = solution;


function x = bead_stats(startpercent, dilfactor, mass_kg, diameter_um, fovarea_um2)
    x.startpercent = startpercent;
    x.dilution_factor = dilfactor;
    x.percent = startpercent / dilfactor;
    x.mgpermL = x.percent * 10;
    x.count_per_mL = x.mgpermL ./ (mass_kg * 1e6); 
    x.count_per_uL = x.count_per_mL ./ 1e3; % Number concentration per mL
    x.count_per_um3 = x.count_per_uL * 1e-6; %  1 [um^3] = 1 [femtoLiter]
    x.per_um = x.count_per_um3 .^ (1/3);  % beads per um (grid lattice)
    x.meanfreepath_um = 1 ./ x.per_um;
    x.conc_check_mgmL = (mass_kg * 1e6) * x.count_per_mL; % [mg/mL]
    x.N_beaddiameters = x.meanfreepath_um ./ diameter_um;   
    x.N_per_FOV = fovarea_um2 ./ (x.meanfreepath_um .^ 2);

    
    
    
    