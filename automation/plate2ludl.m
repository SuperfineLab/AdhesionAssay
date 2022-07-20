function ludlxy_ticks = plate2ludl(ludl, cal, plate_xycoord_mm)
% ludlxy_ticks = platexy_mm2ludlxy_ticks(ludl, cal, plate_xycoord_mm)

pxy = plate_xycoord_mm;

% platespec = cal.platedef;
theta = cal.theta;

R_pxy_mm = rot2d(pxy, theta);

R_pxy_ticks = mm2tick(ludl, R_pxy_mm);

ludl_origin_ticks = cal.centers(1,:);

ludlxy_ticks = ludl_origin_ticks - fliplr(R_pxy_ticks);

return

% function movegrid_ludl = plate2ludl(ludl, movegrid_plate)
%     movegrid_ludl = mm2tick(ludl, [-movegrid_plate(2) movegrid_plate(1)]);

function [Rplatexy] = rot2d(platexy, theta)
%ROT2D Return 2D rotation matrix
%   Returns matrix that rotates a column vector by angle a (in radians).
%   Example 1: v=[1;1]; w=rot2d(pi/4)*v; {w now = [0;1.414]}
%   Example 2: Rotate 3 (or more) [x;y] pairs at a time: 
%       v1=[1,0]; v2=[1;1]; v3=[0;1]; vc=[v1,v2,v3]; wc=rot2d(pi/6)*vc;
%   The examples show the correct multiplication order.
%   Note that this is not the matrix to use if you want to express a
%   vector in terms of a coordinate system rotated by angle a. 
%   Use w=inv(rot2d(a))*v to express vector v in a coordinate system
%   rotated by a.
    R = [cos(theta),-sin(theta);sin(theta),cos(theta)];
%     Rplatexy = inv(R) * platexy;
    Rplatexy(1,:) = inv(R) \ platexy(:);
return