function [Folder,Name,Frames,Images] = generatedata()

filelist = dir('**/*.mp4')

for k = 1:numel(filelist)
    Folder{k,1} = filelist(k).folder;
    Name{k,1} = filelist(k).name;
    vid = VideoReader(fullfile(filelist(k).folder,filelist(k).name)); 
    Frames{k,1} = readFrame(vid); 
    Images{k,1} = Frames{k,1}(:,:,1);
    Frames{k,1} = k;
end
