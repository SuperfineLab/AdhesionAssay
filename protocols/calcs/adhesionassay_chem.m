%
% Adhesion Assay Chemistry Calculations, Modeling, and Experiment Setup
%

% Define the size scales for length and volume when coupling protein to the
% surface of a well used in the Adhesion Assay
well_diameter_mm = 9;
well_volume_mL = 0.06;

% Model the surface chemistry for the Adhesion Assay well
Well = well_chem(well_diameter_mm, well_volume_mL);

% Model the TEPSA molecule on a per Well basis....
tepsa_chem;

% Move on to the bead of interest. Define the basic size scale and density 
bead_diameter_um = 6;
bead_density_kgm3 = 1050;

% Model the bead chemistry as a function of those scales...
Bead = bead_chem(bead_diameter_um, bead_density_kgm3);

% Define scales for bead SOLUTION, i.e. stock percent and dilution factors
bead_stockconc_pct = 1;
bead_dilutionfactor = 50;

% Model bead SOLUTIONS, both no dilution (stock) and diluted
BeadSolnStock = beadsoln_chem(Bead, bead_stockconc_pct, 1);
BeadDilutedSoln = beadsoln_chem(Bead, bead_stockconc_pct, bead_dilutionfactor);

% Load in the ligand chemistry info and populate with Wells and Beads
ligand_chem;

% Factor in 5x excess
SurfaceTable.ExcessReagentFactor = 5 * SurfaceTable.BeadMassConcentration_mgmL;

% Report SurfaceTable for quick reference
SurfaceTable
