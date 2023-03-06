function h = ba_plot_zmotorhist(ZmotorPos, edges, mytitle)

if nargin < 2 || isempty(edges)
    edges = [-0.1:0.1:3];    
end

h = figure; 
histogram(ZmotorPos, edges);
title(mytitle)
xlabel('Z-motor distance above substrate [mm]');
ylabel('count');