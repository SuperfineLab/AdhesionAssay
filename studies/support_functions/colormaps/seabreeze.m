function outs = seabreeze(cnum)
    cbmap = ... [255,255,255;
             [240,249,232; 
             186,228,188; 
             123,204,196; 
             67,162,202; 
             8,104,172];
    outs = interpcmap(cbmap, cnum);
end
