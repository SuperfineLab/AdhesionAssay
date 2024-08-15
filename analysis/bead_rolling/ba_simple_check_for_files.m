function [QueryFileTable, MissingFileTable] = ba_simple_check_for_files(B, missingfilesonlyTF,repairmetafileTF)

    % Primary questions to answer here are
    % 1. At what time does the bead translate a distance equal to 
    %    its own diameter? This displacement must be measured from the
    %    original z-position int he entire trajectory (vststartxyzpos)
    %    and NOT the first z-value collected for the velocity 
    %    measurement (xyzpath).
    % 2. What are the radial (x+y) displacements at that time point?
    %

    if isTableCol(B.TrackingTable, 'ID')
        B.TrackingTable = renamevars(B.TrackingTable, 'ID', 'SpotID');
    end

    % FileTable = B.FileTable;

    AbsFilename = B.FileTable.FullFilename;

    AbsFilename = cellfun(@(x1)strrep(x1,'.bin','.csv'), AbsFilename, 'UniformOutput',false);

    OrigFileExists = isfile(AbsFilename);

    [FilePath,OrigFilename] = fileparts(AbsFilename);

    Q = table(AbsFilename, FilePath, OrigFilename, OrigFileExists);

    QueryFileTable = Q;

    if missingfilesonlyTF 

        MissingFileTable = QueryFileTable(~QueryFileTable.OrigFileExists,:);

        if ~isempty(MissingFileTable)
            [g,gT] = findgroups(MissingFileTable(:,{'AbsFilename'}));
            fooT = splitapply(@(x)sa_predictnewname(x),MissingFileTable.AbsFilename, g);
    
            fooT = horzcat(gT,fooT);
            MissingFileTable = innerjoin(MissingFileTable, fooT, 'Keys', 'AbsFilename');
        else
            MissingFileTable = [];
        end

    else
        MissingFileTable = [];
    end


    if repairmetafileTF && ~isempty(MissingFileTable)
        idx = MissingFileTable.LikelyFnameExists;
        ToRepairFileTable = MissingFileTable(idx,:);

        [g,gT] = findgroups(ToRepairFileTable.AbsFilename);
        foo = splitapply(@(x1,x2)sa_repairfilename(x1,x2), ToRepairFileTable.AbsFilename, ...
                                                   ToRepairFileTable.LikelyFname, ...                   
                                                   g);
    end

end

function outsT = sa_predictnewname(absfilenames)

    outsT = table;
    
    [filepath,filename] = fileparts(absfilenames);

    matchCell = regexpi(filename, '(well\d*)_', 'tokens');

    likelyfname = [matchCell{1}{1}{1}, '*.csv'];
    
    full_likely_name = fullfile(string(filepath), likelyfname);

    dir_likely_name = dir(full_likely_name);
    likelyfnameexists = ~isempty(dir_likely_name);

    if likelyfnameexists
        actualname = string(dir_likely_name.name);
    else
        actualname = string(likelyfname);
    end

    outsT.LikelyFname = actualname;
    outsT.LikelyFnameExists = likelyfnameexists;   
end


function outs = sa_repairfilename(absname, repairfilename)

    if iscell(absname)
        absname = absname{:};
    end

    startdir = pwd;

    % breakdown the filenames in the FileTable
    [inPath, inFname] = fileparts(absname);
    [~, repairFname, repairExt] = fileparts(repairfilename);

    repairFname = char(repairFname); % because fileparts outputs strings now

    cd(inPath);
    
    % Pull out the metadata filename 
    metafname = [repairFname,'.meta.mat'];
    backupfname = [repairFname,'.meta.oldbad.mat'];
    % metafname = strcat( full_repairfname );

    metafile = dir(fullfile(inPath,metafname));

    tmp = load(metafile.name);
    if ~isempty(tmp)
        if ~strcmp(tmp.File.SampleName, repairFname)
            tmp.File.SampleName = repairFname;
            tmp.File.Binfile = strcat(repairFname, '.bin');
    
            copyfile(metafname, backupfname);

            logentry(['Saving repaired metafile: ', metafname]);
            save(metafname, '-STRUCT', 'tmp');
        else
            logentry('Metadata file is already corrected.');
        end
    else
        logentry('Original metadata file not found.')
    end
    
    cd(startdir);

    outs = 0;
end