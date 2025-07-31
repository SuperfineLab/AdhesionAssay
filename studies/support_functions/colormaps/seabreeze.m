function map = seabreeze(cnum)
% SEABREEZE colormap in the blue-green space
%
% Adhesion Assay
% Analysis
%
% Generates a colormap in the blue-green space. Raw color data pulled from 
% colorbrewer.
%
% map = seabreeze(cnum)
%
% Output:
%   map contains the outputted colormap, size [CNUM, 3]
%
% Input:
%   cnum is the number of colors (rows) desired for the interpolated colormap
%

    cbmap = ... [255,255,255;
             [240,249,232; 
             186,228,188; 
             123,204,196; 
             67,162,202; 
             8,104,172];
    map = interpcmap(cbmap, cnum);
end
