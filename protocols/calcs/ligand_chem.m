NA = 6.022e23;

% GlcNAC-PEG12-Azide (or GalNAc)
GalNAc_PEG3_Azide.MolWt_gmol = 654.7;
GalNAc_PEG3_Azide.MolesPerWell = Well.COOHSites / NA;
GalNAc_PEG3_Azide.MassPerWell = GalNAc_PEG3_Azide.MolesPerWell * GalNAc_PEG3_Azide.MolWt_gmol; % [g]


% DBCO-amine
DBCO_amine.MolWt_gmol = 276.33;
DBCO_amine.MolesPerWell = GalNAc_PEG3_Azide.MolesPerWell;
DBCO_amine.MassPerWell = DBCO_amine.MolesPerWell * DBCO_amine.MolWt_gmol;


% glycine info
Gly.Name = "Glycine";
Gly.MolWt_gmol = 75;
Gly.MonomerWt_gmol = 75;
% % Gly.Dimensions_nm = [0.1 0.3 0.1]; % total guess here (based on bond lengths and guessing impact of angle)
% % Gly.Area_hi =  0.1 * 0.3; % largest cross-section [nm^2]
% % Gly.Area_lo =  0.1 * 0.1;   % smallest cross-section [nm^2]
% Gly.Area_nm2 = [Gly.Area_lo mean([Gly.Area_lo Gly.Area_hi]) Gly.Area_hi]; % [nm^2]
Gly.Lp_nm = 0.39; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
Gly = polyphys(Gly);
[Gly.WellMolarConcentration_molL, Gly.WellMassConcentration_mgmL] = calc_well_concentration(Well, Gly);
[Gly.BeadMolarConcentration_molL, Gly.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, Gly);

% IgG info
IgG.Name = "IgG";
IgG.MolWt_gmol = 150000; % average molecular weight for IgG [g/mol]
IgG.MonomerWt_gmol = 120;
% IgG.Dimensions_nm = [14.5 8.5 4]; % assume shape is rectangular prism
% IgG.Area_hi =  14.5 * 8.5; % largest cross-section [nm^2]
% IgG.Area_lo =   8.5 * 4;   % smallest cross-section [nm^2]
% IgG.Area_nm2 = [IgG.Area_lo mean([IgG.Area_lo IgG.Area_hi]) IgG.Area_hi]; % [nm^2]
IgG.Lp_nm = 0.39; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
IgG = polyphys(IgG);
[IgG.WellMolarConcentration_molL, IgG.WellMassConcentration_mgmL] = calc_well_concentration(Well, IgG);
[IgG.BeadMolarConcentration_molL, IgG.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, IgG);

% IgG.BeadConcentration_ugmL = calc_concentration(Bead, IgG);


% BSA info
BSA.Name = "BSA";
BSA.MolWt_gmol = 65000; % average molecular weight for BSA [g/mol]
BSA.MonomerWt_gmol = 120;
% BSA.Dimensions_nm = [4 4 14]; % assume shape is prolate spheroid % [nm]
% BSA.Area_hi = pi * 4/2 * 14/2;
% BSA.Area_lo = pi * (4/2) .^ 2;
% BSA.Area_nm2 = [BSA.Area_lo mean([BSA.Area_lo BSA.Area_hi]) BSA.Area_hi]; % [nm^2]
BSA.Lp_nm = 0.39; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
BSA = polyphys(BSA);
[BSA.WellMolarConcentration_molL, BSA.WellMassConcentration_mgmL] = calc_well_concentration(Well, BSA);
[BSA.BeadMolarConcentration_molL, BSA.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, BSA);



% Protein G info
ProtG.Name = "Protein G";
ProtG.MolWt_gmol = 66000; % average molecular weight for BSA [g/mol]
ProtG.MonomerWt_gmol = 120;
ProtG.Lp_nm = 0.39; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
% ProtG.Dimensions_nm = [4 4 14]; % assume shape is prolate spheroid % [nm]
% ProtG.Area_hi = pi * 4/2 * 14/2;
% ProtG.Area_lo = pi * (4/2) .^ 2;
% ProtG.Area_nm2 = [ProtG.Area_lo mean([ProtG.Area_lo ProtG.Area_hi]) ProtG.Area_hi]; % [nm^2]
ProtG = polyphys(ProtG);
[ProtG.WellMolarConcentration_molL, ProtG.WellMassConcentration_mgmL] = calc_well_concentration(Well, ProtG);
[ProtG.BeadMolarConcentration_molL, ProtG.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, ProtG);



% PEG-2kD info (XXX TODO Make a PEG function that computes this based on mol wt.)
Peg2k.Name = "PEG-2k";
Peg2k.MolWt_gmol = 2000;
Peg2k.MonomerWt_gmol = 16 + (12 + 1 + 1)*2; % [g/mol] PEG monomer is H-[-OCH2CH2-]n-OH
Peg2k.Lp_nm = 0.37; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
Peg2k = polyphys(Peg2k);
% Peg2k.Area_nm2 = pi * Peg2k.Rg_nm .^ 2; % [nm^2]
[Peg2k.WellMolarConcentration_molL, Peg2k.WellMassConcentration_mgmL] = calc_well_concentration(Well, Peg2k);
[Peg2k.BeadMolarConcentration_molL, Peg2k.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, Peg2k);


