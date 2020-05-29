function nn = nndist(c)
% NNDIST calculates the nearest-neighbor distance given a list of XY values
%
% Usage: nn = nndist(c), where c is a 2-column matrix of positions in [X Y]
%
if isempty(c)
    nn = NaN;
    return
end

x = c(:,1);
y = c(:,2);

% Tile out the positions into a square matrix
X = repmat(x, 1, numel(x));
Y = repmat(y, 1, numel(y));

% X and Y distances from other beads
Xdist = X - transpose(X);
Ydist = Y - transpose(Y);
dist = sqrt(Xdist.^2 + Ydist.^2);

% Eliminate the zeros along the diagonal
dist( dist == 0 ) = NaN;

% The nearest neighbor for each bead is the minimum distance along each row
nn(:,1) = min(dist, [], 'omitnan');

