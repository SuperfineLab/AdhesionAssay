function s = tenegrad( im )
% TENEGRAD calculates a focus score for an image using Sobel filter.
%
% Tenegrad score = 1/n sum (sx.^2 + sy.^2), where
%  n is the pixel-count, im is a 2D intensity image, and
%  gx and gy are the 5x5 horizontal and vertical Sobel filter responses.
%
% s = tenegrad(im);
%
% Reference: https://en.wikipedia.org/wiki/Sobel_operator
% 

gx = [1, 2, 0, -2, -1 ; ...
      4, 8, 0, -8, -4 ; ...
      6,12, 0,-12, -6 ; ...
      4, 8, 0, -8, -4 ; ...
      1, 2, 0, -2, -1]; 
  
gy = transpose(gx);

n = numel(im);

filtresp =   imfilter(im, gx, 'replicate', 'conv').^2 ...
           + imfilter(im, gy, 'replicate', 'conv').^2;
       
s = (1/n) * sum(filtresp(:));

return