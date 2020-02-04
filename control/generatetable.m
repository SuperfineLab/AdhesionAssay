function [GeneratedTable] = generatetable(filelist)

for k = 1:numel(filelist)
    Frames{k,1} = k;
    Image{k,1} = imread(filelist(k).name);
    Images{k,1} = Image{k,1}(:,:,1); 
end

[centers, radii] = cellfun(@(x1)imfindcircles(x1,[5 30]),Images,'UniformOutput',false);
nndist = cellfun(@neardist,centers,'UniformOutput',false);
meannndist = cellfun(@mean,nndist,'UniformOutput',false);
minnndist = cellfun(@min,nndist,'UniformOutput',false);
mednndist = cellfun(@median,nndist,'UniformOutput',false);
GeneratedTable = table(Frames,Images,centers,radii,nndist,meannndist,minnndist,mednndist)