function xyLudl_ticks = ba_plate2ludl(ludl, cal, xyWellCoord, xyOffset_mm, platelayout)
% BA_PLATE2LUDL converts plate locations to Ludl coords given a calibration
%

% ludl - handle to ludl stage
% cal - output from stage_center
%
% wellcor - well location on the well location grid in the format [row_num 
% column_num] (ex. [1 1] for the top left well nearest to fiducial mark 1)
%
% movegrid - an optional parameter which indicates where the view should
% be moved relative to the center of the well in units of millimeters

% Selecting Well-Layout
if nargin < 5 || isempty(platelayout)
    platelayout = '15v2';
end

if nargin < 4 || isempty(xyOffset_mm)
    xyOffset_mm = [0 0];
end

if numel(xyWellCoord) == 2
    xyWellNum = ba_wellrc2num(xyWellCoord);
elseif numel(xyWellCoord) == 1
    xyWellNum = xyWellCoord;
else
    error('Well designation is malformed.');
end

reshtrans = @(x)(reshape(transpose(x),[],1));

plate = platedef(platelayout);

% % Determining Distances
[cid, rid] = meshgrid(1:5,1:3);

xycenters(:,1) = reshtrans(plate.well_one_center(1) + plate.interwell_dist(1) * (cid-1));
xycenters(:,2) = reshtrans(plate.well_one_center(1) + plate.interwell_dist(2) * (rid-1));

platexy_mm = xycenters(xyWellNum,:) + xyOffset_mm;

theta = cal.theta;

xyLudl_ticks = plate2ludl(ludl.scale, cal, platexy_mm);

return

