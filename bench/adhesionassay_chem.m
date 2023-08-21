% adhesion assay chemistry setup

well_diameter_mm = 9;
well_volume_mL = 0.06;
Well = well_chem(well_diameter_mm, well_volume_mL);

tepsa_chem;

bead_diameter_um = 23.7;
bead_density_kgm3 = 1150;
Bead = bead_chem(bead_diameter_um, bead_density_kgm3);

bead_stockconc_pct = 1;
bead_dilutionfactor = 10;

BeadSolnStock = beadsoln_chem(Bead, bead_stockconc_pct, 1);
BeadSolnDilutedSoln = beadsoln_chem(Bead, bead_stockconc_pct, bead_dilutionfactor);

ligand_chem;

SurfaceTable.ExcessReagentFactor = 0.2./SurfaceTable.BeadMassConcentration_mgmL