NA = 6.023e23;

% Well info
Well.Diameter_mm = 9; % [mm]
% Well.Diameter_mm = 8.8; % [mm]
Well.Volume_mL = 0.060; % [mL]
Well.Area = pi * (Well.Diameter_mm*1e6/2) .^ 2; % [nm^2]
Well.OHPerArea = 2; % [-OH/nm^2]
Well.OHPerWell = Well.Area * Well.OHPerArea;
Well.MolesOHPerWell = Well.OHPerWell / NA;
Well.TEPSASites = Well.OHPerWell/3;
Well.COOHSites = Well.TEPSASites * 2;

% TEPSA needed to coat a single well based on physical size of TEPSA
TEPSA.Area = 1.4; % [nm^2]  https://www.google.com/books/edition/Silanes_and_Other_Coupling_Agents_Volume/G7jNBQAAQBAJ?hl=en&gbpv=1&dq=10.1163/ej.9789004165915.i-348.16&pg=PA25&printsec=frontcover
TEPSA.MolWt_gmol = 13*12 + 24 + 6 * 16 + 28.1; % C13H24O6Si
TEPSA.NumberPerWell = Well.Area/TEPSA.Area;
TEPSA.MolesPerWell = TEPSA.NumberPerWell ./ NA; % [moles]
TEPSA.MassPerWell = TEPSA.MolesPerWell * TEPSA.MolWt_gmol; % [grams]

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

% GlcNAC-PEG12-Azide (or GalNAc)
GalNAc_PEG3_Azide.MolWt_gmol = 654.7;
GalNAc_PEG3_Azide.MolesPerWell = Well.COOHSites / NA;
GalNAc_PEG3_Azide.MassPerWell = GalNAc_PEG3_Azide.MolesPerWell * GalNAc_PEG3_Azide.MolWt_gmol; % [g]

% DBCO-amine
DBCO_amine.MolWt_gmol = 276.33;
DBCO_amine.MolesPerWell = GalNAc_PEG3_Azide.MolesPerWell;
DBCO_amine.MassPerWell = DBCO_amine.MolesPerWell * DBCO_amine.MolWt_gmol;
% DBCO_amine.

% IgG info
IgG.MolWt_gmol = 150000; % average molecular weight for IgG [g/mol]
IgG.Dimensions_nm = [14.5 8.5 4]; % assume shape is rectangular prism
IgG.Area_hi =  14.5 * 8.5; % largest cross-section [nm^2]
IgG.Area_lo =   8.5 * 4;   % smallest cross-section [nm^2]
IgG.Area = [IgG.Area_lo mean([IgG.Area_lo IgG.Area_hi]) IgG.Area_hi]; % [nm^2]i
IgG.WellConcentration_ugmL = calc_concentration(Well, IgG);
IgG.BeadConcentration_ugmL = calc_concentration(Bead, IgG);

% BSA info
BSA.MolWt_gmol = 65000; % average molecular weight for BSA [g/mol]
BSA.Dimensions_nm = [4 4 14]; % assume shape is prolate spheroid % [nm]
BSA.Area_hi = pi * 4/2 * 14/2;
BSA.Area_lo = pi * (4/2) .^ 2;
BSA.Area = [BSA.Area_lo mean([BSA.Area_lo BSA.Area_hi]) BSA.Area_hi]; % [nm^2]
BSA.Concentration_ugmL = calc_concentration(Well, BSA);

% Protein G info
ProtG.MolWt_gmol = 66000; % average molecular weight for BSA [g/mol]
ProtG.Dimensions_nm = [4 4 14]; % assume shape is prolate spheroid % [nm]
ProtG.Area_hi = pi * 4/2 * 14/2;
ProtG.Area_lo = pi * (4/2) .^ 2;
ProtG.Area = [ProtG.Area_lo mean([ProtG.Area_lo ProtG.Area_hi]) ProtG.Area_hi]; % [nm^2]
ProtG.Concentration_ugmL = calc_concentration(Well, ProtG);

