[vid, src] = ba_video_setup;

NFrames = 1270; % Originally 1800

imaqmex('feature', '-previewFullBitDepth', true);
vid.ReturnedColorspace = 'grayscale';
triggerconfig(vid, 'manual');
vid.FramesPerTrigger = NFrames;

vidRes = vid.VideoResolution;
frame = getsnapshot(vid);
imagetype = class(frame);

imageRes = fliplr(vidRes);

f = figure;%('Visible', 'off');
if strcmp(class(frame),'uint8')
    pImage = imshow(uint8(zeros(imageRes)));
elseif strcmp(class(frame),'uint16')
    pImage = imshow(uint16(zeros(imageRes)));
else
    disp(':(')
end

axis image
setappdata(pImage, 'UpdatePreviewWindowFcn', @ba_pulloffview)
p = preview(vid, pImage);
set(p, 'CDataMapping', 'scaled');