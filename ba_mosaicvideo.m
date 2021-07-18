clear f w b foo im Vout
fclose('all');

filelist = dir('*.mp4');

for f = 1:length(filelist)
    w(f) = VideoReader(filelist(f).name); 
end

b = 1; 
while hasFrame(w(1)) 
    for k = 1:length(filelist)
        foo = w(k).readFrame; 
        im(:,:,k,b) = foo(:,:,1); 
    end
    b=b+1
end

Vout = VideoWriter('GlcNAc_closedplate_pincermagnet.mp4', 'MPEG-4');
Vout.FrameRate = 60;
open(Vout);
for m = 1:size(im,4)
    m
    q = squeeze(im(:,:,:,m));
    T = imtile(q, 'GridSize', [3 5]);        
    T = im2uint8(T);
    writeVideo(Vout, T);
end
close(Vout);