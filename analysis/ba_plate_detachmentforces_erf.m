function [TableOut, fr] = ba_plate_detachmentforces_erf(ba_process_data, aggregating_variables, weightTF, plotTF)

    if nargin < 3 || isempty(weightTF)
        weightTF = true;
    end
    
    Data = ba_process_data;
    
    % "Fraction Left" plot is always going to be plotting the Fraction of beads
    % left to detach vs the force at which they detach. SO, that means all we
    % need are the aggregating variables AND those relevant columns
    
    FileTableVars = [{'PlateID', 'Fid'}, aggregating_variables(:)'];
    ForceTableVars = {'Fid', 'SpotID', 'Force', 'ForceError', 'Weights', 'FractionLeft'};
    
    PlateID = unique(Data.FileTable.PlateID);
    
    if length(PlateID) > 1
        error('Something is amiss. There should only be one plate''s worth of data here.');
    end
    
    RelevantData = innerjoin(Data.ForceTable(:,ForceTableVars), ...
                             Data.FileTable(:, FileTableVars), ...
                             'Keys', 'Fid');
        
    [g, grpT] = findgroups(RelevantData(:,aggregating_variables));
    
    grpTstr = string(table2array(grpT));
    ystrings = join(grpTstr, '_');
    
%     foo = splitapply(@(x1,x2,x3)ba_fit_erf(x1,x2,x3), log10(RelevantData.Force*1e9), ...
%                                                       RelevantData.FractionLeft, ...
%                                                       RelevantData.Weights);

    F = RelevantData.Force*1e9;
    Ferr = RelevantData.ForceError*1e9;
    frac = RelevantData.FractionLeft;
    
    if weightTF
        w = RelevantData.Weights;
    else
        w = ones(numel(F),1);
    end
    
    gn = unique(g);
    for k = 1:height(grpT)
        idx = (g == gn(k) );
        
        ForceData{k,1} = F(idx);
        ForceError{k,1} = Ferr(idx);
        PctLeftData{k,1} = frac(idx);
        Weights{k,1} = w(idx);

        % Fit model to data.
        try
            [fitresult,gof] = ba_fit_erf( log10(ForceData{k,1}), ...
                                          PctLeftData{k,1}, ...
                                          Weights{k,1} );            
            ci = confint(fitresult)';
            fr{k,1} = fitresult;
            gofout(k,1) = gof;
            outs(k,1).a = fitresult.a;
            outs(k,1).aconf = ci(1,:);
            outs(k,1).am = fitresult.am;
            outs(k,1).amconf = ci(2,:);
            outs(k,1).as = fitresult.as;
            outs(k,1).asconf = ci(3,:);
            outs(k,1).bm = fitresult.bm;
            outs(k,1).bmconf = ci(4,:);
            outs(k,1).bs = fitresult.bs;
            outs(k,1).bsconf = ci(5,:);
        catch        
            fr{k} = '';
            gofout(k).sse = NaN;
            gofout(k).rsquare = NaN;
            gofout(k).dfe = NaN;
            gofout(k).adjrsquare = NaN;
            gofout(k).rmse = NaN;
            outs(k,1).a = NaN;
            outs(k,1).aconf = [NaN NaN];

            outs(k,1).a = NaN;
            outs(k,1).aconf = [NaN NaN];
            outs(k,1).am = NaN;
            outs(k,1).amconf = [NaN NaN];
            outs(k,1).as = NaN;
            outs(k,1).asconf = [NaN NaN];
            outs(k,1).bm = NaN;
            outs(k,1).bmconf = [NaN NaN];
            outs(k,1).bs = NaN;
            outs(k,1).bsconf = [NaN NaN];
        end
        
        if plotTF
            ba_plot_fit(fitresult, ForceData{k,1}, ForceError{k,1}, PctLeftData{k,1});
        end

    end

    for k = 1:length(outs)
        if outs(k).a > 0.5
            DetachForce(k,1) = outs(k).am;
            confDetachForce(k,:) = outs(k).amconf;
        else
            DetachForce(k,1) = outs(k).bm;
            confDetachForce(k,:) = outs(k).bmconf;
        end
    end

    ForceData = cell2table(ForceData, 'VariableNames', {'ForceData'});
    ForceError = cell2table(ForceError, 'VariableNames', {'ForceError'});
    DetachForce = table(DetachForce, 'VariableNames', {'DetachForce'});
    confDetachForce = table(confDetachForce, 'VariableNames', {'confDetachForce'});    
    PctLeftData = cell2table(PctLeftData, 'VariableNames', {'PctLeftData'});
    Weights = cell2table(Weights, 'VariableNames', {'Weights'});

    outs = struct2table(outs);
    gofT = struct2table(gofout);
    frT = cell2table(fr(:), 'VariableNames', {'FitObject'});
    % gofT = fillmissing(gofT, 'Constant', NaN);
        
    TableOut = [grpT outs gofT frT ForceData ForceError DetachForce PctLeftData Weights] ;
    
end







