function m = well_metadata_script(row,col)
% WELL_METADATA_SCRIPT(row,col) takes an input file generated using the
% well layout software and turns it into a .m file

% row - refers to the row value of the well, takes values [1, 2, 3]
% col - refers to the column value of the well, takes values [1, 2, 3, 4,
% 5]

%% Unpacking independent variables from file

% Import the file and prune out data not pertaining to given well
ivarfile = 'D:\data\test.csv'; % For test purposes only! Replace with real file name! :)
ivar = ba_read_plate_layout(ivarfile);

% Rename rows to letters
switch row
    case 1
        row_letter = 'A';
    case 2
        row_letter = 'B';
    case 3
        row_letter = 'C';
    otherwise
        disp('Error: Invalid row')
end

% Keep only data for given well
rows = [];
k = 1;

while k <= height(ivar)
   if ~((categorical(ivar{k,'PlateRow'}) == row_letter) && (ivar{k,'PlateColumn'} == col))
        rows = [rows, k];
   end
   k = k + 1;
end

ivar(rows,:) = [];

clear k rows

% Pull independent variables for 'File' for given well
filename = ivar_extract(ivar,'SampleName');
SampleInstance = ivar_extract(ivar, 'SampleInstance');
binfilename = ivar_extract(ivar, 'BinFile');
incubationstarttime = ivar_extract(ivar, 'IncubationStartTime');

% Pull independent variables for 'Substrate' for given well
SubstrateChemistry = 'SubstrateChemistry_test'; % CHANGE DUMMY VARIABLE!
%SubstrateChemistry = ivar_extract(ivar, 'SubstrateChemistry');

% Pull independent variables for 'Bead' for given well
BeadChemistry = 'BeadChemistry_test'; % CHANGE DUMMY VARIABLE!
%BeadChemistry = ivar_extract(ivar, 'BeadChemistry');

%% Putting together the initial metadata file

% Constants for 'File'
[~,host] = system('hostname');

% Creating 'File' category
m.File.SampleName = filename;   
m.File.SampleInstance = SampleInstance;   
m.File.Binfile = binfilename;  
m.File.Binpath = pwd;
m.File.Hostname = strip(host);
m.File.IncubationStartTime = incubationstarttime;   
   
% Creating 'Scope' category
m.Scope.Name = 'Olympus IX-71';
m.Scope.CodeName = 'Ixion';
m.Scope.Magnification = 10;
m.Scope.Magnifier = 1;
m.Scope.Calibum = 0.346;

% Creating 'Video' category
m.Video.ExposureMode = 'off'; 
m.Video.FrameRateMode = 'off';
m.Video.ShutterMode = 'manual';
m.Video.Gain = 10;
m.Video.Gamma = 1.15;
m.Video.Brightness = 5.8594;
m.Video.Height = 768;
m.Video.Width = 1024;
m.Video.Depth = 16;

% Creating 'Zmotor' category
m.Zmotor.StartingHeight = 12;
m.Zmotor.Velocity = 0.2; % [mm/sec]

% Creating 'Medium' category -> NEEDS ITS OWN CONFIG FILE
m.Medium.Null = '';     % Placeholder
m.Medium.Buffer = 'PBS';

% Creating 'Substrate' category
m.Substrate.SurfaceChemistry = SubstrateChemistry;
m.Substrate.Size = '50x75x1 mm';
m.Substrate.LotNumber = 'SubstrateLot_test';

% Constants for 'Bead'
PSF_filename = 'D:\pramoj23\src\AdhesionAssay\calib\psf\mag_10x_bead_24umdiaYG_stepsize_1um.psf.tif';
impsf = imread(PSF_filename);

% Creating 'Bead' category
m.Bead.Diameter = 24;
m.Bead.SurfaceChemistry = BeadChemistry;
m.Bead.PointSpreadFunction = impsf;
m.Bead.PointSpreadFunctionFilename = PSF_filename;

% Constants for 'Magnet'
MagnetGeometry = 'cone';

% Creating 'Magnet' category
switch lower(MagnetGeometry)
    case 'cone'
        m.Magnet.Geometry = 'cone';
        m.Magnet.Size = '0.25 inch radius';
        m.Magnet.Material = 'rare-earth magnet (neodymium)';
        m.Magnet.PartNumber = 'Cone0050N';
        m.Magnet.Supplier = 'www.supermagnetman.com';
        m.Magnet.Notes = 'Right-angle cone, radius 0.25 inch, north-pole at tip';
    case 'softironcone'
        m.Magnet.Geometry = 'softironcone';
        m.Magnet.Size = '0.25 inch radius';
        m.Magnet.Material = 'softiron';
        m.Magnet.PartNumber = 'N/A';
        m.Magnet.Supplier = 'UNC physics shop';
        m.Magnet.Notes = 'Right-angle cone, radius 0.25 inch, softiron';        
    case 'pincer'
        m.Magnet.Geometry = 'orig';
        m.Magnet.Size = 'gap is approx 2 mm';
        m.Magnet.Material = 'soft-iron';
        m.Magnet.PartNumber = 'N/A';
        m.Magnet.Supplier = 'UNC physics shop';
        m.Magnet.Notes = 'Original magnet design by Max DeJong with softiron pincer-stylt tips and rare-earth magnet (neodymium) rectangular prism magnets on the back end.';
end    

% Saving config data as a .mat file
save([filename, '.meta.mat'], '-STRUCT', 'm');

return

function value = ivar_extract(ivarTable,var)

k = 1;

while k <= height(ivarTable)
    if ivarTable{k,'Field_name'} == var
       value = convertStringsToChars(ivarTable{k,'Value'});
       break
    end
    k = k + 1;
end

