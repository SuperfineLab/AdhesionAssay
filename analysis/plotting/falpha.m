function alphaout = falpha(relwidth)

    relwidth = relwidth(:);

    alphaout = NaN(size(relwidth));

    alphaout(relwidth < 1) = 1;
    alphaout(relwidth > 10) = 0.1;
    alphaout(relwidth > 100) = 0;
    
    % everywhere else needs mapping
    alphafunc = @(w)(-0.089.*w + 0.9889);
    idx = relwidth >= 1 & relwidth <= 10;
    alphaout(idx) = alphafunc(relwidth(idx));
           
end