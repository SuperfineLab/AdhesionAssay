function good_image = classify_image(im)

readimage = imread(im);
centers = imfindcircles(readimage,[5 30]);
BeadNumber = numel(centers);
% NearestNeighborDist = cellfun(@nndist,num2cell(centers),'UniformOutput',false);
% MeanDist = cell2mat(cellfun(@(x1)mean(x1,'omitnan'),NearestNeighborDist,'UniformOutput',false));

if numel(centers) == 0
    good_image = "Error: 0 Count";
else
    average_dist = nndist(centers);
    sigma_f = sqrt((log10((BeadNumber)))^2*(0.00131769));
    f = (-0.5126*log10(BeadNumber)+2.747);
    if log10(average_dist) < (f - sigma_f)
        good_image = false;
    elseif log10(average_dist) >= (f - sigma_f)
        good_image = true;
    else
        disp("Numerical Error");
    end
end


