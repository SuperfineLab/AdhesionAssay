
% Well info
Well.Diameter_mm = 9; % [mm]
Well.Volume_mL = 0.060; % [mL]
Well.Area = pi * (Well.Diameter_mm*1e6/2) .^ 2; % [nm^2]

% Bead info
Bead.Diameter_um = 24;
Bead.Density_kgm3 = 1400;
Bead.Volume_m3 = (4/3) * pi * (Bead.Diameter_um*1e-6/2) .^ 3;
Bead.Mass_kg = Bead.Density_kgm3 .* Bead.Volume_m3;
Bead.StockMassConcentration = 0.01;  % 1% w/v, or also 0.01 kg per L
Bead.StockNumberConcentration_mL = (Bead.StockMassConcentration ./ Bead.Mass_kg) ./ 1e3; % [kg/L -> count/mL]

Bead.SurfaceArea = 4 * pi * (Bead.Diameter_um*1e3/2).^2; % [nm^2]
Bead.CrossSection=     pi * (Bead.Diameter_um*1e3/2).^2; % [nm^2]

Bead.Concentration = Bead.StockMassConcentration ./ 100; % I use 1:100 dilution when dropping beads on surface
Bead.Area = Bead.Concentration .* Bead.SurfaceArea; % Total bead surface area in solution
Bead.Volume_mL = 0.06;

% 
% bead.activegroup.conc_molkg = 0.15; % [mol/kg] OR [mmol/g]
% bead.activegroup.conc_Nperkg = bead.activegroup.conc_molkg * NA; % [activesites/kg]
% bead.activegroup.conc_Nperbead = bead.activegroup.conc_Nperkg * bead.mass_kg; % [activesites/bead]
% bead.activegroup.areaper_m2 = bead.surfacearea_m2 / bead.activegroup.conc_Nperbead;



% IgG info
IgG.Molwt_gmol = 150000; % average molecular weight for IgG [g/mol]
IgG.Dimensions_nm = [14.5 8.5 4]; % assume shape is rectangular prism
IgG.Area_hi =  14.5 * 8.5; % largest cross-section [nm^2]
IgG.Area_lo =   8.5 * 4;   % smallest cross-section [nm^2]
IgG.Area = [IgG.Area_lo mean([IgG.Area_lo IgG.Area_hi]) IgG.Area_hi]; % [nm^2]
IgG.WellConcentration_ugmL = calc_concentration(Well, IgG);
IgG.BeadConcentration_ugmL = calc_concentration(Bead, IgG);

% BSA info
BSA.Molwt_gmol = 65000; % average molecular weight for BSA [g/mol]
BSA.Dimensions_nm = [4 4 14]; % assume shape is prolate spheroid % [nm]
BSA.Area_hi = pi * 4/2 * 14/2;
BSA.Area_lo = pi * (4/2) .^ 2;
BSA.Area = [BSA.Area_lo mean([BSA.Area_lo BSA.Area_hi]) BSA.Area_hi]; % [nm^2]
BSA.Concentration_ugmL = calc_concentration(Well, BSA);

% Protein G info
ProtG.Molwt_gmol = 66000; % average molecular weight for BSA [g/mol]
ProtG.Dimensions_nm = [4 4 14]; % assume shape is prolate spheroid % [nm]
ProtG.Area_hi = pi * 4/2 * 14/2;
ProtG.Area_lo = pi * (4/2) .^ 2;
ProtG.Area = [ProtG.Area_lo mean([ProtG.Area_lo ProtG.Area_hi]) ProtG.Area_hi]; % [nm^2]
ProtG.Concentration_ugmL = calc_concentration(Well, ProtG);

% PEG info
Peg2k.Molwt_gmol = 2000;
Peg2k.Lp = 0.37; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
Peg2k.N = 45;
Peg2k.Ro = 1/2 * (Peg2k.Lp*2) * Peg2k.N^0.5; % Ro = 1/2*b*N^0.5 [Rubi ]
Peg2k.Area = pi * Peg2k.Ro .^ 2;
Peg2k.Concentration_ugmL = calc_concentration(Well, Peg2k);

function Concentration_ugmL = calc_concentration(Well, Molecule)

    % Constants
    NA = 6.022e23;

    % The ratio in areas provides the number of IgG molecules 
    % that would fully coat the well surface.
    Molecule.Nmolecules = Well.Area ./ Molecule.Area;

    % convert to moles
    Molecule.Moles = Molecule.Nmolecules ./ NA;

    % convert to grams
    Molecule.Mass = Molecule.Moles .* Molecule.Molwt_gmol .* 1e6;

    % Concentrations matching area requirements 1:1
    Concentration_ugmL = Molecule.Mass ./ Well.Volume_mL; % [ug/mL]

end