function [Folder,Name,Frames,Images] = generatedata(filelist)


for k = 1:numel(filelist)
    Folder{k,1} = filelist(k).folder;
    Name{k,1} = filelist(k).name;
    vid{k,1} = imread(fullfile(filelist(k).folder,filelist(k).name)); 
    Frames{k,1} = k;
%     Frames{k,1} = readFrame(vid); 
    Images{k,1} = vid{k,1}(:,:,1);
%     Frames{k,1} = k;
end
