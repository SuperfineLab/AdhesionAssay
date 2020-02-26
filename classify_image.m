function classification = classify_image(image)

readimage = imread(image);
[centers] = imfindcircles(readimage,[5 30]);
BeadNumber = numel(centers);
% NearestNeighborDist = cellfun(@neardist,num2cell(centers),'UniformOutput',false);
% MeanDist = cell2mat(cellfun(@(x1)mean(x1,'omitnan'),NearestNeighborDist,'UniformOutput',false));
nearest_neighbor_dist = [];
if numel(centers) == 0
    classification = "Error: 0 Count";
else
    for m = 1:numel(BeadNumber)
        mindist = 1000;
        for l = 1:numel(BeadNumber)
            if l ~= m
                dist = sqrt((centers(l,2)-centers(m,2))^2 + (centers(l,1)-centers(m,1))^2);
                if dist < mindist
                    mindist = dist;
                end
            end   
        end
        nearest_neighbor_dist = [nearest_neighbor_dist mindist]; 
    end
    average_dist = mean(nearest_neighbor_dist);
    sigma_f = sqrt((log10((BeadNumber)))^2*(0.02356)+0.0256);
    f = (-0.5118*log10(BeadNumber)+2.745);
    if log10(average_dist) < (f - sigma_f);
        classification = "bad";
    elseif 10^average_dist >= (f - sigma_f);
        classification = "good";
    else
        disp("Numerical Error");
    end
end


