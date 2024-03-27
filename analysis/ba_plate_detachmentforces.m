function [TableOut, fr] = ba_plate_detachmentforces(ba_process_data, aggregating_variables, modeltype, weightTF, plotTF)

    if nargin < 4 || isempty(weightTF)
        weightTF = true;
    end

    if nargin < 3 || isempty(modeltype)
        modeltype = 'erf';
    end
    
    Data = ba_process_data;


% % % %     fooT = innerjoin(Broot.FileTable, Broot.ForceTable, 'Keys', 'Fid');
% % % % figure; plot(log10(fooT.Force), fooT.NewFractionLeft, '.');
% % % % [g gT] = findgroups(fooT.PlateID);
% % % % figure; plot(log10(fooT.Force(g==1)), fooT.NewFractionLeft(g==1), '.');
    
    % "Fraction Left" plot is always going to be plotting the Fraction of beads
    % left to detach vs the force at which they detach. SO, that means all we
    % need are the aggregating variables AND those relevant columns    
    FileTableVars = unique([{'PlateID', 'Fid', 'Well', 'PlateRow', 'PlateColumn', 'FirstFrameBeadCount'}, aggregating_variables(:)']);
%     ForceTableVars = {'Fid', 'SpotID', 'Force', 'ForceInterval', 'ForceRelWidth', 'Weights', 'FractionLeft'};
    ForceTableVars = {'Fid', 'SpotID', 'Force', 'ForceInterval', 'ForceRelWidth', 'Weights'};

    RelevantData = innerjoin(Data.ForceTable(:,ForceTableVars), ...
                             Data.FileTable(:, FileTableVars), ...
                             'Keys', {'Fid'});         
    

    %
    % Calculate fraction left according to aggregation parameters
    %
    agglist(1,:) = unique(['PlateID' aggregating_variables(:)']);
    Np = numel(agglist);

    [g, gT] = findgroups(RelevantData(:, agglist));
    tmp = splitapply(@(x1,x2,x3,x4){ba_fracleft(x1,x2,x3,x4)}, ...
                                    RelevantData.Fid, ...
                                    RelevantData.SpotID, ...
                                    RelevantData.Force, ...
                                    RelevantData.FirstFrameBeadCount, ...
                                    g);
    tmp = vertcat(tmp{:});
    foo = table(tmp(:,1), tmp(:,2), tmp(:,3),'VariableNames', {'Fid', 'SpotID', 'FractionLeft'});
    RelevantData = innerjoin(RelevantData, foo, 'Keys', {'Fid', 'SpotID'});
    clear foo

    RelevantData = sortrows(RelevantData, [agglist "FractionLeft"], [repmat("ascend", Np, 1) "descend"]);


    % 0. Tack on the "IncludeinFit" Variable so we can filter some out later
    RelevantData.IncludeInFit = true(height(RelevantData),1);

    % 1. Put forces into the correct units (nanoNewtons) for fitting
    RelevantData.Force = RelevantData.Force * 1e9;

    % 2. Tag forces that extend below a lower threshold force (bead
    % force_gravity - buoyancy force = 0.014 nN.
    threshold_force = 0.014;
    RelevantData.IncludeInFit(RelevantData.Force < threshold_force) = false;

    % 3. Optimize starting points according to number of modes
    Nterms = 2;
    [g, grpT] = findgroups(RelevantData(:, unique(['PlateID', aggregating_variables])));
    grpT.StartingPoint = splitapply(@(x1,x2,x3,x4)sa_optimize_start(x1,x2,x3,x4,Nterms), ...
                                                   log10(RelevantData.Force), ...
                                                   RelevantData.FractionLeft, ...
                                                   RelevantData.Weights, ...
                                                   RelevantData.IncludeInFit, ...
                                                   g);

    RelevantData = innerjoin(RelevantData, grpT);

    % 3b. After joining, the groups need re-defining because of possible re-sorting
    [g, grpT] = findgroups(RelevantData(:, unique(['PlateID', aggregating_variables])));

    grpT.IncludeCurve = true(height(grpT),1);

    if weightTF
        Weights = RelevantData.Weights;
    else
        Weights = ones(height(RelevantData),1);
    end    

    % 4. Assemble RawData tables for each condition for convenient plotting
    grpT.RawData = splitapply(@(x1,x2,x3,x4,x5,x6){sa_assemble_rawdata(x1,x2,x3,x4,x5,x6)}, ...
                               RelevantData.Force, ...
                               RelevantData.ForceRelWidth, ...
                               RelevantData.ForceInterval, ...
                               RelevantData.FractionLeft, ...
                               RelevantData.Weights, ...
                               RelevantData.IncludeInFit, ...
                               g);
%  ba_fit_erf(logforce, pct_left, weights, startpoint, Nmodes)
    % 5. Perform the One mode and Two mode fits and collect the fitting info
    foo{1} = splitapply(@(x1,x2,x3,x4)ba_fit_erf(x1,x2,x3,x4,1), ...
                                                  RelevantData.Force, ...                                                  
                                                  RelevantData.FractionLeft, ...
                                                  Weights, ...    
                                                  RelevantData.StartingPoint, ...
                                                  g);     
    foo{1} = horzcat(grpT, foo{1});
    foo{2} = splitapply(@(x1,x2,x3,x4)ba_fit_erf(x1,x2,x3,x4,2), ...
                                                  RelevantData.Force, ...                                                  
                                                  RelevantData.FractionLeft, ...
                                                  Weights, ...
                                                  RelevantData.StartingPoint, ...
                                                  g);     
    foo{2} = horzcat(grpT, foo{2});
    FitTable = vertcat(foo{:});

    % 6. Compare fits and use the best (ONE or TWO modes)
    [df, dfT] = findgroups(FitTable(:, unique(['PlateID', aggregating_variables])));
    q = splitapply(@(x1,x2,x3,x4)sa_choosebestmodel(x1,x2,x3,x4), ...
                                         FitTable.FitObject, ...
                                         FitTable.GoodnessOfFit, ...
                                         FitTable.FitOptions, ...
                                         FitTable.Nmodes,  ...
                                         df);
    BestFitTable = horzcat(dfT, q);

        
    % 7. Summarize fitting data
    [sf, sfT] = findgroups(BestFitTable(:, unique(['PlateID', aggregating_variables, 'BestModel'])));
    q = splitapply(@(x1,x2)sa_summarizefits(x1,x2), BestFitTable.FitObject, BestFitTable.GoodnessOfFit, sf);
    FitSummaryTable = [sfT q];

    % 8. Choose dominant detachment force
    [df, dfT] = findgroups(FitSummaryTable(:, unique(['PlateID', aggregating_variables, 'BestModel'])));
    [dfT.DetachForce, dfT.confDetachForce] = splitapply(@(x1,x2)sa_choosedetachforce(x1,x2), BestFitTable.FitObject, BestFitTable.GoodnessOfFit, df);

    % 9. Merge in our RawData summarized before.
    TableOut = innerjoin(dfT, grpT, 'Keys', unique(['PlateID', aggregating_variables]));
    TableOut = movevars(TableOut, "PlateID", "Before", 2);
%     TableOut = movevars(TableOut, {'BeadChemistry', 'SubstrateChemistry', 'Media', 'DetachForce', 'confDetachForce', 'RawData' }, "After", "PlateID");          

end




%
% Support Functions
%
function outs = sa_optimize_start(logforce_nN, fractionleft, weights, includetf, nterms)

    outs = ba_optimize_startpoint(logforce_nN(includetf), ...
                                 fractionleft(includetf), ...
                                 weights(includetf), ...
                                 nterms);

end


function outs = sa_choosebestmodel(fitobject, gof, opt, nmodes) 

    rmse1 = gof(nmodes == 1).rmse;
    rmse2 = gof(nmodes == 2).rmse;

    if rmse1 < rmse2
        disp(['Model One is better! One: ' num2str(rmse1) ' vs Two: ' num2str(rmse2)]);
        best = 1;
    else
        disp(['Model Two is better! One: ' num2str(rmse1) ' vs Two: ' num2str(rmse2)]);
        best = 2;
    end

    outs = table( fitobject(nmodes == best), ...
                  gof(nmodes == best), ...
                  opt(nmodes == best), ...
                  best, ...
                  'VariableNames', {'FitObject', 'GoodnessOfFit', 'FitOptions', 'BestModel'});
        
end


function outs = sa_summarizefits(fitobject,goodness_of_fit)


    fo = fitobject{1};

    fco = coeffvalues(fo);
    fci = confint(fo);

    % If the one-term fit was the best, pad bm and bs with NaN outputs
    if numel(fco) == 3
        fco(1,4:5) = NaN(1,2);
        fci(1:2,4:5) = NaN(2,2);
    end

    fci = transpose(fci);

    a = fco(1);
    am = fco(2);
    as = fco(3);
    bm = fco(4);
    bs = fco(5);

%     [a,am,as,bm,bs] = deal(fco(1:5))

    aconf = fci(1,:);
    amconf = fci(2,:);
    asconf = fci(3,:);
    bmconf = fci(4,:);
    bsconf = fci(5,:);

    CoeffT = table(a, aconf, am, amconf, as, asconf, ...
                             bm, bmconf, bs, bsconf);

    gof = struct2table(goodness_of_fit);

    outs = [CoeffT gof];


end

function [outforce, outci] = sa_choosedetachforce(fitobject,goodness_of_fit)
    fo = fitobject{1};
    
    fco = coeffvalues(fo);
    ci = confint(fo)';

    % Hacked in for a single detachment force value. This
    % doesn't make sense in the long run.                
    if fo.a > 0.5
        outforce = fo.am;
        outci(1,:) = ci(2,:);
    else
        try
            outforce = fo.bm;
            outci(1,:) = ci(4,:);
        catch
            outforce = fo.am;
            outci(1,:) = ci(2,:);
        end
    end      
end


function outs = sa_assemble_rawdata(force, force_error_factor, force_interval, factorleft, weights, includetf)

    outs = table(force, force_error_factor, force_interval, factorleft, weights, includetf);
    outs.Properties.VariableNames = {'Force', 'ForceRelWidth', 'ForceInterval', 'FactorLeft', 'Weights', 'IncludeInFit'};
    outs.Properties.VariableUnits = {'[nN]',  '[nN]',             '[nN]',          '[]',         '[]',      '[]'};
end