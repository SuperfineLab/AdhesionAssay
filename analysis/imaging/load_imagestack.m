function [stack, xy, metaT] = load_imagestack()
addpath(genpath('D:\jcribb\src\bfmatlab'));

filelist = dir('Well 15 Individual Images_redo_*.vsi');
stack = cell(length(filelist),2);


for k = 1:length(filelist)
%     reader = bfGetReader(filelist(k).name);
%     omeMeta = reader.getMetadataStore();
%     bfGetPlane(reader,1)
%     foo = bfGetPlane(reader,1);
%     figure; imagesc(foo);


    file = bfopen(filelist(k).name);
    tmp = file{1,1};
    stack{k,1} = tmp{1,1};
    stack{k,2} = tmp{1,2};
    meta = file{1,2};
    metadataKeys = meta.keySet().iterator();
    for i=1:meta.size()
        metakey{1,i} = metadataKeys.nextElement(); %#ok<AGROW> 
        metavalue{k,i} = meta.get(metakey{1,i}); %#ok<AGROW> 
%         fprintf('%s = %s\n', metakey{1,i}, metavalue{k,i});
    end

end
% gostr = cellfun(@(s)contains(s, 'Global Origin'), metakey);
q(:,1) = metavalue( :, matches(metakey, 'Global Origin'));

N = size(q,1);
xy = NaN(N,2);
for idx = 1:N
    tmp = q{idx,1};
    r = regexp(tmp, '\((\d*\.\d*), (\d*\.\d*)\)', 'tokens');
    r = r{1};
    xy(idx,1) = str2double(r{1,1}); 
    xy(idx,2) = str2double(r{1,2});
end

x = xy(:,1);
y = xy(:,2);

dxy = abs(diff(xy,1,1));
dxy = sort(floor(dxy), 1);

dx = dxy(:,1);
[a,b] = groupcounts(dx( dx > 0, 1));
imstepx = b(a == max(a));

dy = dxy(:,2);
[a,b] = groupcounts(dy( dy > 0, 1));
imstepy = b(a == max(a));

xlocs = floor(x / imstepx);
ylocs = floor(y / imstepy);

xlocf = stagepos2mosaicloc(xy(:,1));
ylocf = stagepos2mosaicloc(xy(:,2));

end

function locs = stagepos2mosaicloc(pos)
    dpos = abs(diff(pos));
    dpos = sort(floor(dpos), 1);
    
    [a,b] = groupcounts(dpos( dpos > 0, 1));
    imstep = b(a == max(a));
    
    locs = floor(pos / imstep);
end