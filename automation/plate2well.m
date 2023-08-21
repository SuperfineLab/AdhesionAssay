function [ActiveWell, xy_offset_mm] = plate2well(ludlscale, cal, ludlXY)
% Assigns ludl-coordinates to a well and provides polar-coordinates to that
% location in well-space (e.g., 1.25 [mm] at -90° would be 1.25 [mm] south 
% of the well's center).

pdef = cal.platedef;

% Well = [1:15];

[WellX, WellY] = meshgrid(1:5, 1:3);

PlateX = (WellX-1)*pdef.interwell_dist(1) + pdef.well_one_center(1);
PlateY = (WellY-1)*pdef.interwell_dist(2) + pdef.well_one_center(2);

% Locations of well centers in [mm] from center of top-left fiducial
xy = [ reshape(transpose(PlateX),15,1), reshape(transpose(PlateY),15,1) ];

% convert to ludl tick-locations based on scale and ludl location of
% top-left fiducial
well_centers_ticks = plate2ludl(ludlscale, cal, xy);

% Assign input xy to 'nearest well' and identify the position relative to 
% the well center in polar coordinates.
N = size(ludlXY,1);
[r_ticks, ActiveWell, phi_radians] = deal(NaN(N,1));
for k = 1:N
    pos = ludlXY(k,:);
    diffs_ticks = double(pos) - well_centers_ticks;
%     [r_ticks(k,1), ActiveWell(k,1)] = min(sqrt(sum((diffs_ticks).^2,2)));

    [~,ActiveWell(k,1)] = min(sum(abs(diffs_ticks),2));
    xyoffset_ticks(k,:) = diffs_ticks(ActiveWell(k,1),:);
%     xy_offset = diffs_ticks(ActiveWell(k,1),:);    
%     phi_radians(k,1) = atan2(well_offset(2), well_offset(1));
end

% Not sure where the bug is in the transform, but the ActiveWell
% calculation (a few lines above) is correct. In order to fix the
% coordinate space for the xy_offset, I need to negate and flip the
% outputted value.
xyoffset_ticks = -fliplr(xyoffset_ticks);
xy_offset_mm = tick2mm(ludlscale, xyoffset_ticks);


return