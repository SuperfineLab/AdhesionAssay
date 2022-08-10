clear Tally file frameIn frameOut foo im Vout height
fclose('all');

filelist = dir('*.mp4');
Tally = table('Size', [numel(filelist), 4], ...
              'VariableTypes', {'double', 'double', 'double', 'double'}, ...
              'VariableNames', {'WellNumber', 'FrameWidth', 'FrameHeight', 'FrameCount'});

% generate list of handles to mp4 videos
for file = 1:height(Tally)
    VidHandles{file} = VideoReader(filelist(file).name);
end

% Extract the well number from the data filename and populate the video tally table          
for file = 1:length(filelist)
    
    filename = filelist(file).name;
%     tok = regexpi(filename, 'fov-(\d*)', 'tokens');
%     wellNum = str2num(tok{1}{1});
            
%     Tally.WellNumber(file) = wellNum;
    Tally.WellNumber(file) = file;
    Tally.FrameWidth(file) = VidHandles{file}.Width;
    Tally.FrameHeight(file) = VidHandles{file}.Height;
    Tally.FrameCount(file) = VidHandles{file}.NumFrames;
end

frameIn = 1; 
while hasFrame(VidHandles{1}) 
    for file = 1:length(filelist)
        try
            foo = VidHandles{file}.readFrame; 
        catch
            foo = zeros(Tally.FrameHeight(file), Tally.FrameWidth(file));
        end
        wellNum = Tally.WellNumber(file);        
        im(:,:,file,frameIn) = foo(:,:,1); 
    end
    fprintf('FrameNumberIn= %u\n', frameIn);
    frameIn = frameIn + 1;
end


Vout = VideoWriter('2022.07.28__1xHBE_3xThinkyProtocol-NoInt-PEG&PWM&SNA&DNA&HBEbeads-mosaicvideo', 'MPEG-4');
% Vout = VideoWriter('2021.09.10__HBEslideNonInterfering_Trial3_mosaicvideo.mp4', 'MPEG-4');
Vout.FrameRate = 60;
open(Vout);
for frameOut = 1:size(im,4)
    fprintf('FrameNumberOut= %u\n', frameOut);
    q = squeeze(im(:,:,:,frameOut));
    T = imtile(q, 'GridSize', [3 5]);        
    T = im2uint8(T);
    writeVideo(Vout, T);
end
close(Vout);