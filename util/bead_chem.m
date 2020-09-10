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

bead.density_kgm3 = density;

r_m = bead.diameter_um/2 * 1e-6;
bead.volume_m3 = (4/3) * pi * r_m^3; % [m^3]
bead.surfacearea_m2 = 4 * pi * r_m^2; % [m^2]
bead.crosssection_m2 = pi * r_m^2; % [m^2]
bead.mass_kg = bead.volume_m3 .* bead.density_kgm3; % [kg]

bead.activegroup.conc_molkg = 0.15; % [mol/kg] OR [mmol/g]
bead.activegroup.conc_Nperkg = bead.activegroup.conc_molkg * NA; % [activesites/kg]
bead.activegroup.conc_Nperbead = bead.activegroup.conc_Nperkg * bead.mass_kg; % [activesites/bead]
bead.activegroup.areaper_m2 = bead.surfacearea_m2 / bead.activegroup.conc_Nperbead;

% Spatial distribution of beads in solution
bead.count_per_mL = beadcount_per_mL; % Number concentration
bead.spacingpermicron = bead.count_per_mL .^ (1/3) / 1e3;% [beads/micron]
bead.meanfreepath_um = 1 ./ bead.spacingpermicron;  % [um]
bead.mass_conc_kgmL = bead.mass_kg * bead.count_per_mL; % [kg/mL]
bead.mass_conc_mgmL = bead.mass_conc_kgmL * 1e6;  % [mg/mL]

N_beaddiameters = bead.meanfreepath_um / (bead.diameter_um * 1e6);
bead.N_per_FOV = FOV.area_um2 ./ (bead.meanfreepath_um .^ 2);

outs.FOV = FOV;
outs.bead = bead;
outs.solution = solution;