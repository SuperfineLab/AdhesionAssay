function A = triarea(t, p)
% TRIAREA Computes the area of triangles in a triangulation
%
% Adhesion Assay
% **util**
%
%   A = TRIAREA(t, p) returns the area of each triangle defined by vertex
%   indices in t and corresponding vertex coordinates in p.
%
% Inputs:
%   t - M-by-3 matrix of indices into p, defining triangle connectivity
%   p - N-by-2 matrix of vertex coordinates (X, Y) for each point
%
% Outputs:
%   A - M-by-1 vector of areas for each triangle
%
% Example:
%   A = triarea(tri, points);
%

% A = TRIAREA(t, p) area of triangles in triangulation
Xt = reshape(p(t, 1), size(t)); % X coordinates of vertices in triangulation
Yt = reshape(p(t, 2), size(t)); % Y coordinates of vertices in triangulation
A = 0.5 * abs((Xt(:, 2) - Xt(:, 1)) .* (Yt(:, 3) - Yt(:, 1)) - ...
(Xt(:, 3) - Xt(:, 1)) .* (Yt(:, 2) - Yt(:, 1)));
