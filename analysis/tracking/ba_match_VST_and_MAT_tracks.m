function BeadInfoTable = ba_match_VST_and_MAT_tracks(BeadInfoTable, VSTfirstframe)

    if nargin < 2 || isempty(VSTfirstframe) || isempty(BeadInfoTable)
        error('Need both VST and MAT tracking data as inputs.');
    end

    % threshold pixel distance between VST and MAT xy positions
    pixeldist_threshold = 6;

    [g, gT] = findgroups(VSTfirstframe.ID);


    VSTid_list = VSTfirstframe.ID;

    BeadInfoTable.SpotID = NaN(height(BeadInfoTable),1);
    BeadInfoTable.VSTxyz = NaN(height(BeadInfoTable),3);
    BeadInfoTable.MatchDist = NaN(height(BeadInfoTable),1);

    for k = 1:length(VSTid_list)

        idx = find(VSTfirstframe.ID == VSTid_list(k));

        testXY = [VSTfirstframe.X(idx), VSTfirstframe.Y(idx)];

        dist = dist_matrix([testXY; BeadInfoTable.BeadPosition]);
        dist = dist(2:end,1);         

        [neardist, matidx] = min(dist, [], 'omitnan');
        
        % If the nearest object is too far away, then it's not a real match (NaN output)
        if neardist < pixeldist_threshold
            BeadInfoTable.SpotID(matidx) = VSTid_list(k);
            BeadInfoTable.VSTxyz(matidx,:) = [VSTfirstframe.X(k) VSTfirstframe.Y(k) VSTfirstframe.Z(k)]; 
            BeadInfoTable.VSTarea(matidx,:) = VSTfirstframe.RegionSize(k);
        end
        BeadInfoTable.MatchDist(matidx,:) = neardist;
        
    end    

    BeadInfoTable = movevars(BeadInfoTable, "VSTxyz", "After", "BeadPosition");
    BeadInfoTable = movevars(BeadInfoTable, "SpotID", "Before", "BeadPosition");

%     figure; 
%     plot(VSTfirstframe.X, VSTfirstframe.Y, 'kx', ...
%          BeadInfoTable.BeadPosition(:,1),BeadInfoTable.BeadPosition(:,2), 'g.', ...
%          BeadInfoTable.VSTxy(:,1), BeadInfoTable.VSTxy(:,2), 'ro');
%     title('Bead Finding Debug Plot');
%     xlabel('X position [px');
%     ylabel('Y position [px]');
%     legend('Orig VST loc', 'MATtrack loc', 'Found VST loc');
%     xlim([0 1024]);
%     ylim([0 768]);
%     set(gca, 'YDir', 'reverse');
%     drawnow;

end


% function outs = findmatch(VSTid, VSTxy, MatBeadPosition, g)
% 
%     testXY = [VSTfirstframe.X(idx), VSTfirstframe.Y(idx)];    
%     dist = dist_matrix([testXY; BeadInfoTable.BeadPosition]);    
%     outs = 0;
% 
% end
