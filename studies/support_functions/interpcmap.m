function outs = interpcmap(map, cnum)
% INTERPCMAP interpolates a colormap based on input map and output count
%
% Adhesion Assay
% Analysis
%
% Interpolates a colormap to a given number of values. Useful for
% quantizing gradient outputs (e.g., from colorbrewer)
%
% outs = interpcmap(map, cnum)
%
% Output:
%   outs contains the outputted colormap, size [CNUM, 3]
%
% Input:
%   map is an Nx3 input colormap containing N "key-colors"
%   cnum is the number of colors (rows) desired for the interpolated colormap
%

    map = map ./ 255;
    sampleN = size(map,1);
    xnew = linspace(1,sampleN,cnum);

    outs = interp1(map, xnew);
    outs(1,:) = [1,1,1];
end