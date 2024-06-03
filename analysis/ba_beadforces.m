function BeadForceTable = ba_beadforces(Data, weightstyle)
% BA_BEADFORCES computes bead-level forces based on z-velocity
%
%   BeadForceTable = ba_beadforces(Data, weightstyle)
%
% Outputs:
%    BeadForceTable - standard Table output for Adhesion Assay bead forces 
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
    
       BeadForceTable{k} = ba_get_linefits(myTracking, calibum, visc_Pas, bead_diameter_um, Fid, weightstyle);  
       BeadForceTable{k}.ZmotorPos = interp1(myZtable.Time, myZtable.ZHeight, BeadForceTable{k}.Mean_time);
       BeadForceTable{k}.Properties.VariableUnits{'ZmotorPos'} = '[mm]';
       BeadForceTable{k}.Properties.VariableDescriptions{'ZmotorPos'} = 'Magnet z-distance from substrate in mm';

    end      
    
    BeadForceTable = vertcat(BeadForceTable{:});

    if isstring(BeadForceTable.SpotID)
        BeadForceTable.SpotID = double(BeadForceTable.SpotID);
    end

end

