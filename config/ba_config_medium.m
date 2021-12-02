function outs = ba_config_medium(medium_type)
    
    if strcmpi(medium_type, 'int')
        medium_type = 'int25k';
    end

    switch lower(medium_type)

        case 'int25k'
            mName = 'Int';
            Name = ["Lactose", "Galactose", "GalNAc", "GlcNac", "Sialic Acid", "PEG20k"]';
            Conc = [0.0365, 0.0365, 0.0365, 0.0365, 0.0365, 0.1]';
            ConcUnits = ["mol/L", "mol/L", "mol/L", "mol/L", "mol/L", "mass fraction"]';                        
            Viscosity = 0.060;   % 06.20.2019 Data from CAP

        case 'intnana'
            mName = 'IntNANA';
            Name = ["Sialic Acid", "PEG20k"]';
            Conc = [0.0365, 0.1]';
            ConcUnits = ["mol/L", "mass fraction"]';
            Viscosity = 0.059; % Interpolated guess. Needs to be measured.

        case 'intglcnac'
            mName = 'IntGlcNAc';
            Name = ["GlcNac", "PEG20k"]';
            Conc = [0.0365, 0.1]';
            ConcUnits = ["mol/L", "mass fraction"]';
            Viscosity = 0.059; % Interpolated guess. Needs to be measured.
            
        case 'intgalnac'
            mName = 'IntGalNAc';
            Name = ["GalNac", "PEG20k"]';
            Conc = [0.0365, 0.1]';
            ConcUnits = ["mol/L", "mass fraction"]';
            Viscosity = 0.059; % Interpolated guess. Needs to be measured.
            
        case 'noint'
            mName = 'NoInt';
            Name = ["PEG20k"]';
            Conc = [0.1]';
            ConcUnits = ["mass fraction"]';
            Viscosity = 0.058;
            
        otherwise
            error('Unknown Medium type. Need new definition.');

    end
    
    outs = struct;
    outs.Name = mName;
    outs.Components  = table(Name, Conc, ConcUnits);
    outs.Viscosity = Viscosity;
