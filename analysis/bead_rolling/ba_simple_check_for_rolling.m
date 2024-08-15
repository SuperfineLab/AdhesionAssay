function outs = ba_simple_check_for_rolling(B)

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
    
    joinT = innerjoin(B.BeadInfoTable(:,{'Fid', 'SpotID', 'BeadPosition', 'VSTxyz', 'MatchDist', 'BeadRadius'}), ...
                      B.BeadForceTable(:,{'Fid', 'SpotID', 'Pulloff_time', 'Mean_vel'}), ...
                      'Keys', {'Fid', 'SpotID'});

    joinT = innerjoin(joinT, ...
                      B.FileTable(:,{'Fid', 'FullFilename', 'MeanFps', 'Calibum'}), ...
                      'Keys',{'Fid'});

    joinTfull = innerjoin(joinT, ...
                      B.TrackingTable(:,{'Fid', 'SpotID', 'Frame', 'X', 'Y', 'Z'}), ...
                      'Keys', {'Fid', 'SpotID'});



    [g, gT] = findgroups(joinTfull(:, {'Fid', 'SpotID'}));


    joinTfull.zFrameVelocity = joinTfull.Mean_vel ./ joinTfull.MeanFps .* joinTfull.Calibum * 1e6;
    tmp = splitapply(@(x1,x2,x3,x4,x5)sa_findtruedetachframe(x1,x2,x3,x4,x5), ...
                                                             joinTfull.Fid, ...
                                                             joinTfull.SpotID, ...
                                                             joinTfull.Frame, ...
                                                             joinTfull.VSTxyz(:,3), ...                                                             
                                                             joinTfull.Z, ...
                                                             g);
    joinT = innerjoin(joinT, tmp, 'Keys', {'Fid', 'SpotID'});

    [g, ~] = findgroups(joinT(:, {'Fid'}));
    tmp = splitapply(@(x1,x2,x3,x4){sa_calc_xyrolling(x1,x2,x3,x4)}, joinT.Fid, ...
                                                            joinT.SpotID, ...
                                                            joinT.TrueDetachFrame, ...
                                                            joinT.FullFilename, ...
                                                            g);
    outs = vertcat(tmp{:});
    
    outs.MaxRxy = cell2mat(outs.MaxRxy);
    
    outs.Properties.VariableUnits{'TrueDetachFrame'} = '[frame number]';
    outs.Properties.VariableUnits{'MaxRxy'} = '[pixels]';


    % pull out correct xy rolling quantity

end





function Tout = sa_findtruedetachframe(fid, spotid, frame, startzpos, zdisp)


    p = polyfit(frame, zdisp, 1);
    [zvel, z0] = deal(p(1),p(2));
    % tdf means "true detachment frame"
    tdf = floor(startzpos(1) - z0 / zvel);

    Tout = table;
    Tout.Fid = fid(1);
    Tout.SpotID = spotid(1);
    Tout.TrueDetachFrame = tdf;
end


function Tout = sa_calc_xyrolling(fid, spotid, truedetachframe, fullfilename)
     

     fullfilename = fullfilename(1);
     % framerate = framerate(1);
     % calibum = calibum(1);

     miniBeadTable = table(fid, spotid, truedetachframe, 'VariableNames', {'Fid', 'ID', 'TrueDetachFrame'});
 
     origTrackingFile = strrep(fullfilename, '.bin', '.csv');
     origTracks = load_video_tracking(origTrackingFile, ...
                                      1, 'pixels', 1, 'absolute','no', ...
                                      'table');

     origTracks = innerjoin(origTracks, miniBeadTable, "Keys", {'ID'});

     [g, gT] = findgroups(origTracks(:,{'Fid','ID'}));
     gT.MaxRxy = splitapply(@(x1,x2,x3){sa_calcMaxRxy(x1,x2,x3)}, origTracks.Frame, ...
                                                            [origTracks.X, origTracks.Y, origTracks.Z], ...
                                                             origTracks.TrueDetachFrame, ...
                                                             g);

     % Tout.Fid = fid(1);
     % Tout.SpotID = spotid(1);
     % Tout.MaxRxy = maxRxy;
    Tout = innerjoin(miniBeadTable, gT, 'Keys', {'Fid', 'ID'});
    Tout = renamevars(Tout, 'ID', 'SpotID');
end



function maxrout = sa_calcMaxRxy(frame, xyz, truedetachframe)

    % myframes = frame(frame <= truedetachframe(1));
    neut_xyz = xyz - xyz(1,:);
    myxy = neut_xyz(frame < truedetachframe, 1:2);

    rout = sqrt(sum(myxy.^2, 2));

    if isempty(rout)
        maxrout = NaN;
        logentry('No detachment radius found. Not sure why.');
    else
        maxrout = max(rout);
    end
    
end