% PEG-5kD info
Peg5k.Name = "PEG-5k";
Peg5k.MolWt_gmol = 5000;
Peg5k.MonomerWt_gmol = 16 + (12 + 1 + 1)*2; % [g/mol] PEG monomer is H-[-OCH2CH2-]n-OH
Peg5k.Lp_nm = 0.37; % [nm] https://www.sciencedirect.com/science/article/pii/S0006349508701255
Peg5k = polyphys(Peg5k);
% Peg5k.Area_nm2 = pi * Peg5k.Rg_nm .^ 2; % [nm^2]
[Peg5k.WellMolarConcentration_molL, Peg5k.WellMassConcentration_mgmL] = calc_well_concentration(Well, Peg5k);
[Peg5k.BeadMolarConcentration_molL, Peg5k.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, Peg5k);


% PWM info
PWM.Name = "PWM";
PWM.MolWt_gmol = 32000;
PWM.MonomerWt_gmol = 120; % [g/mol] https://www.biotrend.com/en/phytolacca-americana-lectin-pwm-5353/phytolacca-americana-lectin-pwm-677014366.html
PWM.Lp_nm = 0.39; % [nm] https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3593838/
PWM = polyphys(PWM);
% PWM.Area_nm2 = pi * PWM.Rg_nm .^ 2; % [nm^2]
[PWM.WellMolarConcentration_molL, PWM.WellMassConcentration_mgmL] = calc_well_concentration(Well, PWM);
[PWM.BeadMolarConcentration_molL, PWM.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, PWM);


% WGA info
WGA.Name = "WGA";
WGA.MolWt_gmol = 38000;
WGA.MonomerWt_gmol = 120; % [g/mol] 
WGA.Lp_nm = 0.39; % [nm] https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3593838/
WGA = polyphys(WGA);
% WGA.Area_nm2 = pi * WGA.Rg_nm .^ 2; % [nm^2]
[WGA.WellMolarConcentration_molL, WGA.WellMassConcentration_mgmL] = calc_well_concentration(Well, WGA);
[WGA.BeadMolarConcentration_molL, WGA.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, WGA);


% PNA info
PNA.Name = "PNA";
PNA.MolWt_gmol = 110000;
PNA.MonomerWt_gmol = 120; % [g/mol] 
PNA.Lp_nm = 0.39; % [nm] https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3593838/
PNA = polyphys(PNA);
% PNA.Area_nm2 = pi * PNA.Rg_nm .^ 2; % [nm^2]
[PNA.WellMolarConcentration_molL, PNA.WellMassConcentration_mgmL] = calc_well_concentration(Well, PNA);
[PNA.BeadMolarConcentration_molL, PNA.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, PNA);


% SNA info
SNA.Name = "SNA";
SNA.MolWt_gmol = 140000;
SNA.MonomerWt_gmol = 120; % [g/mol] (a peptide)
SNA.Lp_nm = 0.39; % [nm] https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3593838/
SNA = polyphys(SNA);
% SNA.Area_nm2 = pi * SNA.Rg_nm .^ 2; % [nm^2]
[SNA.WellMolarConcentration_molL, SNA.WellMassConcentration_mgmL] = calc_well_concentration(Well, SNA);
[SNA.BeadMolarConcentration_molL, SNA.BeadMassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSolnStock, SNA);


SurfaceTable = [struct2table(Gly);
                struct2table(Peg2k);
                struct2table(Peg5k);
                struct2table(PNA);
                struct2table(PWM);
                struct2table(WGA);
                struct2table(SNA);
                struct2table(BSA);
                struct2table(IgG);
                struct2table(ProtG);
                ]


function Molecule = polyphys(Molecule)
    Molecule.N = Molecule.MolWt_gmol / Molecule.MonomerWt_gmol;
    Molecule.Ro_nm = 1/2 * (Molecule.Lp_nm*2) * Molecule.N^0.5; % [nm], Ro = 1/2*b*N^0.5 [Rubi 54]
    Molecule.Rg_nm = Molecule.Ro_nm / sqrt(6); % [nm], Rg = Ro/sqrt(6) [Rubi 63]
    Molecule.Area_nm2 = pi * Molecule.Rg_nm .^ 2; % [nm^2]
end


function [MolarConcentration_molL, MassConcentration_mgmL] = calc_well_concentration(Well, Molecule)

    % Constants
    NA = 6.022e23;

    % The ratio in areas provides the number of molecules (proteins, etc)
    % that would fully coat the well surface.
    Molecule.Nmolecules = Well.Area_nm2 ./ Molecule.Area_nm2;

    % convert to moles
    Molecule.Moles = Molecule.Nmolecules ./ NA;

    % convert to grams
    Molecule.Mass_mg = Molecule.Moles .* Molecule.MolWt_gmol .* 1e3;

    % Concentrations matching area requirements 1:1
    MolarConcentration_molL = Molecule.Moles ./ Well.Volume_mL * 1e-3; % [mol/L]
    MassConcentration_mgmL = Molecule.Mass_mg ./ Well.Volume_mL; % [ug/mL]
    
end


function [MolarConcentration_molL, MassConcentration_mgmL] = calc_bead_concentration(Bead, BeadSoln, Molecule)

    % Constants
    NA = 6.022e23;

    % The ratio in areas provides the number of molecules (proteins, etc)
    % that would fully coat a bead's surface.
    Molecule.Nmolecules = (Bead.SurfaceArea_nm2 * BeadSoln.count_per_mL)   ./ Molecule.Area_nm2;

    % convert to moles
    Molecule.Moles = Molecule.Nmolecules ./ NA;

    % convert to grams
    Molecule.Mass_mg = Molecule.Moles .* Molecule.MolWt_gmol .* 1e3;
          
    % Concentrations matching area requirements 1:1 for 1 mL of bead soln
    MolarConcentration_molL = Molecule.Moles ./ 1e-3; % [mol/L]
    MassConcentration_mgmL = Molecule.Mass_mg; % [ug/mL]
    
end