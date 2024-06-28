function [TableOut, optstartT] = ba_force_curve_fits(ba_process_data, groupvars, fitmethod, weightmethod)
% XXX @jeremy TODO: Add documentation for this function
%

% function [TableOut, fr] = ba_force_curve_fits(ba_process_data, groupvars, modeltype, weightTF, plotTF)

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
                             groupvars(:)'], 'stable');
    BeadForceTableVars = {'Fid', 'SpotID', 'Force', ...
                      'ForceInterval', 'ForceRelWidth', 'Weights'};

    RelevantData = innerjoin(Data.BeadForceTable(:,BeadForceTableVars), ...
                             Data.FileTable(:, FileTableVars), ...
                             'Keys', {'Fid'});         

    %
    % Calculate fraction left according to aggregation parameters
    %
    agglist(1,:) = unique(['PlateID' groupvars(:)'], 'stable');
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

    % % 3a. Find and exclude datasets with less than three points    
    % % XXX @jeremy TODO: Add in filter for removing datasets with fewer than some number of points Npoints>3?
    %                     Maybe it would look something like this...
    % MinNpoints = 3;
    % [g, tmpT] = findgroups(RelevantData(:, agglist));
    % ExcludeList = splitapply(@(x1)sa_excludeLowNcurves(x1,MinNpoints), RelevantData.IncludeInFit, g);
    % tmpT = horzcat(tmpT, ExcludeList);
    % RelevantData = innerjoin(RelevantData, tmpT);

    % 3b. Determine the Number of modes to fit to each curve, with a
    % maximum set as the "common" value.
    DefaultNmodes = 2;
    [g, tmpT] = findgroups(RelevantData(:, agglist));
    ModeList = splitapply(@(x1)sa_calcNmodes(x1,DefaultNmodes), RelevantData.IncludeInFit, g);
    tmpT = horzcat(tmpT, ModeList);
    RelevantData = innerjoin(RelevantData, tmpT);

    % 4. Optimize starting points according to number of modes

    [g, tmpT] = findgroups(RelevantData(:, agglist));
    optstartT = splitapply(@(x1,x2,x3,x4,x5)sa_optimize_start(x1,x2,x3,x4,x5), ...
                                                         log10(RelevantData.Force), ...
                                                         RelevantData.FractionLeft, ...
                                                         RelevantData.Weights, ...
                                                         RelevantData.IncludeInFit, ...
                                                         RelevantData.Nmodes, ...
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


    % 5. Assemble RawData tables for each condition, which breaks the 
    %    Tidy Data edict, but this is only for convenient plotting later.
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
    fitT = splitapply(@(x1,x2,x3,x4,x5)ba_fit_erf(x1,x2,x3,x4,x5,fitmethod), ...
                                      log10(RelevantData.Force), ...                                                  
                                      RelevantData.FractionLeft, ...
                                      RelevantData.Weights, ...
                                      RelevantData.OptimizedStartParameters, ...
                                      RelevantData.Nmodes, ...
                                      g);     
    TableOut = horzcat(TableOut, fitT);
    TableOut = movevars(TableOut, 'PlateID', "Before", 1);

end


%
% Support Functions
%
function OptStartT = sa_optimize_start(logforce_nN, fractionleft, weights, includetf, nmodes)

    OptStartT = ba_optimize_startpoint(logforce_nN(includetf), ...                                     logforceinterval(includetf,:), ...
                                       fractionleft(includetf), ...
                                       weights(includetf), ...
                                       nmodes(1));
end


function outs = sa_assemble_rawdata(force, force_relwidth, force_interval, fractionleft, weights, includetf)
    outs = table(force, force_relwidth, force_interval, fractionleft, weights, includetf);
    outs.Properties.VariableNames = {'Force', 'ForceRelWidth', 'ForceInterval', 'FractionLeft', 'Weights', 'IncludeInFit'};
    outs.Properties.VariableUnits = {'[nN]',  '[nN]',          '[nN]',          '[]',           '[]',      '[]'};
end


function NmodesOutT = sa_calcNmodes(includetf, nmodes)

    Npoints = sum(includetf);
    highestNmodes = floor((Npoints-1)/3);

    % hacking this in because the amplitudes which sum to one, i.e.,
    % a+b+c=1, are reduced to "a" alone, which must equal one. This reduces
    % the number of unknowns in the equation to 2 ("am" and "as").
    if Npoints == 3
        highestNmodes = 1;
    end

    if highestNmodes < nmodes
        NmodesOut = highestNmodes;
        logentry(['Demoting Nmodes to ', num2str(highestNmodes), ' mode(s).']);
    else
        NmodesOut = nmodes;
    end

    NmodesOutT = table(NmodesOut,'VariableNames',{'Nmodes'});
end