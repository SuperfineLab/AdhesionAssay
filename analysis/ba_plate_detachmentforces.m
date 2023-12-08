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
    
    FileTableVars = [{'PlateID', 'Fid'}, aggregating_variables(:)'];
    ForceTableVars = {'Fid', 'SpotID', 'Force', 'ForceError', 'Weights', 'FractionLeft'};
    
    PlateID = unique(Data.FileTable.PlateID);
    
%     if length(PlateID) > 1
%         error('Something is amiss. There should only be one plate''s worth of data here.');
%     end
    
    RelevantData = innerjoin(Data.ForceTable(:,ForceTableVars), ...
                             Data.FileTable(:, FileTableVars), ...
                             'Keys', {'Fid'});
        
    [g, grpT] = findgroups(RelevantData(:,['PlateID', aggregating_variables]));
    
    grpTstr = string(table2array(grpT));
    ystrings = join(grpTstr, '_');
    
%     foo = splitapply(@(x1,x2,x3)ba_fit_erf(x1,x2,x3), log10(RelevantData.Force*1e9), ...
%                                                       RelevantData.FractionLeft, ...
%                                                       RelevantData.Weights);

    F = RelevantData.Force*1e9;
    Ferr = RelevantData.ForceError*1e9;
    frac = RelevantData.FractionLeft;
    % Flow = abs(F - RelevantData.ForceInterval(:,1)*1e9);
    Fhigh= abs(RelevantData.ForceError(:,1)*1e9 - F);
    
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
        switch modeltype
            case 'erf'
                 
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
                    outs(k,1).am = NaN;
                    outs(k,1).amconf = [NaN NaN];
                    outs(k,1).as = NaN;
                    outs(k,1).asconf = [NaN NaN];
                    outs(k,1).bm = NaN;
                    outs(k,1).bmconf = [NaN NaN];
                    outs(k,1).bs = NaN;
                    outs(k,1).bsconf = [NaN NaN];
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

                 

            case 'linear'
                % % Fit: 'Linear'.     
                [xData, yData, weights] = prepareCurveData( log10(F(idx)), frac(idx), w(idx) );
                ft = fittype( 'a + b*x', 'independent', 'x', 'dependent', 'y' );
                opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
                opts.Display = 'Off';
                opts.Weights = weights;   
                    
                % Fit model to data.
                try
                    [fitresult, gof(k,1)] = fit( xData, yData, ft, opts );
                    ci = confint(fitresult)';
                    fr{k} = fitresult;
                    outs(k,1).a = fitresult.a;
                    outs(k,1).aconf = ci(1,:);
                    outs(k,1).b = fitresult.b;
                    outs(k,1).bconf = ci(2,:);
                catch        
                    outs(k,1).a = NaN;
                    outs(k,1).aconf = [NaN NaN];
                    outs(k,1).b = NaN;
                    outs(k,1).bconf = [NaN NaN];
                end
                
%                 % debug figure
%                 figure;
%                 plot(fitresult, xData, yData, '.');
%                 hold on;
%                 errorbar(xData, yData, Fhigh(idx), 'horizontal', '.');
%                 title(string(PlateID), 'Interpreter', 'none');
%                 hold off;
%                 drawnow;

            case 'exp'
                [xData, yData, weights] = prepareCurveData( F(idx), frac(idx), w(idx) );
                
                % ft = fittype( 'a*exp(-b*x)+(1-a)*exp(-c*x)', 'independent', 'x', 'dependent', 'y' );
                ft = fittype( 'a*exp(-b*x)+c', 'independent', 'x', 'dependent', 'y' );
                opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
                opts.Display = 'Off';
                opts.Upper = [1 Inf Inf];
                opts.Lower = [0 0 0];
                % opts.StartPoint = [1 0.5 0.5];
                opts.Weights = weights;
                opts.StartPoint = [0.750468607549764 0.192644774570146 0.568675630542075];
            
                % Fit model to data
                 try
                    [fitresult, gof(k,1)] = fit( xData, yData, ft, opts );
                    ci = confint(fitresult)';
                    fr{k} = fitresult;
                    outs(k,1).a = fitresult.a;
                    outs(k,1).aconf = ci(1,:);
                    outs(k,1).b = fitresult.b;
                    outs(k,1).bconf = ci(2,:);
                    outs(k,1).c = fitresult.c;
                    outs(k,1).cconf = ci(3,:);
                catch        
                    outs(k,1).a = NaN;
                    outs(k,1).aconf = [NaN NaN];
                    outs(k,1).b = NaN;
                    outs(k,1).bconf = [NaN NaN];
                    outs(k,1).c = NaN;
                    outs(k,1).cconf = [NaN NaN];
                end
        
%         % debug figure
%         figure;
%         plot(fitresult, xData, yData, '.');
%         hold on;
%         errorbar(xData, yData, Fhigh(idx), 'horizontal', '.');
%         title(string(PlateID), 'Interpreter', 'none');
%         hold off;
%         drawnow;


            otherwise
                error('Model type not found.');
        end

        if plotTF
            ba_plot_fit(fitresult, ForceData{k,1}, ForceError{k,1}, PctLeftData{k,1});
        end

    end
    
       
    if strcmp('erf',modeltype) == 1
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
    else
        outs = struct2table(outs);
        gofT = struct2table(gof);
        [g, grpF] = findgroups(RelevantData(:,aggregating_variables));
        % fit form is fraction_left = a*exp(-b*force)+c. Solving for force
        % yields:   force = -1/b*ln((fraction_left-c)/a))
        % Assuming the detachment force is set to 50%, this reduces to:
        %           force = -1/b*ln((0.5-c)/a))
        detachforce = @(a,b)((0.5-a)./b);
        logdf = detachforce(outs.a, outs.b);
        
        TableOut = [grpF outs];
        TableOut.DetachForce = 10.^logdf;
        TableOut.confDetachForce(:,1) = 10.^detachforce(outs.aconf(:,1), outs.bconf(:,1));
        TableOut.confDetachForce(:,2) = 10.^detachforce(outs.aconf(:,2), outs.bconf(:,2));
        TableOut.PlateID = repmat(PlateID, height(TableOut),1);
        TableOut = movevars(TableOut, 'PlateID', 'Before', 1);
    end
end







