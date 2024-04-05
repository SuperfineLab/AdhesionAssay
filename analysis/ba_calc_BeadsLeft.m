function newFileTable = ba_calc_BeadsLeft(Data)
% XXX @stephensnare Add documentation for this function.

% Number of stuck beads is equal to the starting number of beads minus
% the number of Force approximations we made during our tracking
% clean-up for the velocity calculation.

    newFileTable = Data.FileTable;
    ForceTable = Data.ForceTable;

    LastFrameBeadCount = NaN(height(newFileTable),1);

    for k = 1:height(newFileTable)
        Fid = newFileTable.Fid(k);
        FirstFrameBeadCount = newFileTable.FirstFrameBeadCount(k);
    
        myForceTable = ForceTable( ForceTable.Fid == Fid, :);
        LastFrameBeadCount(k,1) = FirstFrameBeadCount - height(myForceTable);       
    end

    newFileTable.LastFrameBeadCount = LastFrameBeadCount;

end


function outs = sa_fracleft(fid, spotid, force, startCount)

    force = force(:);
    Nforce = length(force);   
    
    % I do not really understand how this determines "rank" of force, but
    % it does and outputs the fraction left attached
    [~,Fidx] = sort(force, 'ascend');
    [~,Frank] = sort(Fidx, 'ascend');    
    
    fracleft = 1-(Frank ./ startCount);

    outs = [fid(:), spotid(:), force(:), fracleft(:)];
end