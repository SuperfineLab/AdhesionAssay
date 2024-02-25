function outs = candycane(cnum)
    cbmap = ... [255,255,255;
             [241,238,246;
             215,181,216;
             223,101,176;
             221,28,119;
             152,0,67];
%     cbmap = [255,255,255;
%              255,0,0];
     outs = interpcmap(cbmap, cnum);     
end
