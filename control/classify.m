function classification = classify(image)


fileloc = fullfile(image);
[centers, radii] = imfindcircles(fileloc,[5 30]);
BeadNumber = numel(centers);
NearestNeighborDist = cellfun(@nndist,centers,'UniformOutput',false);
MeanDist = cell2mat(cellfun(@(x1)mean(x1,'omitnan'),NearestNeighborDist,'UniformOutput',false));

if log10(MeanDist) < (-0.5118*log10(BeadNumber)+2.745)-0.020472
    classification = "bad";
elseif log10(MeanDist) < (-0.5118*log10(BeadNumber)+2.745)-0.020472
    classification = "good";
else
    disp("Error");
end

