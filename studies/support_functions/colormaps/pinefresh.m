function map = pinefresh(cnum)
% PINEFRESH colormap in a green-yellow space
%
% Adhesion Assay
% Analysis
%
% Generates a colormap in a green-yellow space. Raw color data pulled from 
% colorbrewer.
%
% map = pinefresh(cnum)
%
% Output:
%   map contains the outputted colormap, size [CNUM, 3]
%
% Input:
%   cnum is the number of colors (rows) desired for the interpolated colormap
%

%   Functions: Custom Colormaps (schema came from colorbrewer)
    cbmap = ... [255,255,255;
             [255,255,204; 
             194,230,153;
             120,198,121;
             49,163,84;
             0,104,55];
    icbmap = interpcmap(cbmap, cnum);
    map = [0 0 0; icbmap];
end






