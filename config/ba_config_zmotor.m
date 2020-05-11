function Zmotor = ba_config_zmotor(CodeName)
% BA_CHECKMETADATA ensures the metadata structure matches the specification.
%

    switch CodeName
        case 'Z25B'
            Zmotor.StartingHeight = 12;
            Zmotor.Velocity = 0.2;
            Zmotor.SerialNumber = [];
        case 'Z12B'
            Zmotor.StartingHeight = 12;
            Zmotor.Velocity = 0.2;
            Zmotor.SerialNumber = [];
            error('This needs developing because we moved away from Ixion.');            
        otherwise
            error('Scope codename not recognized.');
    end
        

 
   