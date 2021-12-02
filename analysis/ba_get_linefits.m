function m = ba_get_linefits(evtfile, calibum, visc_Pas, bead_diameter_um, Fid)
% BA_GET_LINEFITS calculates bead velocity and force from displacement line fits.
%

d = load_evtfile(evtfile);

if isempty(d)
    m = table('Size', [0 8], ...
              'VariableTypes', {'double', 'double', 'string', 'double', ...
                                'double', 'double', 'double', 'double'},...
              'VariableNames', {'Fid', 'Filename', 'SpotID', 'StartPosition', ...
                                'Pulloff_time', 'Mean_time', 'Mean_vel', 'Force'});
    return
else 
    t = d.Frame ./ d.Fps;
    [g, ID] = findgroups(d.ID);
end

myfits = splitapply(@(x,y)mylinfit(x,y,1), t, d.Z, g);
sp = splitapply(@(x,y)get_startpos(x,y), d.X, d.Y, g);

mb = cell2mat(myfits(:,3));

m.Fid = repmat(Fid, size(myfits,1), 1);
m.Filename = repmat(string(evtfile), size(myfits,1), 1);
m.SpotID = ID;
m.StartPosition = cell2mat(sp);
m.Pulloff_time = cell2mat(myfits(:,1));
m.Mean_time = cell2mat(myfits(:,2));
m.Mean_vel = mb(:,1) * calibum * 1e-6;
m.Force = 6 * pi * visc_Pas * bead_diameter_um/2 * 1e-6 * m.Mean_vel;

m = struct2table(m);

return

function outs = get_startpos(x,y)
    outs{1,1} = x(1);
    outs{1,2} = y(1);
return

function outs = mylinfit(t,z,order)
    mb = polyfit(t,z,order);
    outs{1,1} = t(1);
    outs{1,2} = mean(t);
    outs{1,3} = mb;
return
