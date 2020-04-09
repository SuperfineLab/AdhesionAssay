function h = ba_thorgui(ScopeCodeName)
% BA_THORGUI initializes the Thorlabs z-motor and opens the ThorLabs UI.
%

if nargin < 1 || isempty(ScopeCodeName)
    ScopeCodeName = 'Artemis';
end

    h = ba_initz(ScopeCodeName,true);

    