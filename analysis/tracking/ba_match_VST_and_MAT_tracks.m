function BeadInfoTable = ba_match_VST_and_MAT_tracks(BeadInfoTable, VSTfirstframe)

    if nargin < 2 || isempty(VSTfirstframe) || isempty(BeadInfoTable)
        error('Need both VST and MAT tracking data as inputs.');
    end

    [g, gT] = findgroups(VSTfirstframe.ID);


    VSTid_list = VSTfirstframe.ID;

    BeadInfoTable.SpotID = NaN(height(BeadInfoTable),1);
    BeadInfoTable.VSTxy = NaN(height(BeadInfoTable),2);
    BeadInfoTable.MatchDist = NaN(height(BeadInfoTable),1);

    for k = 1:length(VSTid_list)

        idx = find(VSTfirstframe.ID == VSTid_list(k));

        testXY = [VSTfirstframe.X(idx), VSTfirstframe.Y(idx)];

        dist = dist_matrix([testXY; BeadInfoTable.BeadPosition]);

        dist = dist(2:end,1);         
        [neardist,matidx] = min(dist, [], 'omitnan');
        
        % If the nearest object is too far away, then it's not a real match (NaN output)
        if neardist < 4 % threshold pixel distance between VST and MAT xy positions
            BeadInfoTable.SpotID(matidx) = VSTid_list(k);
            BeadInfoTable.VSTxy(matidx,:) = [VSTfirstframe.X(k) VSTfirstframe.Y(k)]; 
            BeadInfoTable.VSTarea(matidx,:) = VSTfirstframe.RegionSize(k);
        end
        BeadInfoTable.MatchDist(matidx,:) = neardist;
        
        BeadInfoTable = movevars(BeadInfoTable, "VSTxy", "After", "BeadPosition");
        BeadInfoTable = movevars(BeadInfoTable, "SpotID", "Before", "BeadPosition");

    end    

end


function outs = findmatch(VSTid, VSTxy, MatBeadPosition, g)

            testXY = [VSTfirstframe.X(idx), VSTfirstframe.Y(idx)];

        dist = dist_matrix([testXY; BeadInfoTable.BeadPosition]);


outs = 0;

end