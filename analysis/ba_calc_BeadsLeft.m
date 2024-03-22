function [newFileTable,newForceTable] = ba_calc_BeadsLeft(Data, aggregating_variables)
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

    [g, grpT] = findgroups(newFileTable(:,aggregating_variables));
    NStartingBeads(:,1) = splitapply(@sum, newFileTable.FirstFrameBeadCount, g);
    NStartingBeadsT = [grpT, table(NStartingBeads)];
    
    T = join(ForceTable, newFileTable(:,{'Fid', aggregating_variables{:}})); %#ok<CCAT> 
    T = join(T, NStartingBeadsT);
    % T = sortrows(T, {'Filename', 'Force'}, {'ascend', 'ascend'});
    [g, grpT] = findgroups(T(:,aggregating_variables));
    
    foo = splitapply(@(x1,x2,x3,x4){sa_fracleft(x1,x2,x3,x4)}, T.Fid, T.SpotID, T.Force, T.NStartingBeads, g);
    fooM = cell2mat(foo);
    
    Tmp.Fid = fooM(:,1);
    Tmp.SpotID = fooM(:,2);
    Tmp.Force = fooM(:,3);
    Tmp.FractionLeft = fooM(:,4);
    
    Tmp = struct2table(Tmp);
    newForceTable = join(ForceTable, Tmp);

    newForceTable.Properties.VariableUnits{'FractionLeft'} = '[]';
    newForceTable.Properties.VariableDescriptions{'FractionLeft'} = 'Fraction of beads remaining on substrate';
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