% PEG-2kD info (XXX TODO Make a PEG function that computes this based on mol wt.)
Peg2k.MolWt_gmol = 2000;
Peg2k.MonomerWt_gmol = 16 + (12 + 1 + 1)*2; % [g/mol] PEG monomer is H-[-OCH2CH2-]n-OH
Peg2k.Lp = 0.37; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
Peg2k.N = Peg2k.MolWt_gmol / Peg2k.MonomerWt_gmol;
Peg2k.Ro = 1/2 * (Peg2k.Lp*2) * Peg2k.N^0.5; % [nm], Ro = 1/2*b*N^0.5 [Rubi 54]
Peg2k.Rg = Peg2k.Ro / sqrt(6); % [nm], Rg = Ro/sqrt(6) [Rubi 63]
Peg2k.Area = pi * Peg2k.Rg .^ 2; % [nm^2]
Peg2k.Concentration_ugmL = calc_concentration(Well, Peg2k);

% PEG-5kD info
Peg5k.MolWt_gmol = 5000;
Peg5k.MonomerWt_gmol = 16 + (12 + 1 + 1)*2; % [g/mol] PEG monomer is H-[-OCH2CH2-]n-OH
Peg5k.Lp = 0.37; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
Peg5k.N = Peg5k.MolWt_gmol / Peg5k.MonomerWt_gmol;
Peg5k.Ro = 1/2 * (Peg5k.Lp*2) * Peg5k.N^0.5; % [nm], Ro = 1/2*b*N^0.5 [Rubi 54]
Peg5k.Rg = Peg5k.Ro / sqrt(6); % [nm], Rg = Ro/sqrt(6) [Rubi 63]
Peg5k.Area = pi * Peg5k.Rg .^ 2; % [nm^2]
Peg5k.Concentration_ugmL = calc_concentration(Well, Peg5k);

% glycine info
Gly.MolWt_gmol = 75.1;
Gly.Concentration_ugmL = (Well.COOHSites*Gly.MolWt_gmol)/Well.Volume_mL;

% WGA info
WGA.MolWt_gmol = 38000;
WGA.MonomerWt_gmol = 120; % [g/mol] 
WGA.Lp = 0.39; % [nm] https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3593838/
WGA.N = WGA.MolWt_gmol / WGA.MonomerWt_gmol;
WGA.Ro = 1/2 * (WGA.Lp*2) * WGA.N^0.5; % [nm], Ro = 1/2*b*N^0.5 [Rubi 54]
WGA.Rg = WGA.Ro / sqrt(6); % [nm], Rg = Ro/sqrt(6) [Rubi 63]
WGA.Area = pi * WGA.Rg .^ 2; % [nm^2]
WGA.Concentration_ugmL = calc_concentration(Well, WGA);


% PNA info
PNA.MolWt_gmol = 110000;
PNA.MonomerWt_gmol = 120; % [g/mol] PNA monomer is H-[-OCH2CH2-]n-OH
PNA.Lp = 0.39; % [nm] https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3593838/
PNA.N = PNA.MolWt_gmol / PNA.MonomerWt_gmol;
PNA.Ro = 1/2 * (PNA.Lp*2) * PNA.N^0.5; % [nm], Ro = 1/2*b*N^0.5 [Rubi 54]
PNA.Rg = PNA.Ro / sqrt(6); % [nm], Rg = Ro/sqrt(6) [Rubi 63]
PNA.Area = pi * PNA.Rg .^ 2; % [nm^2]
PNA.Concentration_ugmL = calc_concentration(Well, PNA);







function Concentration_ugmL = calc_concentration(Well, Molecule)

    % Constants
    NA = 6.022e23;

    % The ratio in areas provides the number of IgG molecules 
    % that would fully coat the well surface.
    Molecule.Nmolecules = Well.Area ./ Molecule.Area;

    % convert to moles
    Molecule.Moles = Molecule.Nmolecules ./ NA;

    % convert to grams
    Molecule.Mass = Molecule.Moles .* Molecule.MolWt_gmol .* 1e6;

    % Concentrations matching area requirements 1:1
    Concentration_ugmL = Molecule.Mass ./ Well.Volume_mL; % [ug/mL]

end
