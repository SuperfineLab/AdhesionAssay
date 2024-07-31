function Bclean = ba_clean_beadchem(B, BeadChemsToKeep)

idxFile = ismember(B.FileTable.BeadChemistry, BeadChemsToKeep);

Bclean.FileTable = B.FileTable(idxFile,:);
Bclean.FileTable.BeadChemistry = removecats(Bclean.FileTable.BeadChemistry);
Bclean.FileTable.BeadChemistry = reordercats(Bclean.FileTable.BeadChemistry, BeadChemsToKeep);

FidToKeep = Bclean.FileTable.Fid;

idxTime     = ismember(B.TimeHeightVidStatsTable.Fid, FidToKeep);
idxBead     = ismember(B.BeadInfoTable.Fid, FidToKeep);
idxTracking = ismember(B.TrackingTable.Fid, FidToKeep);
idxForce    = ismember(B.BeadForceTable.Fid, FidToKeep);
idxOptStart = ismember(B.OptimizedStartTable.BeadChemistry, BeadChemsToKeep);
idxForceFit = ismember(B.ForceFitTable.BeadChemistry, BeadChemsToKeep);
idxDetach   = ismember(B.DetachForceTable.BeadChemistry, BeadChemsToKeep);

Bclean.TimeHeightVidStatsTable = B.TimeHeightVidStatsTable(idxTime,:);
Bclean.BeadInfoTable           = B.BeadInfoTable(idxBead,:);
Bclean.TrackingTable           = B.TrackingTable(idxTracking,:);
Bclean.BeadForceTable          = B.BeadForceTable(idxForce,:);
Bclean.OptimizedStartTable     = B.OptimizedStartTable(idxOptStart,:);
Bclean.ForceFitTable           = B.ForceFitTable(idxForceFit,:);
Bclean.ForceFitTable.BeadChemistry    = removecats(Bclean.ForceFitTable.BeadChemistry);
Bclean.DetachForceTable        = B.DetachForceTable(idxDetach,:);
Bclean.DetachForceTable.BeadChemistry = removecats(Bclean.DetachForceTable.BeadChemistry);

end
