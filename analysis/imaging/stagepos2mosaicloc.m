function rclocs = stagepos2mosaicloc(stagexy)

    xlocs = convert2mosaic(stagexy(:,1));
    ylocs = convert2mosaic(stagexy(:,2));
    
    rclocs = [ylocs xlocs];

end


function locs = convert2mosaic(pos)

    pos = pos - min(pos);

    dpos = abs(diff(pos));
    dpos = sort(floor(dpos), 1);
    
    [a,b] = groupcounts(dpos( dpos > 0, 1));
    imstep = b(a == max(a));
    
%     locs = floor(pos / imstep) + 1;
    locs = round(pos / imstep, 0) + 1;
end


