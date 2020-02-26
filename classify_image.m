function classification = classify_image(image)

readimage = imread(image);
[centers radii] = imfindcircles(readimage,[5 30]);
BeadNumber = numel(centers);
NearestNeighborDist = cellfun(@neardist,centers,'UniformOutput',false);
MeanDist = cell2mat(cellfun(@(x1)mean(x1,'omitnan'),NearestNeighborDist,'UniformOutput',false));
nearest_neighbor_dist = [];
for k = 1:numel(centers)
    mindist = 1000;
    for l = 1:numel(centers)
        if k ~= l
            dist = sqrt((centers(l,2)-centers(k,2))^2 + (centers(l,1)-centers(k,1))^2);
        end
    end
end
if log10(MeanDist) < (-0.5118*log10(BeadNumber)+2.745)-0.020472
    classification = "bad";
elseif log10(MeanDist) < (-0.5118*log10(BeadNumber)+2.745)-0.020472
    classification = "good";
else
    disp("Error");
end

