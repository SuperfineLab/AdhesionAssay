function m = ba_get_linefits(TrackingTable, calibum, visc_Pas, bead_diameter_um, Fid)
% BA_GET_LINEFITS calculates bead velocity and force from displacement line fits.
%


if isempty(TrackingTable)
    m = table('Size', [0 10], ...
              'VariableTypes', {'double', 'double', 'double', ...
                                'double', 'double', 'double', 'double', ...
                                'double', 'double', 'double'},...
              'VariableNames', {'Fid', 'SpotID', 'StartPosition', ...
                                'Pulloff_time', 'Mean_time', 'Mean_vel', 'VelInterval', ...
                                'Force', 'ForceError', 'Weights'});
    return
end

t = TrackingTable.Frame ./ TrackingTable.Fps;
[g, ID] = findgroups(TrackingTable.ID);

myfits = splitapply(@(x,y)mylinfit(x,y,1), t, TrackingTable.Z, g);
sp = splitapply(@(x,y)get_startpos(x,y), TrackingTable.X, TrackingTable.Y, g);

mb = cell2mat(myfits(:,3));

m.Fid = repmat(Fid, size(myfits,1), 1);
% m.Filename = repmat(string(evtfile), size(myfits,1), 1);
m.SpotID = ID;
m.StartPosition = cell2mat(sp);
m.Pulloff_time = cell2mat(myfits(:,1));
m.Mean_time = cell2mat(myfits(:,2));
m.Mean_vel = mb(:,1) * calibum * 1e-6;
m.VelInterval = cell2mat(myfits(:,4)) * calibum * 1e-6;
m.Force = 6 * pi * visc_Pas * bead_diameter_um/2 * 1e-6 * m.Mean_vel;

m.ForceInterval = 6 * pi * visc_Pas * bead_diameter_um/2 * 1e-6 * m.VelInterval;
m.ForceError = abs(ForceInterval(:,1) - m.Force);

w = 1./(m.ForceError);
w = w ./ max(w);
m.Weights = w;

m = struct2table(m);

return

function outs = get_startpos(x,y)
    outs{1,1} = x(1);
    outs{1,2} = y(1);
return

% function outs = mylinfit(t,z,order)
%     mb = polyfit(t,z,order);
%     outs{1,1} = t(1);
%     outs{1,2} = mean(t);
%     outs{1,3} = mb;
% return

function outs = mylinfit(t,z,order)

    myfit = fit(t,z,'poly1');
    cf = transpose(confint(myfit));
    
%     mb = polyfit(t,z,order);
    outs{1,1} = t(1);
    outs{1,2} = mean(t);
    outs{1,3} = myfit.p1;
    outs{1,4} = cf(1,:);
    
return
