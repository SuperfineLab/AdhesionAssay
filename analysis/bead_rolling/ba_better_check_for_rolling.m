function outs = ba_better_check_for_rolling(B)

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
    
    T = innerjoin(B.BeadInfoTable(:,{'Fid', 'SpotID', 'BeadPosition', 'VSTxyz', 'MatchDist', 'BeadRadius'}), ...
                      B.BeadForceTable(:,{'Fid', 'SpotID', 'Pulloff_time', 'Mean_vel'}), ...
                      'Keys', {'Fid', 'SpotID'});

    T = innerjoin(T, B.FileTable(:,{'Fid', 'FullFilename', 'MeanFps', 'Calibum'}), ...
                     'Keys',{'Fid'});

    joinTfull = innerjoin(T, B.TrackingTable(:,{'Fid', 'SpotID', 'Frame', 'X', 'Y', 'Z'}), ...
                          'Keys', {'Fid', 'SpotID'});

    [g, tmpDetachTable] = findgroups(joinTfull(:, {'Fid', 'SpotID'}));


    joinTfull.zFrameVelocity = joinTfull.Mean_vel ./ joinTfull.MeanFps .* joinTfull.Calibum * 1e6;
    tmp = splitapply(@(x1,x2,x3)sa_findtruedetachframe(x1,x2,x3), ...
                                                             joinTfull.Frame, ...
                                                             joinTfull.VSTxyz(:,3), ...                                                             
                                                             joinTfull.Z, ...
                                                             g);
    tmpDetachTable = horzcat(tmpDetachTable, tmp);
    clear tmp;

    T = innerjoin(T, tmpDetachTable, 'Keys', {'Fid', 'SpotID'});

    [g, ~] = findgroups(T(:, {'Fid'}));
    tmpxyT = splitapply(@(x1,x2,x3,x4){sa_extract_xy(x1,x2,x3,x4)}, T.Fid, ...
                                                            T.SpotID, ...
                                                            T.TrueDetachFrame, ...
                                                            T.FullFilename, ...
                                                            g);
    tmpxyT = vertcat(tmpxyT{:});
    tmpxyT = renamevars(tmpxyT, "ID", "SpotID");

    [g, xyT] = findgroups(tmpxyT(:, {'Fid','SpotID'}));
    xyT.MaxRxy = splitapply(@sa_calcMaxRxy, [tmpxyT.X, tmpxyT.Y], g);

    xyT = innerjoin(xyT, tmpDetachTable, "Keys", {'Fid', 'SpotID'});
    
    xyT.Properties.VariableUnits{'TrueDetachFrame'} = '[frame number]';
    xyT.Properties.VariableUnits{'MaxRxy'} = '[pixels]';


    % pull out correct xy rolling quantity

end


function Tout = sa_findtruedetachframe(frame, startzpos, zdisp)

    p = polyfit(frame, zdisp, 1);
    [zvel, z0] = deal(p(1),p(2));
    % tdf means "true detachment frame"
    tdf = floor(startzpos(1) - z0 / zvel);

    Tout = table;
    Tout.TrueDetachFrame = tdf;
end


function filtTracks = sa_extract_xy(fid, spotid, truedetachframe, fullfilename)

     fullfilename = fullfilename(1);
     % framerate = framerate(1);
     % calibum = calibum(1);

     miniBeadTable = table(fid, spotid, truedetachframe, 'VariableNames', {'Fid', 'ID', 'TrueDetachFrame'});
 
     origTrackingFile = strrep(fullfilename, '.bin', '.csv');
     origTracks = load_video_tracking(origTrackingFile, ...
                                      1, 'pixels', 1, 'absolute','no', ...
                                      'table');

     filtTracks = innerjoin(origTracks(:,{'Frame', 'ID', 'X', 'Y', 'Z'}), ...
                            miniBeadTable, "Keys", {'ID'});

     filtTracks = filtTracks(filtTracks.Frame <= filtTracks.TrueDetachFrame, :);
     filtTracks = movevars(filtTracks, "Fid", "Before", 1);
     filtTracks.TrueDetachFrame = [];
end

% function Tout = sa_calc_xyrolling(xy, spotid, truedetachframe, fullfilename)     
%      [g, gT] = findgroups(origTracks(:,{'Fid','ID'}));
%      gT.MaxRxy = splitapply(@(x1,x2,x3){sa_calcMaxRxy(x1,x2,x3)}, origTracks.Frame, ...
%                                                             [origTracks.X, origTracks.Y, origTracks.Z], ...
%                                                              origTracks.TrueDetachFrame, ...
%                                                              g);
% 
%      % Tout.Fid = fid(1);
%      % Tout.SpotID = spotid(1);
%      % Tout.MaxRxy = maxRxy;
%     Tout = innerjoin(miniBeadTable, gT, 'Keys', {'Fid', 'ID'});
%     Tout = renamevars(Tout, 'ID', 'SpotID');
% end



function maxrout = sa_calcMaxRxy(xy)
    
    myxy = xy - xy(1,:);

    rout = sqrt(sum(myxy.^2, 2));

    if isempty(rout)
        maxrout = NaN;
        logentry('No detachment radius found. Not sure why.');
    else
        maxrout = max(rout);
    end
    
end


% function myxy = sa_extractxy(frame, xyz, truedetachframe)
% 
%     % myframes = frame(frame <= truedetachframe(1));
%     xyz = xyz - xyz(1,:);
%     myxy = neut_xyz(frame < truedetachframe, 1:2);
% 
%     if isempty(myxy)
%         myxy = NaN;
%         logentry('Trajectory is empty. Not sure why.');
%     end
% 
% end