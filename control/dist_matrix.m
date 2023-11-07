function dist = dist_matrix(c)
% NNDIST calculates the distance matrix given a list of XY values
%
% Usage: dist = dist_matrix(c), where c is a 2-column matrix of positions
% in [X Y].
%
% The output "dist" is a symmetric matrix with distances in point order
% along the rows and columns, e.g., dist(1,1) contains the distance of the
% first point from itself and dist(1,2) contains the distance of the first
% point from the second.
%

if isempty(c)
    dist = NaN;
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

