function varargout = plate_space_move(ludl, calib, xyWellCoord, xyOffset_mm, platelayout) %(ludl, plate, wellcor)
% PLATE_SPACE_MOVE moves to the center of a given well

% centers - location of center of fiducial marks
%
% wellcor - well location on the well location grid in the format [row_num 
% column_num] (ex. [1 1] for the top left well nearest to fiducial mark 1)

if nargin < 5 || isempty(platelayout)
    platelayout = '15v2';
end

if nargin < 4 || isempty(xyOffset_mm) 
    logentry('No offset from well center defined. Assuming [0,0] mm.');
    xyOffset_mm = [0 0];
end

if nargin < 3 || isempty(xyWellCoord)
    error('Need well coordinate, either as [r c] or single number, while traveling down the rows.');
end

if numel(xyWellCoord) == 1
    xyWellCoord = ba_wellnum2rc(xyWellCoord);
end

xyLudlCoord = ba_plate2ludl(ludl, calib, xyWellCoord, xyOffset_mm, platelayout);

% Move the stage accordingly
% Note: x and y are reversed
stage_move_Ludl(ludl, xyLudlCoord);

switch nargout
    case 1
        varargout{1} = double(xyLudlCoord);
end

pause(0.5);

