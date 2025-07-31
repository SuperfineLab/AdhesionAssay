function [cx,cy,sx,sy] = centerofmass(m)
% CENTEROFMASS Calculates the center of mass of an image
%
% Adhesion Assay
% **util**
%
%   [cx, cy, sx, sy] = CENTEROFMASS(m) computes the center of mass (cx, cy)
%   and standard deviation (sx, sy) along each axis of a 2D intensity matrix.
%   Pixel intensities are treated as weights.
%
% Inputs:
%   m  - 2D matrix (image), where pixel values represent intensity or weight
%
% Outputs:
%   cx - X-coordinate of the center of mass
%   cy - Y-coordinate of the center of mass
%   sx - Standard deviation in X-direction (spread)
%   sy - Standard deviation in Y-direction (spread)
%
% Example:
%   [cx, cy, sx, sy] = centerofmass(im);

% PURPOSE: find c of m for distribution

[sizey sizex] = size(m);

vx = sum(m);
vy = sum(m');

vx = vx.*(vx>0);
vy = vy.*(vy>0);

x = [1:sizex];
y = [1:sizey];

cx = sum(vx.*x)/sum(vx);
cy = sum(vy.*y)/sum(vy);
sx = sqrt(sum(vx.*(abs(x-cx).^2))/sum(vx));
sy = sqrt(sum(vy.*(abs(y-cy).^2))/sum(vy));
