function ba_unzipstack(zipfile, destination_folder)
% BA_UNZIPSTACK Extracts a stack of images from a ZIP archive
%
% Adhesion Assay
% **util**
%
%   BA_UNZIPSTACK(zipfile, destination_folder) extracts a .zip archive
%   into a new folder. The ZIP file should contain image stack files
%   (e.g., frame*.pgm). If destination_folder is not provided, it is
%   inferred from the ZIP file name.
%
% Inputs:
%   zipfile            - String, path to the .zip archive to extract
%   destination_folder - (Optional) String, path to the output folder.
%                        Defaults to [zipfile name without extension].
%
% Outputs:
%   (none)
%
% Example:
%   ba_unzipstack('experiment01_stack.zip');
%

startdir = pwd;

if nargin < 1 || isempty(zipfile)
    error('No zip file defined.');
end

zipfile = dir(zipfile);

if isempty(zipfile)
    error('Zip file not found.');
elseif numel(zipfile) > 1
    error('Cannot run on multiple zip files (yet).');     
end

zname = zipfile.name;

if nargin < 2 
    destination_folder = zname(1:end-4);
end

dftmp = dir(destination_folder);
if ~isempty(dftmp)
    error('Destination folder already exists.');   
end
    
cd(zipfile.folder);


% Use below to use system zip software
% XXX TODO implement for below code calling system zip software 
% XXX TODO Dont forget to check for system zip first
zip7 = @(z,d) (['"C:\Program Files\7-Zip\7z.exe" -mmt8 -tzip -y e "' z '" -o"' d '"']);

system(zip7(zname, destination_folder));

% To do a whole list of directories into zip files.
% cellfun(@(d,z) system(zip7(d,z)), dirlist, zipnames, 'uniformoutput',false)



% THIS IS PAINFULLY SLOW. INSTALL 7-ZIP.
% zip(outfile,filelistcell);

cd(startdir);

return
