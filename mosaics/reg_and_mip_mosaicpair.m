cd 'V:\VertClear\2022.12.07__HBEracetrack3_mucus+NANA\step01-PBSwash'
filelist = dir('*.zip');
filelist = {filelist(:).name}'
filelist = cellfun(@(str)strrep(str,'.zip','.mp4'),filelist, 'UniformOutput', false)

rootdir = 'V:\VertClear\2022.12.07__HBEracetrack3_mucus+NANA\step01-PBSwash';


cd(rootdir)
regdir = [rootdir, filesep, 'reg-mp4s'];
mipdir = [rootdir, filesep, 'mip-mp4s'];

scale = 0.5;
for k = 1:length(filelist)
    regvid = VideoReader([regdir, filesep, filelist{k}]);
    mipvid = VideoReader([mipdir, filesep, filelist{k}]);
       
    outname = [rootdir, filesep, strrep(filelist{k}, '.mp4', '_mosaic.mp4')];
    outvid = VideoWriter(outname, 'MPEG-4');
    outvid.Quality = 95;
    open(outvid)
    
    clear IM
    FrameCount = 1;
    while(hasFrame(regvid))
        regframe = readFrame(regvid);
        mipframe = readFrame(mipvid);
        
        regframe = imresize(regframe(:,:,1), scale, 'bicubic');
        mipframe = imresize(mipframe(:,:,1), scale, 'bicubic');
        
        IM = imtile([rescale(regframe, 0, 255), rescale(mipframe,0,255)]);
        IM = uint8(IM);
        
        figure(32); 
        imagesc(IM); 
        colormap(gray); 
        drawnow;
        
        if ~mod(FrameCount,100)
            disp(['Frame: ', num2str(FrameCount)]);
        end
        
        FrameCount = FrameCount + 1;
        writeVideo(outvid,IM);
    end
    close(outvid);
end
