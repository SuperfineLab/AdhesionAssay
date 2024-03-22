function ForceTable = ba_make_ForceTable(Data)

    FileTable = Data.FileTable;
    
    for k = 1:height(FileTable)
    
       Fid = FileTable.Fid(k);
       visc_Pas = FileTable.MediumViscosity(k);
       calibum = FileTable.Calibum(k);   
       bead_diameter_um = FileTable.BeadExpectedDiameter(k); 
    
       myZtable = Data.TimeHeightVidStatsTable(Data.TimeHeightVidStatsTable.Fid == Fid,:);      
       myTracking = Data.TrackingTable(Data.TrackingTable.Fid == Fid, :);
    
       ForceTable{k} = ba_get_linefits(myTracking, calibum, visc_Pas, bead_diameter_um, Fid);  
       ForceTable{k}.ZmotorPos = interp1(myZtable.Time, myZtable.ZHeight, ForceTable{k}.Mean_time);
       ForceTable{k}.Properties.VariableUnits{'ZmotorPos'} = '[mm]';
       ForceTable{k}.Properties.VariableDescriptions{'ZmotorPos'} = 'Magnet z-distance from substrate in mm';

    end      
    
    ForceTable = vertcat(ForceTable{:});

    if isstring(ForceTable.SpotID)
        ForceTable.SpotID = double(ForceTable.SpotID);
    end

end

