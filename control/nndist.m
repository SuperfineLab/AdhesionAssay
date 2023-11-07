function nn = nndist(c)
% NNDIST calculates the nearest-neighbor distance given a list of XY values
%
% Usage: nn = nndist(c), where c is a 2-column matrix of positions in [X Y]
%
if isempty(c)
    nn = NaN;
    return
end

dist = distmatrix(c);

dist( dist == 0 ) = NaN;

% The nearest neighbor for each bead is the minimum distance along each row
nn(:,1) = min(dist, [], 'omitnan');

