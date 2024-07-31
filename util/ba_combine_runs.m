function DataOut = ba_combine_runs(DataInA, DataInB)
% BA_COMBINE_RUNS concatenates bead-adhesion assay datasets.
%

repeatFID = intersect(DataInA.FileTable.Fid, DataInB.FileTable.Fid);
repeatPlateID = intersect(DataInA.FileTable.PlateID, DataInB.FileTable.PlateID);

if isempty(repeatFID) && isempty(repeatPlateID)
    DataOut.FileTable = [DataInA.FileTable; DataInB.FileTable];
    DataOut.TimeHeightVidStatsTable = [DataInA.TimeHeightVidStatsTable; DataInB.TimeHeightVidStatsTable];
    DataOut.BeadInfoTable = [DataInA.BeadInfoTable; DataInB.BeadInfoTable];
    DataOut.TrackingTable = [DataInA.TrackingTable; DataInB.TrackingTable];
    DataOut.BeadForceTable = [DataInA.BeadForceTable; DataInB.BeadForceTable];
    DataOut.OptimizedStartTable = [DataInA.OptimizedStartTable; DataInB.OptimizedStartTable];
    DataOut.ForceFitTable = [DataInA.ForceFitTable; DataInB.ForceFitTable];
    DataOut.DetachForceTable = [DataInA.DetachForceTable; DataInB.DetachForceTable];
else
    error('Repeat FID. Likely the data are already combined. Data cannot be further combined.');
end
