function [TableOut, fr] = ba_plate_detachmentforces_erf(ba_process_data, aggregating_variables, weightTF)

    if nargin < 3 || isempty(weightTF)
        weightTF = true;
    end
    
    Data = ba_process_data;
    
    % "Fraction Left" plot is always going to be plotting the Fraction of beads
    % left to detach vs the force at which they detach. SO, that means all we
    % need are the aggregating variables AND those relevant columns
    ForceTableVars = {'Fid', 'SpotID', 'Force', 'ForceInterval', 'FractionLeft'};
    FileTableVars = [{'PlateID', 'Fid'}, aggregating_variables(:)'];
    % FileTableVars = {'Fid', aggregating_variables{:}};
    
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
    
    F = RelevantData.Force*1e9;
    Flow = abs(F - RelevantData.ForceInterval(:,1)*1e9);
    Fhigh= abs(RelevantData.ForceInterval(:,2)*1e9 - F);
    frac = RelevantData.FractionLeft;
    
    if weightTF
        w = 1./abs(Fhigh-F);
    else
        w = ones(numel(F),1);
    end
    
    gn = unique(g);
    for k = 1:height(grpT)
        idx = (g == gn(k) );
        
        ForceData{k,1} = F(idx);
        PctLeftData{k,1} = frac(idx);
        Weights{k,1} = w(idx);

        % Fit model to data.
        try
            [fitresult,gof] = createErfFit( ForceData{k,1}, ...
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
    DetachForce = table(DetachForce, 'VariableNames', {'DetachForce'});
    confDetachForce = table(confDetachForce, 'VariableNames', {'confDetachForce'});    
    PctLeftData = cell2table(PctLeftData, 'VariableNames', {'PctLeftData'});
    Weights = cell2table(Weights, 'VariableNames', {'Weights'});

    outs = struct2table(outs);
    gofT = struct2table(gofout);
    fr = cell2table(fr, 'VariableNames', {'FitObject'});
    % gofT = fillmissing(gofT, 'Constant', NaN);
        
    TableOut = [grpT outs gofT fr ForceData DetachForce confDetachForce PctLeftData Weights] ;
    
end


function [fitresult, gof] = createErfFit(force, pct_left, weights)
    
    % log transform the force
    logforce = log10(force);
    [logforce, pct_left, weights] = prepareCurveData( logforce, pct_left, weights );
    
%     [tmpa,tmpb] = get_good_startpoint(logforce, pct_left, weights);

    % Set up fittype and options.
    ft = fittype( '1/2*(a*erfc(((x)-am)/(sqrt(2)*as))+(1-a)*erfc(((x)-bm)/(sqrt(2)*bs)))', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Lower = [0 0 0 0 0];
    opts.MaxFunEvals = 2600;
    opts.MaxIter = 2400;
    opts.StartPoint = [0.825816977489547 0.0781755287531837 0.442678269775446 0.106652770180584 0.961898080855054];
    %             a  am   as   bm   bs
    opts.Lower = [0 -Inf  0   -Inf  0];
    opts.Upper = [1  Inf  Inf  Inf  Inf];
    opts.Weights = weights;
    

    % Fit model to data.
    [fitresult, gof] = fit( logforce, pct_left, ft, opts );
    
%     % Plot fit with data.
%     figure( 'Name', 'erf fit' );
%     h = plot( fitresult, logforce, pct_left, 'predobs' );
%     legend( h, 'y vs. x with w', 'hbe', 'Lower bounds (hbe)', 'Upper bounds (hbe)', 'Location', 'NorthEast', 'Interpreter', 'none' );
%     % Label axes
%     xlabel( 'x', 'Interpreter', 'none' );
%     ylabel( 'y', 'Interpreter', 'none' );
%     grid on
 
end


function [pks, locs, widths] = get_good_startpoint(logforce, pct_left, weights)
    %% Fit: 'hbe spline'.
    [logforce, pct_left, weights] = prepareCurveData( logforce, pct_left, weights );
    
    % Set up fittype and options.
    ft = fittype( 'smoothingspline' );
    opts = fitoptions( 'Method', 'SmoothingSpline' );
    opts.Normalize = 'on';
%     opts.Normalize = 'off';
    opts.SmoothingParam = 0.96;
    opts.Weights = weights;
    
    % Fit model to data.
    [fitresult, gof] = fit( logforce, pct_left, ft, opts );
    
    myrange = linspace(min(logforce), max(logforce), 1000);
    fitval = fitresult(myrange);
%     dfit = CreateGaussScaleSpace(fitval, 2, 0.5);
    dfit = diff(fitval,2);
    [p, locs] = findpeaks(dfit, myrange(2:end-1));
%     [pks, locs, widths] = findpeaks(dfit, myrange);



    % Plot fit with data.
    figure( 'Name', 'Good ERF startpoints' );
    h = plot( fitresult, logforce, pct_left);
    hold on
    findpeaks(dfit, myrange(2:end-1));
    legend( h, 'y vs. x with w', 'hbe spline', 'Lower bounds (hbe spline)', 'Upper bounds (hbe spline)', 'Location', 'NorthEast', 'Interpreter', 'none' );
    % Label axes
    xlabel( 'logforce', 'Interpreter', 'none' );
    ylabel( 'pct_left', 'Interpreter', 'none' );
    grid on
end

