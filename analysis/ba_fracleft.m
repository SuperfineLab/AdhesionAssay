function outs = ba_fracleft(fileid, spotid, force, startCount)

    if nargin < 4 || isempty(startCount)
        startCount = length(force);   
    end

    force = force(:);
    
    % I do not really understand how this determines "rank" of force, but
    % it does and outputs the fraction left attached
    [~,Fidx] = sort(force, 'ascend');
    [~,Frank] = sort(Fidx, 'ascend');    
    
    fracleft = 1 - (Frank ./ startCount);
   
    outs = [fileid(:), spotid(:), fracleft(:)];
end