function outs = interpcmap(map, cnum)
    map = map ./ 255;
    sampleN = size(map,1);
    xnew = linspace(1,sampleN,cnum);

    outs = interp1(map, xnew);
    outs(1,:) = [1,1,1];
end