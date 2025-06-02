function newFileTable = ba_calc_BeadsLeft(Data)
% BA_CALC_BEADSLEFT calculates remaining beads during video pull-offs
%
% Adhesion Assay
% Analysis
%
% Number of stuck beads is equal to the starting number of beads minus
% the number of Force approximations we made during our tracking
% clean-up for the velocity calculation.

    newFileTable = Data.FileTable;
    BeadForceTable = Data.BeadForceTable;

    LastFrameBeadCount = NaN(height(newFileTable),1);

    for k = 1:height(newFileTable)
        Fid = newFileTable.Fid(k);
        FirstFrameBeadCount = newFileTable.FirstFrameBeadCount(k);
    
        myForceTable = BeadForceTable( BeadForceTable.Fid == Fid, :);
        LastFrameBeadCount(k,1) = FirstFrameBeadCount - height(myForceTable);       
    end

    newFileTable.LastFrameBeadCount = LastFrameBeadCount;

end
