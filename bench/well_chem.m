function Well = well_chem(well_diameter_mm, well_volume_mL)

if nargin < 2 || isempty(well_volume_mL)
    well_volume_mL = 0.06;
end

if nargin < 1 || isempty(well_diameter_mm)
    well_diameter_mm = 9;
end

NA = 6.023e23;

% Well info
Well.Diameter_mm = well_diameter_mm; % [mm]
Well.Volume_mL = well_volume_mL; % [mL]
Well.Area_m2 =  pi * (Well.Diameter_mm*1e-3/2) .^ 2; % [m^2]
Well.Area_um2 = Well.Area_m2 * (1e6^2); % [um^2]
Well.Area_nm2 = Well.Area_m2 * (1e9^2); % [nm^2]
Well.OHPerArea = 2; % [-OH/nm^2]
Well.OHPerWell = Well.Area_nm2 * Well.OHPerArea;
Well.MolesOHPerWell = Well.OHPerWell / NA;
Well.TEPSASites = Well.OHPerWell/3;
Well.COOHSites = Well.TEPSASites * 2;

% TEPSA needed to coat a single well based on physical size of TEPSA
TEPSA.Area_nm2 = 1.4; % [nm^2]  https://www.google.com/books/edition/Silanes_and_Other_Coupling_Agents_Volume/G7jNBQAAQBAJ?hl=en&gbpv=1&dq=10.1163/ej.9789004165915.i-348.16&pg=PA25&printsec=frontcover
TEPSA.MolWt_gmol = 13*12 + 24 + 6 * 16 + 28.1; % C13H24O6Si
TEPSA.NumberPerWell = Well.Area_nm2/TEPSA.Area_nm2;
TEPSA.MolesPerWell = TEPSA.NumberPerWell ./ NA; % [moles]
TEPSA.MassPerWell = TEPSA.MolesPerWell * TEPSA.MolWt_gmol; % [grams]

