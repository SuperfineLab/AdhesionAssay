function [stack, metaout] = load_bfstack(filemask)
addpath(genpath('D:\jcribb\src\bfmatlab'));

filelist = dir(filemask);
stack = struct;


for k = 1:length(filelist)
%     reader = bfGetReader(filelist(k).name);
%     omeMeta = reader.getMetadataStore();
%     bfGetPlane(reader,1)
%     foo = bfGetPlane(reader,1);
%     figure; imagesc(foo);

    fname = filelist(k).name;
    file = bfopen(fname);
    tmp = file{1,1};
    stack(k).RawImage = tmp{1,1};
    stack(k).MetaTag = tmp{1,2};
    meta = file{1,2};
    metadataKeys = meta.keySet().iterator();
    for i = 1:meta.size()
        metaout.key{i,1} = metadataKeys.nextElement(); %#ok<AGROW> 
        metaout.frame(1,k) = k;
        metaout.value{i,k} = meta.get(metaout.key{i,1}); %#ok<AGROW> 
    end
   
end

    stack = struct2table(stack); 
    
    stack.ImageIndex = cellfun(@indexfun,stack.MetaTag);
    stack.Well = cellfun(@wellfun,stack.MetaTag); 

end


function idxout = indexfun(mystring)
    r = regexpi(mystring, '_(\d*).vsi', 'tokens');
    r = r{1};
    idxout = str2double(r{1});
end

function wellidx = wellfun(mystring)
    r = regexpi(mystring, 'well(\d*)', 'tokens');
    if ~isempty(r)
        r = r{1};
    else
        r = '';
    end
    wellidx = str2double(r);
end

