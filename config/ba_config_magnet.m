function Magnet = ba_config_magnet(MagnetGeometry)
% BA_CONFIG_MAGNET configures magnetics geometry for Adhesion Assay
%

    switch lower(MagnetGeometry)
        case 'cone'
            Magnet.Geometry = MagnetGeometry;
            Magnet.Size = '0.25 inch radius';
            Magnet.Material = 'rare-earth magnet (neodymium)';
            Magnet.PartNumber = 'Cone0050N';
            Magnet.Supplier = 'www.supermagnetman.com';
            Magnet.Notes = 'Right-angle cone, radius 0.25 inch, north-pole at tip';
        case 'softironcone'
            Magnet.Geometry = MagnetGeometry;
            Magnet.Size = '0.25 inch radius';
            Magnet.Material = 'softiron';
            Magnet.PartNumber = 'N/A';
            Magnet.Supplier = 'UNC physics shop';
            Magnet.Notes = 'Right-angle cone, radius 0.25 inch, softiron';  
        case 'pincer'
            Magnet.Geometry = MagnetGeometry;
            Magnet.Size = 'gap is approx 2 mm';
            Magnet.Material = 'soft-iron';
            Magnet.PartNumber = 'N/A';
            Magnet.Supplier = 'UNC physics shop';
            Magnet.Notes = 'Original magnet design by Max DeJong with softiron pincer-stylt tips and rare-earth magnet (neodymium) rectangular prism magnets on the back end.';
        otherwise
            error('Magnet geometry not recognized.');
    end
    
