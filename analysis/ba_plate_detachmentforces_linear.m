function [TableOut, fr] = ba_plate_detachmentforces_linear(ba_process_data, aggregating_variables, weightTF)

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
    
    minFraction = 0.3;
    maxFraction = 0.7;
    KeepInterval = RelevantData.FractionLeft < maxFraction & ...
                   RelevantData.FractionLeft > minFraction;
    RelevantData = RelevantData(KeepInterval,:);
    
    [g, grpF] = findgroups(RelevantData(:,aggregating_variables));
    
    grpFstr = string(table2array(grpF));
    ystrings = join(grpFstr, '_');
    
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
    for k = 1:height(grpF)
        idx = (g == gn(k) );
        
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
        
        % debug figure
        figure;
        plot(fitresult, xData, yData, '.');
        hold on;
        errorbar(xData, yData, Fhigh(idx), 'horizontal', '.');
        title(string(PlateID), 'Interpreter', 'none');
        hold off;
        drawnow;
    end
    
    outs = struct2table(outs);
    gofT = struct2table(gof);

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


function [fitresult, gof] = createErfFit(xData, yData)
    
    % % Fit: 'untitled fit 1'.
    [xData_1, yData_1] = prepareCurveData( xData, yData );
    
    % Set up fittype and options.
    ft = fittype( 'erfc(b*x)+erfc(d*x)', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.StartPoint = [0.306349472016557 0.51077156417211];
    
    % Fit model to data.
    [fitresult, gof] = fit( xData_1, yData_1, ft, opts );
    
    % Plot fit with data.
    figure( 'Name', 'untitled fit 1' );
    h = plot( fitresult, xData_1, yData_1 );
    legend( h, 'yData vs. xData', 'untitled fit 1', 'Location', 'NorthEast', 'Interpreter', 'none' );
    % Label axes
    xlabel( 'xData', 'Interpreter', 'none' );
    ylabel( 'yData', 'Interpreter', 'none' );
    grid on

end



% function outs = sa_sortforce(forceANDfractionleft, direction)
% 
%     if nargin < 2 || isempty(direction)
%         direction = 'ascend';
%     end
% 
%     [outs,Fidx] = sortrows(forceANDfractionleft, direction);
% 
% end