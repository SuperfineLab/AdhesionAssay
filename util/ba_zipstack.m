function ba_zipstack(stack_folder, destination_folder, outfile)
% BA_ZIPSTACK Compresses a stack of images into a ZIP file for archiving
%
% Adhesion Assay
% **util**
%
%   BA_ZIPSTACK(stack_folder, destination_folder, outfile) compresses all
%   .pgm files in the specified stack_folder into a ZIP archive. If no
%   destination_folder or outfile name is specified, default values are
%   constructed from the input path.
%
% Inputs:
%   stack_folder       - String, path to folder containing frame*.pgm files
%   destination_folder - (Optional) String, directory where the ZIP file
%                        will be created. Defaults to parent of stack_folder
%   outfile            - (Optional) String, full path to output ZIP file.
%                        Defaults to [destination_folder / stack_folder].zip
%
% Outputs:
%   (none)
%
% Example:
%   ba_zipstack('myStackFolder');
%

if nargin < 1 || isempty(stack_folder)
    error('No Stack folder defined.');
end

sftmp = dir(stack_folder);

if ~isempty(sftmp)
    stack_folder = sftmp.folder;
else
    error('Stack not found. Incorrect filename?');
end

slashpos = regexp(stack_folder, filesep);

if nargin < 2 || isempty(destination_folder)
    destination_folder = stack_folder(1:slashpos(end)-1);
end

if nargin < 3 || isempty(outfile)
    outfile = [destination_folder, stack_folder(slashpos(end):end), '.zip'];
end

startdir = pwd;
cd(stack_folder);

filelist = dir('frame*.pgm');

if isempty(filelist)
    error('No images found. Bad directory name?');
end

filelistcell = {filelist.name};

% Use below to use system zip software
% XXX TODO implement below code for calling system zip software 
% XXX TODO Dont forget to check for system zip first
zip7 = @(d,z) (['"C:\Program Files\7-Zip\7z.exe" a -mmt8 -mx4 -tzip -y -r "' z '" "' d '/*"']);

system(zip7(stack_folder, outfile));

% To do a whole list of directories into zip files.
% cellfun(@(d,z) system(zip7(d,z)), dirlist, zipnames, 'uniformoutput',false)



% THIS IS PAINFULLY SLOW. INSTALL 7-ZIP.
% zip(outfile,filelistcell);

cd(startdir);

return
