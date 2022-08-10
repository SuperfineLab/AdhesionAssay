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
    opts.tag.datetime = false;
    opts.tag.frame = false;
    opts.tag.height = false;
    opts.tag.name = false; 
    opts.tag.fov = false;
    opts.tag.angle = false;
    opts.tag.nana = false;
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
    
    if isfield(metadata.Results, 'TimeStatsTable')
        time = table2array(metadata.Results.TimeStatsTable);
    elseif isfield(metadata.Results, 'TimeHeightVidStatsTable')
        time = table2array(metadata.Results.TimeHeightVidStatsTable);
    else
        error('Do not recognize the Time Table.');
    end
    
else
    AllHeights = [];
    Time = [];
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
    
    count = 1;
    tag = opts.tag;
    tagtxt = '';
    if tag.datetime
        tagtxt{count,1} = datestr(time(k));
        count = count + 1;
    end
    
    if tag.frame
        tagtxt{count,1} = ['f=' num2str(k,'%04i')];
        count = count + 1;
    end
    
    if tag.height
        tagtxt{count,1} = ['h=' num2str(height)];
        count = count + 1;
    end
    
    if tag.name 
        tagtxt{count,1} = stack_folder;
        count = count + 1;
    end
    
    if tag.fov
        tmp = regexpi(stack_folder, 'fov-(\d*)', 'tokens');
        if ~isempty(tmp)
            fov = tmp{1}{1};
            tagtxt{count,1} = ['fov=' fov];
            count = count + 1;
        end
    end
        
    if tag.angle
        tmp = regexpi(stack_folder, 'angle-(\d*)', 'tokens');
        if ~isempty(tmp)
            angle = tmp{1}{1};
            tagtxt{count,1} = ['angle=' angle];
            count = count + 1;
        end
    end
    
    if tag.nana
        tmp = regexpi(stack_folder, 'NANA-(\d*)', 'tokens');
        if ~isempty(tmp)
            nana = tmp{1}{1};
            tagtxt{count,1} = ['NANA=' nana 'mg/mL'];
            count = count + 1;
        end        
    end
    
    tagtxt = join(tagtxt, ', ');
    
    imrgb = insertText(im, [5 5], tagtxt, ...
                                  'AnchorPoint', 'LeftTop', ...
                                  'BoxColor', 'black', ...
                                  'BoxOpacity', 0.4, ...
                                  'TextColor', 'white', ...
                                  'FontSize', 14);
   
    im = im2uint8(imrgb);
    writeVideo(v, im); 
end
close(v);

