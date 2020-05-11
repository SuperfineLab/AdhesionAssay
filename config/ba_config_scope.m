function Scope = ba_config_scope(CodeName)
% BA_CHECKMETADATA ensures the metadata structure matches the specification.
%
    switch CodeName
        case 'Artemis'
            Scope.Name = 'Nikon TE-2000E';
            Scope.CodeName = CodeName;
            Scope.Magnification = 10;
            Scope.Magnifier = 1;
            Scope.Calibum = NaN;
        case 'Ixion'
            Scope.Name = 'Olympus IX-71';
            Scope.CodeName = CodeName;
            Scope.Magnification = 10;
            Scope.Magnifier = 1;
            Scope.Calibum = 0.346;
            error('This may need developing because we moved away from Ixion.');
        otherwise
            error('Scope codename not recognized.');
    end



