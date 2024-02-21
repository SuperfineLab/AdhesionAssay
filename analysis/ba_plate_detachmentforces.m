function [TableOut, fr] = ba_plate_detachmentforces(ba_process_data, aggregating_variables, modeltype, weightTF, plotTF)

    if nargin < 4 || isempty(weightTF)
        weightTF = true;
    end

    if nargin < 3 || isempty(modeltype)
        modeltype = 'erf';
    end
    
    Data = ba_process_data;
    
    % "Fraction Left" plot is always going to be plotting the Fraction of beads
    % left to detach vs the force at which they detach. SO, that means all we
    % need are the aggregating variables AND those relevant columns
    
    FileTableVars = unique([{'PlateID', 'Fid', 'Well', 'PlateRow', 'PlateColumn'}, aggregating_variables(:)']);
    ForceTableVars = {'Fid', 'SpotID', 'Force', 'ForceInterval', 'ForceError', 'Weights', 'FractionLeft'};
    
    RelevantData = innerjoin(Data.ForceTable(:,ForceTableVars), ...
                             Data.FileTable(:, FileTableVars), ...
                             'Keys', {'Fid'});
        
    [g, grpT] = findgroups(RelevantData(:,unique(['PlateID', aggregating_variables])));
    

%     foo = splitapply(@(x1,x2,x3)ba_fit_erf(x1,x2,x3), log10(RelevantData.Force*1e9), ...
%                                                       RelevantData.FractionLeft, ...
%                                                       RelevantData.Weights);

    if weightTF
        Weights = RelevantData.Weights;
    else
        Weights = ones(height(RelevantData),1);
    end
    
    IncludeCurve = true(height(grpT),1);
    IncludeInFit = true(height(RelevantData),1);

    gn = unique(g);
    for k = 1:height(grpT)
        idx = (g == gn(k) );
        
        RawData = table(RelevantData.Force(idx)*1e9, ...
                        RelevantData.ForceError(idx)*1e9, ...
                        RelevantData.ForceInterval(idx,:)*1e9, ...
                        RelevantData.FractionLeft(idx), ...
                        Weights(idx), ...
                        IncludeInFit(idx), ...
                        'VariableNames', {'Force', 'ForceError', 'ForceInterval', 'PctLeft', 'Weights', 'IncludeInFit'});
        RawData = sortrows(RawData, "Force", "ascend");

        % Fit model to data.
        myfits(k,1) = ba_fit_erf( log10(RawData.Force), RawData.PctLeft, RawData.Weights);            

        % Hacked in for a single detachment force value. This
        % doesn't make sense in the long run.                
        if myfits(k).a > 0.5
            DetachForce(k,1) = myfits(k).am;
            confDetachForce(k,:) = myfits(k).amconf;
        else
            DetachForce(k,1) = myfits(k).bm;
            confDetachForce(k,:) = myfits(k).bmconf;
        end                 
                
        if plotTF
            figh = ba_plot_fit(myfits(k,1).FitObject, RawData.Force, RawData.ForceError, RawData.PctLeft);
            figh.Name = [figh.Name, ': ', char(unique(RelevantData.PlateID))];
        end

        RawDataOut{k,1} = RawData;
    end
    
    

    DetachForce = table(DetachForce, 'VariableNames', {'DetachForce'});
    confDetachForce = table(confDetachForce, 'VariableNames', {'confDetachForce'});  
    RawDataOut = cell2table(RawDataOut, 'VariableNames', {'RawData'});
    IncludeCurve = table(IncludeCurve, 'VariableNames', {'IncludeCurve'});

    myfits = struct2table(myfits);

    TableOut = [grpT myfits DetachForce confDetachForce RawDataOut IncludeCurve] ;

end







