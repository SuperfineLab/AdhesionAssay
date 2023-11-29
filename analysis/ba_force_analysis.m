function outs = ba_force_analysis(ba_process_data, diameter_range)


    FileTableVars = {'PlateID', 'Fid', 'MeanFps', 'Media', 'SampleName', ...
                     'BeadChemistry', 'SubstrateChemistry', 'MagnetGeometry', ...
                     'pH', 'MediumViscosity', 'Well'};
    ForceTableVars = {'Fid', 'SpotID', 'Mean_time', 'Mean_vel', 'Force', ...
                      'ForceInterval', 'ZmotorPos', 'FractionLeft'};
    BeadInfoVars = {'Fid', 'SpotID', 'BeadPosition', 'BeadRadius', 'VSTarea'};
    
    T = innerjoin(ba_process_data.FileTable(:,FileTableVars), ...
                  ba_process_data.ForceTable(:,ForceTableVars));
    T = innerjoin(T, ba_process_data.BeadInfoTable(:,BeadInfoVars));
    
    T.BeadDiameters = T.BeadRadius*2*0.692;

    bead_mean_diameter = mean(T.BeadDiameters);
    bead_median_diameter = median(T.BeadDiameters);
    bead_mad = mad(T.BeadDiameters);
    bead_std_diameter = std(T.BeadDiameters);
    
    if nargin < 2 || isempty(diameter_range)
        diameter_range = [bead_median_diameter - 2*bead_mad ...
                          bead_median_diameter + 2*bead_mad];
    end

    logentry(['Median bead size: ', num2str(bead_median_diameter, '%02.1f' ), ...
              ' ± '               , num2str(bead_mad, '%02.1f')]);
    logentry(['Acceptable bead range: [', num2str(diameter_range(1), '%02.1f'), ' ', ...
                                          num2str(diameter_range(2), '%02.1f'), '].']);
    T.AcceptableBeadSize = T.BeadDiameters > diameter_range(1) & ...
                           T.BeadDiameters < diameter_range(2);

    % pull out the data
    zpos = T.ZmotorPos(T.AcceptableBeadSize);
    force = T.Force(T.AcceptableBeadSize);
    forceinterval = T.ForceInterval(T.AcceptableBeadSize);
    w = T.Weights(T.AcceptableBeadSize);

    [x_zpos, y_force, weights] = prepareCurveData( log10(zpos), log10(force), w );
    
    % Set up fittype and options.
    ft = fittype( 'poly1' );
    lowestMM  = 0.5; % [mm]
    highestMM = 5.0; % [mm]
    excludedPoints = (x_zpos < log10(lowestMM)) | (x_zpos > log10(highestMM));    
    opts = fitoptions( 'Method', 'LinearLeastSquares' );
    opts.Weights = weights;
    opts.Exclude = excludedPoints;

    % Fit model to data.
    [fitresult, gof] = fit( x_zpos, y_force, ft, opts );
    
    figure; 
    h = histogram(T.BeadDiameters);
    xlabel('Bead diameter [\mum]');
    ylabel('count');
    title(['Median diameter = ', num2str(bead_median_diameter, '%02.1f'), ...
            ' ± ', num2str(bead_mad, '%02.1f')]);
    hold on
        histogram(T.BeadDiameters(~T.AcceptableBeadSize), h.BinEdges);
    hold off
    
%     figure; 
%     errorbar(T.ZmotorPos, force*1e9, abs(forceinterval*1e9), '.')
%     xlabel('Z-motor distance from surface [mm]');
%     ylabel('Force [nN]');
%     ax = gca; 
%     ax.XScale = "log"; 
%     ax.YScale = "log";

    % Plot fit with data.
    figure( 'Name', 'untitled fit 1' );
    plot( fitresult, x_zpos, y_force, excludedPoints, 'predobs', 0.9 );    
    hold on
    plot(log10(T.ZmotorPos(~T.AcceptableBeadSize)), ...
         log10(T.Force(~T.AcceptableBeadSize)), 'ro');                
    hold off    
    ax = gca;
    leg = legend( ax, { 'logy vs. logx with w', ...
                       'Excluded logy vs. logx with w', ...
                       'untitled fit 1', ...
                       'Lower bounds (untitled fit 1)', ...                       
                       'Upper bounds (untitled fit 1)', ...
                       'beads outside size range' }, ... 
                       'Location', 'SouthWest', 'Interpreter', 'none' );        


    xlabel( 'log(distance) [mm]', 'Interpreter', 'none' );
    ylabel( 'log(Force) [N]', 'Interpreter', 'none' );
    grid on


outs = fitresult;


