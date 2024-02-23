function outs = doldrums(cnum)
    outs = gray(cnum);
    outs(:,2) = 0;
    outs(:,3) = flipud(outs(:,1));
    outs(1,:) = 1;
end
