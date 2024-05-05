function m = ba_get_linefits(TrackingTable, calibum, visc_Pas, bead_diameter_um, Fid)
% BA_GET_LINEFITS calculates bead velocity and force from displacement line fits.
%


if isempty(TrackingTable)
    m = table('Size', [0 11], ...
              'VariableTypes', {'double', 'double', 'double', ...
                                'double', 'double', 'double', 'double', ...
                                'double', 'double', 'double', 'double'},...
              'VariableNames', {'Fid', 'SpotID', 'StartPosition', ...
                                'Pulloff_time', 'Mean_time', 'Mean_vel', 'VelInterval', ...
                                'Force', 'ForceInterval', 'ForceRelWidth', 'Weights'});
    return
end

% lower threshold force (bead: force_gravity - buoyancy force = 0.014 nN.
lowForceLimit = 0.014 * 1e-9; % [N]

t = TrackingTable.Frame ./ TrackingTable.Fps; % [s]
[g, ID] = findgroups(TrackingTable.ID);

myfits = splitapply(@(x,y)mylinfit(x,y,1), t, TrackingTable.Z, g);
sp = splitapply(@(x,y)get_startpos(x,y), TrackingTable.X, TrackingTable.Y, g);

mb = cell2mat(myfits(:,3));

m.Fid = repmat(Fid, size(myfits,1), 1);
% m.Filename = repmat(string(evtfile), size(myfits,1), 1);
m.SpotID = ID;
m.StartPosition = cell2mat(sp);
m.Pulloff_time = cell2mat(myfits(:,1)); % [s]
m.Mean_time = cell2mat(myfits(:,2)); % [s]
m.Mean_vel = mb(:,1) * calibum * 1e-6; % [m/s]
m.VelInterval = cell2mat(myfits(:,4)) * calibum * 1e-6; % [m/s]
m.Force = 6 * pi * visc_Pas * (bead_diameter_um/2 * 1e-6) * m.Mean_vel; % [N]
m.ForceInterval = 6 * pi * visc_Pas * bead_diameter_um/2 * 1e-6 * m.VelInterval; % [N]
m.ForceInterval(m.ForceInterval <= lowForceLimit) = lowForceLimit;
m.ForceRelWidth = ba_relwidthCI(m.Force, m.ForceInterval);
m.Weights = ba_weights(m.ForceInterval, 0.95);

m = struct2table(m);

m = fleshout_table_metadata(m);

end

function outs = get_startpos(x,y)
    outs{1,1} = x(1);
    outs{1,2} = y(1);
end

% function outs = mylinfit(t,z,order)
%     mb = polyfit(t,z,order);
%     outs{1,1} = t(1);
%     outs{1,2} = mean(t);
%     outs{1,3} = mb;
% end

function outs = mylinfit(t,z,order)

    conflevel = 0.95;

    myfit = fit(t,z,'poly1');
    cf = transpose(confint(myfit,conflevel));
    
%     mb = polyfit(t,z,order);
    outs{1,1} = t(1);
    outs{1,2} = mean(t);
    outs{1,3} = myfit.p1;
    outs{1,4} = cf(1,:);
    
end


function m = fleshout_table_metadata(m)

    meta = {'Fid',           '',      'File ID (generated randomly)'; 
            'SpotID',        '',      'Spot ID (obtained from Spot Tracker)'; 
            'StartPosition', '[px]',  'Starting position of (cleaned) trajectory'; 
            'Pulloff_time',  '[s]',   'First time point from cleaned trajectory'; 
            'Mean_time',     '[s]',   'Average time point from cleaned trajectory'; 
            'Mean_vel',      '[m/s]', 'Average velocity during cleaned trajectory'; 
            'VelInterval',   '[m/s]', 'Confidence interval for velocity fit'; 
            'Force',         '[N]',   'Detachment force applied to tracked SpotID'; 
            'ForceInterval', '[N]',   'Confidence interval for Detachment force'; 
            'ForceRelWidth', '[]',    'Breadth of Force Interval normalized by measured Force'; 
            'Weights',       '[]',    'Weight of Detachment Force, given Interval size'; 
           };
    
    m.Properties.VariableNames = meta(:,1);
    m.Properties.VariableUnits = meta(:,2);
    m.Properties.VariableDescriptions = meta(:,3);

end

