function A = triarea(t, p)
% A = TRIAREA(t, p) area of triangles in triangulation
Xt = reshape(p(t, 1), size(t)); % X coordinates of vertices in triangulation
Yt = reshape(p(t, 2), size(t)); % Y coordinates of vertices in triangulation
A = 0.5 * abs((Xt(:, 2) - Xt(:, 1)) .* (Yt(:, 3) - Yt(:, 1)) - ...
(Xt(:, 3) - Xt(:, 1)) .* (Yt(:, 2) - Yt(:, 1)));
