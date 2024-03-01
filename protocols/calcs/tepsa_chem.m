% TEPSA needed to coat a single well based on physical size of TEPSA
NA = 6.022e23;

TEPSA.Area_nm2 = 1.4; % [nm^2]  https://www.google.com/books/edition/Silanes_and_Other_Coupling_Agents_Volume/G7jNBQAAQBAJ?hl=en&gbpv=1&dq=10.1163/ej.9789004165915.i-348.16&pg=PA25&printsec=frontcover
TEPSA.MolWt_gmol = 13*12 + 24 + 6 * 16 + 28.1; % C13H24O6Si
TEPSA.NumberPerWell = Well.Area_nm2/TEPSA.Area_nm2;
TEPSA.MolesPerWell = TEPSA.NumberPerWell ./ NA; % [moles]
TEPSA.MassPerWell = TEPSA.MolesPerWell * TEPSA.MolWt_gmol; % [grams]