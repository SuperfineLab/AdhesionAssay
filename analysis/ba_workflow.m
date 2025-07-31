function ba_workflow(filemask)
% BA_WORKFLOW analyzes a suite of bead-adhesion videos in the experiment path.
%
% This function begins the analytical workflow on an adhesion
% "experiment,", defined here as a directory containing videos collected 
% for one 15-well slide. Given an experiment directory of bin files, this
% workflow includes converting the bin files to image stacks, creating a 
% small compressed video for quick reference, extracting first and last 
% keyframes, tracking beads for each video, and zipping the final image
% stack into a smaller form for archival purposes.
%
%   ba_workflow(filemask)
%
% Inputs:
%    filemask- directory of bin files
% 
% Outputs:
%    (none)
%

if nargin < 1 || isempty(filemask)
    error('No files to work on.');
end

filelist = dir(filemask); 

if isempty(filelist)
    error('This directory does not contain files in filemask.');
end

exptdir = filelist(1).folder;

startdir = pwd;
cd(exptdir);

    
binfilelist = dir('**/*.bin');
    
if ~isempty(binfilelist)
    B = length(binfilelist);
    parfor b = 1 : B
        binfile = binfilelist(b).name;
        
        logentry('Converting bin file to stack of pgms...')
        ba_bin2stack(binfile, [], true);
        
        logentry('Deleting original bin file...');
        delete(binfile);
    end
else
%     error('No data found.');
end

stackdirlist = dir('**/frame00001.pgm');

S = length(stackdirlist);

% For every file-stack in my experiment directory
for s = 1:S
    
    stackdir = stackdirlist(s).folder;
    
% %     cd(binpath);
    


%     logentry('Loading frame extraction times and motor z-positions');
%     tz = load([stackdir '.meta.mat']);
    
    logentry('Retrieving first & last frames (used for first locating beads).');
    ba_extract_keyframes(stackdir);
    
      
    opts.scale = 0.25;
    opts.stride = 4;
    opts.pmip = false;
    opts.tag.datetime = true;
    opts.tag.frame = true;
    opts.tag.height = false;
    opts.tag.name = false; 
    opts.tag.fov = true;
    opts.tag.angle = true;
    opts.tag.nana = true;
    
    logentry('Creating mini-video of stack using MP4 format'); 
    ba_minivideo(stackdir,[],[],opts);
    
    logentry('Tracking beads in this stack...');
    ba_trackstack(stackdir);

    logentry('Compressing stack into smaller zip file.');
    ba_zipstack(stackdir);
    
%     logentry('Deleting stack...');
%     rmdir(stackdir, 's');
    

    
    % Return to our original experiment directory
    cd(exptdir);
        
end
% rm('*_tmp.*');

cd(startdir);

return

    
% function for writing out stderr log messages
function logentry(txt)
    logtime = clock;
    logtimetext = [ '(' num2str(logtime(1),  '%04i') '.' ...
                   num2str(logtime(2),        '%02i') '.' ...
                   num2str(logtime(3),        '%02i') ', ' ...
                   num2str(logtime(4),        '%02i') ':' ...
                   num2str(logtime(5),        '%02i') ':' ...
                   num2str(floor(logtime(6)), '%02i') ') '];
     headertext = [logtimetext 'ba_workflow: '];
     
     fprintf('%s%s\n', headertext, txt);
     
     return;  
