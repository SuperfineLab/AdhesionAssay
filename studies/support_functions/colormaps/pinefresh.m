function outs = pinefresh(cnum)
%   Functions: Custom Colormaps (schema came from colorbrewer)
    cbmap = ... [255,255,255;
             [255,255,204; 
             194,230,153;
             120,198,121;
             49,163,84;
             0,104,55];
    outs = interpcmap(cbmap, cnum);
end






