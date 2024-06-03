function [TableOut, optstartT] = ba_detachmentforces(ba_process_data, groupvars)
% XXX @jeremy TODO: Add documentation for this function
%
    
    Data = ba_process_data;


    % Extract detachment forces and their relative certainty

%     g = findgroups(RelevantData(:, unique(['PlateID', groupvars])));
%     [tmpa, tmpb] = splitapply(@(x1,x2)calcdetachforce_CFTBXmethod(x1,x2), fitfoo.FitParams, fitfoo.confFitParams, g);
    filterTF = false;
    [tmpa, tmpb] = cellfun(@(x1,x2)calcdetachforce_CFTBXmethod(x1,x2), fitT.FitParams, fitT.confFitParams, 'UniformOutput',false);
    TableOut.logDetachForce = tmpa;
    TableOut.relwidthDetachForce = tmpb;
    TableOut.DetachForce = cellfun(@(x1,x2)reduce2oneforce(x1,x2,filterTF), TableOut.logDetachForce, TableOut.relwidthDetachForce, 'UniformOutput',false);
    TableOut.DetachForce = 10.^cell2mat(TableOut.DetachForce);

    TableOut.Properties.VariableUnits{'DetachForce'} = '[nN]';

end



%
% Support Functions
%

function logforce = reduce2oneforce(logdetachforces, relwidthdetachforce, filterTF)

    % filter out forces less than 10^-3 nN (1 pN) and greater than 10^3 nN
    if filterTF
        idx = (logdetachforces >= -3 && logdetachforces <= 4);
        logentry(['Removing ' num2str(numel(logdetachforces) - sum(idx)) ' forces outside set, relevant bounds.']);
        logdetachforces = logdetachforces(idx);
        relwidthdetachforce = relwidthdetachforce(idx);
    end

    if sum(isnan(relwidthdetachforce)) == numel(relwidthdetachforce)
        logforce = NaN;
    else
        w = 1./relwidthdetachforce;
        weights = w ./ sum(w,[],'omitnan');
        logforce = sum(weights .* logdetachforces, [], 'omitnan');    
    end
end

function [outforce, outci] = calcdetachforce_BASICmethod(p)

    twist = @(x)transpose(reshape(x,3,[]));

    % This pulls out the coefficients and confidence-intervals placed into
    % a cell array to keep matlab from complaining about the confidence 
    % interval's two-rows being incompatible (or ambiguously defined) when 
    % putting them into a matlab table object.
    p = p{1};    

    if mod(numel(p),3)
        error('Wrong number of parameters (not divisible by 3).');
    end

    pmat = twist(p);
    
    peakfraction = pmat(:,1);
    logforce = pmat(:,2);
    peakbreadth = pmat(:,3);

    weights = peakfraction./peakbreadth;
    weights = weights./max(weights);

    outforce = sum(weights .* logforce)/sum(weights);
    outci = NaN(1,2);

end


function [outlogforce, outrelwidthci] = calcdetachforce_CFTBXmethod(p, pconf)
% "CFTBX" stands for "curve-fitting toolbox." This version of the function 
% includes values for basic confidence intervals.

    twist = @(x)transpose(reshape(x,3,[]));

    % This pulls out the coefficients and confidence-intervals placed into
    % a cell array to keep matlab from complaining about the confidence 
    % interval's two-rows being incompatible (or ambiguously defined) when 
    % putting them into a matlab table object.
    if iscell(p)
        p = p{1};
        pconf = pconf{1};
    end

    if mod(numel(p),3)
        error('Wrong number of parameters (not divisible by 3).');
    end

% %     % relative width of confidence interval compared to value
% %     relwidth = diff(pconf,[],1) ./ p;

    % ba_relwidth is looking for a column vector and column-oriented matrix,
    % so transpose first since they are row-ordered here.
    relwidth = transpose(ba_relwidthCI(p', pconf'));

    p = twist(p); 
    relwidth = twist(relwidth);

    % filter out detachment force parameters that greatly exceed the
    % assay's ability to measure
    idx = (p(:,2) >= -3 & p(:,2) <= 4);
    peakfraction = p(idx,1);
    logforce = p(idx,2);
    logforce_cispan = relwidth(idx,2);
    peakwidth = p(idx,3);

    outlogforce = transpose(logforce(:));
    outrelwidthci = transpose(logforce_cispan(:));    

end

% 
% function [outforce, outci] = sa_extractdetachforce(fitobject)
%     fo = fitobject{1};
%     
%     if isa(fo,'char')
%         outforce = NaN;
%         outci = NaN(1,2);
%         return
%     end
%     
%     fco = coeffvalues(fo)';
%     ci = confint(fo)';
% 
%  
% end
