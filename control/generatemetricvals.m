 function logavgdist = logavgdist(im) 

%readimage = imread(im);
[centers] = imfindcircles(im,[5 30]);
BeadNumber = numel(centers);
% NearestNeighborDist = cellfun(@nndist,num2cell(centers),'UniformOutput',false);
% MeanDist = cell2mat(cellfun(@(x1)mean(x1,'omitnan'),NearestNeighborDist,'UniformOutput',false));
nearest_neighbor_dist = [];
if numel(centers) == 0
    good_image = "Error: 0 Count";
else
%     for m = 1:numel(BeadNumber)
%         mindist = 1000;
%         for l = 1:numel(BeadNumber)
%             if l ~= m
%                 dist = sqrt((centers(l,2)-centers(m,2))^2 + (centers(l,1)-centers(m,1))^2);
%                 if dist < mindist
%                     mindist = dist;
%                 end
%             end   
%         end
%         nearest_neighbor_dist = [nearest_neighbor_dist mindist]; 
%     end
    nd = nndist(centers);
    md = min(nd);
    sigma_f = sqrt((log10((BeadNumber)))^2*(0.00131769));
    f = (-0.5126*log10(BeadNumber)+2.747);
    logavgdist = log10(md);
end