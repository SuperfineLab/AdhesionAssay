function mm = ba_checkmetadata(m)
% BA_CHECKMETADATA ensures the metadata structure matches the specification.
%

    % Order everything so it can be aggregated later
    mm = orderfields(m, {'PlateID', 'File', 'Bead', 'Substrate', 'Medium', 'Zmotor', 'Magnet', 'Scope', 'Video', 'Results'});
    mm.File = orderfields(mm.File, {'Fid', 'Well', 'SampleName', 'SampleInstance', 'Binfile', 'Binpath', 'Hostname', 'IncubationStartTime'});
    mm.Bead = orderfields(mm.Bead, {'Diameter', 'SurfaceChemistry', 'LotNumber', 'PointSpreadFunction', 'PointSpreadFunctionFilename'});    
    mm.Substrate = orderfields(mm.Substrate, {'Material', 'Size', 'Silane', 'SurfaceChemistry', 'Concentration_mgmL', 'LotNumber'});    
    mm.Medium = orderfields(mm.Medium, {'Name', 'ManufactureDate', 'Viscosity', 'pH', 'Components', 'Buffer'});
    mm.Zmotor = orderfields(mm.Zmotor, {'StartingHeight', 'Velocity'});
    mm.Magnet = orderfields(mm.Magnet, {'Geometry', 'Size', 'Material', 'PartNumber', 'Supplier', 'Notes'});
    mm.Scope = orderfields(mm.Scope, {'Name', 'CodeName', 'Magnification', 'Magnifier', 'Calibum'});    
    mm.Video = orderfields(mm.Video, {'ExposureMode', 'FrameRateMode', 'ShutterMode', 'Gain', 'Gamma', 'Brightness', 'Format', 'Height', 'Width', 'Depth', 'ExposureTime'});
    mm.Results = orderfields(mm.Results, {'ElapsedTime', 'TimeHeightVidStatsTable', 'FirstFrame', 'LastFrame'});

end
