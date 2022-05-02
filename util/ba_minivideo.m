function ba_minivideo(stack_folder, destination_folder, outfile, opts)
% BA_MINIVIDEO creates a compressed and annotated mp4 for an image stack
%

if nargin < 1 || isempty(stack_folder)
    error('No Stack folder defined.');
end

sftmp = dir(stack_folder);

if ~isempty(sftmp)
    stack_folder = sftmp(1).folder;
    slashpos = regexp(stack_folder, filesep);
else
    error('Stack not found. Incorrect filename?');
end

if nargin < 2 || isempty(destination_folder)
    destination_folder = stack_folder(1:slashpos(end)-1);
end

if nargin < 3 || isempty(outfile)
    outfile = [destination_folder, stack_folder(slashpos(end):end), '.mp4'];
end

if nargin < 4 || isempty(opts)
    opts.stride = 4;
    opts.scale = 0.5;
    opts.pmip = true;    
end

rootdir = pwd;

filelist = dir([stack_folder filesep 'frame*.pgm']);

if isempty(filelist)
    error('No images found. Bad directory name?');
end

vidstatsfile = dir([stack_folder '.vidstats.mat']);
metadatafile = dir([stack_folder '.meta.mat']);

if ~isempty(vidstatsfile)
    VidStats = load(vidstatsfile.name);
    VidStats = VidStats.VidStats;
    maxintens = VidStats.Max(1);
    disp(['Max intens is: ' num2str(maxintens)]);
end

if ~isempty(metadatafile)
    metadata = load(metadatafile.name);        
    try
        AllHeights = metadata.Results.TimeHeightVidStatsTable.ZHeight;
    catch
        AllHeights = [];
    end
else
    AllHeights = [];
end



v = VideoWriter(outfile, 'MPEG-4');
v.FrameRate = 15;

open(v);
for k = 1:opts.stride:length(filelist)
    myfile = fullfile(filelist(k).folder, (filelist(k).name));
    
    im = imread(myfile);    
    
    if ~exist('accim', 'var')
        accim = uint16(zeros(size(im)));
    end
    
    if opts.pmip
        tmpim = cat(3, im, accim);
        im = max(tmpim,[],3);
        accim = im;
    end    
        
    if opts.scale ~= 1
        im = imresize(im, opts.scale);    
    end
    
    if ~isempty(vidstatsfile)
        im = double(im);
        im = im ./ maxintens;
    end
    
    
    % To label the current height in the top-left corner of the video...
    if ~isempty(AllHeights)
        height = AllHeights(k);
    else
        height = 0;
    end
    
    height = round(height, 1);

    imrgb = insertText(im, [5 5], ['f=' num2str(k), ...
                                   ', h=' num2str(height)], ...
                                   'AnchorPoint', 'LeftTop', ...
                                   'BoxColor', 'black', ...
                                   'BoxOpacity', 0.4, ...
                                   'TextColor', 'white', ...
                                   'FontSize', 14);
   
    im = im2uint8(imrgb);
    writeVideo(v, im); 
end
close(v);

