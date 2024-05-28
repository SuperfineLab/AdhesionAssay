function ForceTable = ba_make_ForceTable(Data, weightstyle)
% BA_MAKE_FORCETABLE computes bead-level forces based on z-velocity
%
%   ForceTable = ba_make_ForceTable(Data, weightstyle)
%
% Outputs:
%    ForceTable - standard Table output for Adhesion Assay bead forces 
%
% Inputs:
%    Data - standard Table outputted from ba_process_expt/ba_load_raw_data
%    weightstyle - 
%

    if nargin < 2 || isempty(weightstyle)
        weightstyle = 'unweighted';
    end

    FileTable = Data.FileTable;
    
    for k = 1:height(FileTable)
    
       Fid = FileTable.Fid(k);
       visc_Pas = FileTable.MediumViscosity(k);
       calibum = FileTable.Calibum(k);   
       bead_diameter_um = FileTable.BeadExpectedDiameter(k); 
    
       myZtable = Data.TimeHeightVidStatsTable(Data.TimeHeightVidStatsTable.Fid == Fid,:);      
       myTracking = Data.TrackingTable(Data.TrackingTable.Fid == Fid, :);
    
       ForceTable{k} = ba_get_linefits(myTracking, calibum, visc_Pas, bead_diameter_um, Fid, weightstyle);  
       ForceTable{k}.ZmotorPos = interp1(myZtable.Time, myZtable.ZHeight, ForceTable{k}.Mean_time);
       ForceTable{k}.Properties.VariableUnits{'ZmotorPos'} = '[mm]';
       ForceTable{k}.Properties.VariableDescriptions{'ZmotorPos'} = 'Magnet z-distance from substrate in mm';

    end      
    
    ForceTable = vertcat(ForceTable{:});

    if isstring(ForceTable.SpotID)
        ForceTable.SpotID = double(ForceTable.SpotID);
    end

end

