function outs = bead_chem(beadcount_per_mL, diameter, density, dilfactor, FOVwidthheight, calibum)
% stock_conc of bead in [% w/v]
% diameter of bead in [um]
% mass density of beads in [kg/m^3]
% dilution factor of beads in final solution, % [unitless]
% FOVwidthheight [width height] in [pixels]
% calibum is FOV calibration in [um/pixel]

NA = 6.023e23; % [count/mol]

FOV.width = FOVwidthheight(1);
FOV.height = FOVwidthheight(2);
FOV.calibum = calibum;
FOV.width_um = FOV.width * FOV.calibum;
FOV.height_um = FOV.height * FOV.calibum;
FOV.area_um2 = FOV.width_um .* FOV.height_um;


bead.diameter_um = diameter;
bead_radius_m = bead.diameter_um/2 * 1e-6;
bead.density_kgm3 = density;
bead.volume_m3 = (4/3) * pi * bead_radius_m^3; % [m^3]
bead.surfacearea_m2 = 4 * pi * bead_radius_m^2; % [m^2]
bead.crosssection_m2 = pi * bead_radius_m^2; % [m^2]
bead.mass_kg = bead.volume_m3 .* bead.density_kgm3; % [kg]

bead.activegroup.conc_molkg = 0.15; % [mol/kg] OR [mmol/g]
bead.activegroup.conc_Nperkg = bead.activegroup.conc_molkg * NA; % [activesites/kg]
bead.activegroup.conc_Nperbead = bead.activegroup.conc_Nperkg * bead.mass_kg; % [activesites/bead]
bead.activegroup.areaper_m2 = bead.surfacearea_m2 / bead.activegroup.conc_Nperbead;


% Spatial distribution
solution.bead.count_per_mL = beadcount_per_mL; % Number concentration
solution.bead.spacingpermicron = solution.bead.count_per_mL .^ (1/3) / 1e3;% [beads/micron]
solution.bead.meanfreepath_um = 1 ./ solution.bead.spacingpermicron;  % [um]
solution.bead.mass_conc_kgmL = bead.mass_kg * solution.bead.count_per_mL; % [kg/mL]
solution.bead.mass_conc_mgmL = solution.bead.mass_conc_kgmL * 1e6;  % [mg/mL]

N_beaddiameters = solution.bead.meanfreepath_um / (bead.diameter_um * 1e6);
solution.bead.N_per_FOV = FOV.area_um2 ./ (solution.bead.meanfreepath_um .^ 2);

outs.FOV = FOV;
outs.bead = bead;
outs.solution = solution;