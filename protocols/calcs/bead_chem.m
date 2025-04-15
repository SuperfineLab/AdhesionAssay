function Bead = bead_chem(diameter, density, beadtype)
% stock_conc of bead in [% w/v]
% diameter of bead in [um]
% *** mass density of beads in [kg/m^3]  <----- 1 [g/mL] = 1000 [kg/m^3]
% dilution factor of beads in final solution, % [unitless]
% FOVwidthheight [width height] in [pixels], e.g. [1024 768]
% calibum is FOV calibration in [um/pixel]

if nargin < 3 || isempty(beadtype)
    beadtype = 'spherotech';
end

disp('Make sure your bead density is in kg/m^3!');

logentry(['Bead type is: ' beadtype]);

NA = 6.023e23; % [count/mol]

% Bead info, from Spherotech for 
% FCM-20052-2 : Fluorescent Carboxyl Magnetic Particles, Yellow, 1% w/v, 18.0-24.9 um, 2 mL
% AN01 : 23.7 um Mean Diameter
% ~1.15 g/mL density
% ~1.25 x 10^6 particles/mL
% ~2.35 x 10^9 carboxyl groups/particle (which comes out to 0.00056 mol COOH/kg]
%
Bead.Diameter_um = diameter;
Bead.Density_kgm3 = density;

r_m = Bead.Diameter_um/2 * 1e-6;
Bead.Volume_m3 =      (4/3) * pi * r_m^3; % [m^3]
Bead.Volume_um3 =     (4/3) * pi * r_m^3 * (1e6^3); % [m^3]
Bead.SurfaceArea_m2 =  4    * pi * r_m^2; % [m^2]
Bead.SurfaceArea_nm2 = 4    * pi * r_m^2 * (1e9^2); % [nm^2]
Bead.CrossSection_m2 = pi * r_m^2; % cross-sectional area in [m^2]
Bead.Mass_kg = Bead.Volume_m3 .* Bead.Density_kgm3; % [kg]


switch lower(beadtype)    
    case "spherotech"
        Bead.ActiveGroup.Conc_molkg = 0.00056; % [mol/kg] OR [mmol/g] SPHEROTECH 24UM
    case "fluospheres"
        Bead.ActiveGroup.Conc_molkg = 0.15; % [mol/kg] OR [mmol/g] FLUOSPHERES
    otherwise
        error('Unknown bead type.');
end

Bead.ActiveGroup.Conc_Nperkg = Bead.ActiveGroup.Conc_molkg * NA; % [activesites/kg]
Bead.ActiveGroup.Conc_Nperbead = Bead.ActiveGroup.Conc_Nperkg * Bead.Mass_kg; % [activesites/bead]
% available area for each activegroup
Bead.ActiveGroup.Areaper_m2 = Bead.SurfaceArea_m2 / Bead.ActiveGroup.Conc_Nperbead;



    
    
    
    