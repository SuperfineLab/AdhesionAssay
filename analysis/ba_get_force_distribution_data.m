function grpF = ba_get_force_distribution_data(ba_process_data, maxforce, aggregating_variables)

    if nargin < 1 || isempty(ba_process_data)
        error('No data on input.');
    end
    
    if nargin < 2 || isempty(maxforce)
        maxforce = NaN;
    end    
    
    if nargin < 3 || isempty(aggregating_variables)
        aggregating_variables = {'Fid'};
    end
    
    
    Data = ba_process_data;
    aggVars = aggregating_variables(:);

    if ~iscell(aggVars)
        error('Need cell array of aggregating variables');
    end
        
    [g, BeadCountTable] = findgroups(Data.FileTable(:,aggVars));
    BeadCountTable.Nvideos = splitapply(@numel, Data.FileTable.Fid, g);
    BeadCountTable.TotalBeadCount = splitapply(@sum, Data.FileTable.FirstFrameBeadCount, g);

    FileVars(1,:) = [{'Fid'}; aggVars];
    FTable = join(Data.ForceTable, Data.FileTable(:,FileVars));
    FTable = innerjoin(FTable, BeadCountTable, 'Keys', aggVars);
    FTable(FTable.Force <= 0,:) = [];

    
    [gF, grpF] = findgroups(FTable(:,aggVars));

    grpF.Force = splitapply(@(x1,x2){sa_attach_stuck_beads(x1,x2,maxforce)}, FTable.Force, ...
                                                                             FTable.TotalBeadCount, ...
                                                                             gF);

end

function myforce = sa_attach_stuck_beads(force, beadcount, maxforce)
    padforce = beadcount(1) - length(force);
    myforce = [force(:) ; repmat(maxforce,padforce,1)];
end

