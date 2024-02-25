function outs = OrganizeSurfaceData(sz, VisRow, VisCol, data)
% Organizes data from a table into the appropriate 2D heatmap. Matlabe
% probably has a snazzier way to do this, so this may be superfluous.
% 
% XXX TODO: Look into using Matlab's HEATMAP function to replace this
%


%     myidx = sub2ind(sz, VisRow, VisCol);
% 
%     outs = NaN(sz);
%     outs(myidx) = data(myidx);
    R = max(VisRow);
    C = max(VisCol);
    cmat = zeros(R, C);
    
    for k = 1:R
        for m = 1:C
            try
                cmat(k,m) = data(VisRow == k & VisCol == m);
            catch
                cmat(k,m) = NaN;
            end
        end
    end
    
    outs = cmat;
end
