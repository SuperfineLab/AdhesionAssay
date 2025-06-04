function outs = ba_unpack_tiff(tif_filename, stack_path)
% BA_UNPACK_TIFF Converts a multi-page TIFF into an image stack
%
% Adhesion Assay
% util
%
%   outs = BA_UNPACK_TIFF(tif_filename, stack_path) reads a multi-page
%   .tif file and writes each frame as a separate .pgm file in the
%   specified output directory.
%
% Inputs:
%   tif_filename - String, path to the input .tif file (must end in '.tif')
%   stack_path   - Optional string, name of output directory to save the
%                  unpacked image stack. Defaults to tif_filename name
%                  without '.tif' extension.
%
% Outputs:
%   outs - (Currently unused) Placeholder for future return values or
%          function extension. Presently returns nothing.
%
% Example:
%   ba_unpack_tiff('experiment01_stack.tif');
%


    if nargin < 1 || isempty(tif_filename) || ~contains(tif_filename, '.tif')
        error('No file defined or file does not end with a ".tif" extension.');
    end

    if nargin < 2 || isempty(stack_path)
        stack_path = strrep(tif_filename, '.tif', '');
    end
    
    nfo = imfinfo(tif_filename);

    if isempty(nfo)
        error('No image info for filename input.');
    end

    rootdir = pwd;

    mkdir(stack_path);


    for k =  1:length(nfo)
        im = imread(tif_filename, k); 
        basename = ['frame' num2str(k,'%04u') '.pgm'];
        myfile = fullfile(rootdir, stack_path, basename);
        disp(['Saving ' myfile]);
        imwrite(im, myfile, 'pgm'); 
    end
    
    return
    