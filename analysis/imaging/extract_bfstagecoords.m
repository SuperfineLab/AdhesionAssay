function xy = extract_bfstagecoords(stackmeta)
% gostr = cellfun(@(s)contains(s, 'Global Origin'), metakey);

    q(:,1) = stackmeta.value(matches(stackmeta.key, 'Global Origin'), :);
    
    N = size(q,1);
    xy = NaN(N,2);
    for idx = 1:N
        tmp = q{idx,1};
        r = regexp(tmp, '\((\d*\.\d*), (\d*\.\d*)\)', 'tokens');
        r = r{1};
        xy(idx,1) = str2double(r{1,1}); 
        xy(idx,2) = str2double(r{1,2});
    end
end
