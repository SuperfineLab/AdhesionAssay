function outs = catcells(x)
    if iscell(x)
        outs = cat(1,x{:});
    elseif isnumeric(x)
        outs = x;
    end
end