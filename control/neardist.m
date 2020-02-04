function out = neardist(c)

if isempty(c)
    out = [];
    return
end

x = c(:,1);
y = c(:,2);

X = repmat(x, 1, numel(x));
Y = repmat(y, 1, numel(y));

Xdist = X - transpose(X);
Ydist = Y - transpose(Y);

dist = sqrt(Xdist.^2 + Ydist.^2);

dist( dist == 0 ) = NaN;

out(:,1) = min(dist, [], 'omitnan');
