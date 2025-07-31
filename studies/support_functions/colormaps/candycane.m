function map = candycane(cnum)
% CANDYCANE colormap in a red-white space
%
% Adhesion Assay
% Analysis
%
% Generates a colormap in a red-white space. Raw color data pulled from 
% colorbrewer.
%
% map = candycane(cnum)
%
% Output:
%   map contains the outputted colormap, size [CNUM, 3]
%
% Input:
%   cnum is the number of colors (rows) desired for the interpolated colormap
%

  cbmap = ... [255,255,255;
             [241,238,246;
             215,181,216;
             223,101,176;
             221,28,119;
             152,0,67];
%     cbmap = [255,255,255;
%              255,0,0];
     map = interpcmap(cbmap, cnum);     
end
