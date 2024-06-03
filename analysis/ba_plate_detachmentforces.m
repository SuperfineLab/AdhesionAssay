function [TableOut, optstartT] = ba_plate_detachmentforces(ba_process_data, aggregating_variables, fitmethod, weightmethod)
% XXX @jeremy TODO: Add documentation for this function
%

% function [TableOut, fr] = ba_plate_detachmentforces(ba_process_data, aggregating_variables, modeltype, weightTF, plotTF)

    if nargin < 4 || isempty(weightmethod)
        weightmethod = 'unweighted';
    end

    if nargin < 3 || isempty(fitmethod)
        fitmethod = 'fit';
    end
    
    Data = ba_process_data;

    % "Fraction Left" plot is always going to be plotting the Fraction of beads
    % left to detach vs the force at which they detach. SO, that means all we
    % need are the aggregating variables AND those relevant columns    
    FileTableVars = unique([{'PlateID', 'Fid', 'Well', ...
                             'PlateRow', 'PlateColumn', 'FirstFrameBeadCount', 'LastFrameBeadCount'}, ...
                             aggregating_variables(:)'], 'stable');
    ForceTableVars = {'Fid', 'SpotID', 'Force', ...
                      'ForceInterval', 'ForceRelWidth', 'Weights'};

    RelevantData = innerjoin(Data.ForceTable(:,ForceTableVars), ...
                             Data.FileTable(:, FileTableVars), ...
                             'Keys', {'Fid'});         

    %
    % Calculate fraction left according to aggregation parameters
    %
    agglist(1,:) = unique(['PlateID' aggregating_variables(:)'], 'stable');
    Np = numel(agglist);

    [g, ~] = findgroups(RelevantData(:, agglist));
    tmp = splitapply(@(x1,x2,x3,x4){ba_fracleft(x1,x2,x3,x4)}, ...
                                    RelevantData.Fid, ...
                                    RelevantData.SpotID, ...
                                    RelevantData.Force, ...
                                    RelevantData.FirstFrameBeadCount, ...
                                    g);
    tmp = vertcat(tmp{:});
    foo = table(tmp(:,1), tmp(:,2), tmp(:,3),'VariableNames', {'Fid', 'SpotID', 'FractionLeft'});
    RelevantData = innerjoin(RelevantData, foo, 'Keys', {'Fid', 'SpotID'});
    clear g tmp foo

    %
    % Sort the DataTable to present FractionLeft in decending order
    RelevantData = sortrows(RelevantData, [agglist "FractionLeft"], [repmat("ascend", 1, Np) "descend"]);


    % 0. Tack on the "IncludeinFit" Variable so we can filter some out later
    RelevantData.IncludeInFit = true(height(RelevantData),1);

    % 1. Put forces into the correct units (nanoNewtons) for fitting
    RelevantData.Force = RelevantData.Force * 1e9;
    RelevantData.ForceInterval = RelevantData.ForceInterval * 1e9;

% % %     % 2. Evaluate weights by input choice (if no weights on input, then all
% % %     %    are weighted equally as 1.
% % %     if ~weightmethod
% % %         RelevantData.Weights = ones(height(RelevantData),1);
% % %     end  

    % 3. Tag forces that extend below a lower threshold force (bead
    %    force_gravity - buoyancy force = 0.014 nN.
    threshold_force = 0.014;
    RelevantData.IncludeInFit(RelevantData.Force < threshold_force) = false;


    % 4. Optimize starting points according to number of modes
    Nmodes = 2;
    [g, tmpT] = findgroups(RelevantData(:, agglist));
%     [g, grpT] = findgroups(RelevantData(:, unique(['PlateID', aggregating_variables])));
    optstartT = splitapply(@(x1,x2,x3,x4,x5)sa_optimize_start(x1,x2,x3,x4,x5,Nmodes), ...
                                                         log10(RelevantData.Force), ...
                                                         log10(RelevantData.ForceInterval), ...
                                                         RelevantData.FractionLeft, ...
                                                         RelevantData.Weights, ...
                                                         RelevantData.IncludeInFit, ...
                                                         g);
    optstartT = horzcat(tmpT, optstartT);
    RelevantData = innerjoin(RelevantData, optstartT);

    %
    % Note: At this point we are done conditioning the RelevantData table
    % and will move to constructing the output data table.
    %

    % 4b. After joining the two previous tables, the groups need re-defining 
    %     because of possible re-sorting.
    [g, TableOut] = findgroups(RelevantData(:, agglist));


    % 5. Assemble RawData tables for each condition. This breaks the Tidy Data
    %    edict, but this is only for convenient plotting later.
    TableOut.RawData = splitapply(@(x1,x2,x3,x4,x5,x6){sa_assemble_rawdata(x1,x2,x3,x4,x5,x6)}, ...
                               RelevantData.Force, ...
                               RelevantData.ForceRelWidth, ...
                               RelevantData.ForceInterval, ...
                               RelevantData.FractionLeft, ...
                               RelevantData.Weights, ...
                               RelevantData.IncludeInFit, ...
                               g);


    % 6. Add in "include" variable for each FULL curve.
    TableOut.IncludeCurve = true(height(TableOut),1);

%     TableOut = horzcat(TableOut, optstartT(:, {''}));

    % 7. Do the final fits and bootstrapping for stats collection
    fitT = splitapply(@(x1,x2,x3,x4)ba_fit_erf(x1,x2,x3,x4,Nmodes,fitmethod), ...
                                      log10(RelevantData.Force), ...                                                  
                                      RelevantData.FractionLeft, ...
                                      RelevantData.Weights, ...
                                      RelevantData.OptimizedStartParameters, ...
                                      g);     
    TableOut = horzcat(TableOut, fitT);
    TableOut = movevars(TableOut, 'PlateID', "Before", 1);
%     grpT = movevars(grpT, {'BeadChemistry', 'SubstrateChemistry', 'Media'}, "After", "PlateID");

    % 8. Extract detachment forces and their relative certainty

%     g = findgroups(RelevantData(:, unique(['PlateID', aggregating_variables])));
%     [tmpa, tmpb] = splitapply(@(x1,x2)calcdetachforce_CFTBXmethod(x1,x2), fitfoo.FitParams, fitfoo.confFitParams, g);
    filterTF = false;
    [tmpa, tmpb] = cellfun(@(x1,x2)calcdetachforce_CFTBXmethod(x1,x2), fitT.FitParams, fitT.confFitParams, 'UniformOutput',false);
    TableOut.logDetachForce = tmpa;
    TableOut.relwidthDetachForce = tmpb;
    TableOut.DetachForce = cellfun(@(x1,x2)reduce2oneforce(x1,x2,filterTF), TableOut.logDetachForce, TableOut.relwidthDetachForce, 'UniformOutput',false);
    TableOut.DetachForce = 10.^cell2mat(TableOut.DetachForce);

    TableOut.Properties.VariableUnits{'DetachForce'} = '[nN]';

end


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


%
% Support Functions
%
function OptStartT = sa_optimize_start(logforce_nN, logforceinterval, fractionleft, weights, includetf, nmodes)

    Npoints = numel(logforce_nN);
    highestNmodes = floor((Npoints-1)/3);
    
    if highestNmodes < nmodes
        nmodes = highestNmodes;
        logentry(['Demoting Nmodes to ', num2str(nmodes), ' mode(s).']);
    end


% (logforce_nN, fractionLeft, weights, Nmodes)
    OptStartT = ba_optimize_startpoint(logforce_nN(includetf), ...
                                       logforceinterval(includetf,:), ...
                                       fractionleft(includetf), ...
                                       weights(includetf), ...
                                       nmodes);
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


function outs = sa_assemble_rawdata(force, force_relwidth, force_interval, fractionleft, weights, includetf)
    outs = table(force, force_relwidth, force_interval, fractionleft, weights, includetf);
    outs.Properties.VariableNames = {'Force', 'ForceRelWidth', 'ForceInterval', 'FractionLeft', 'Weights', 'IncludeInFit'};
    outs.Properties.VariableUnits = {'[nN]',  '[nN]',          '[nN]',          '[]',           '[]',      '[]'};
end