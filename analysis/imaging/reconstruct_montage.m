function s = reconstruct_montage(cellstack, rclocs)

    for k = 1:size(rclocs,1) 
        im = cellstack{k};        
        s{rclocs(k,1), rclocs(k,2)} = im; 
    end

    s = cell2mat(s);

end