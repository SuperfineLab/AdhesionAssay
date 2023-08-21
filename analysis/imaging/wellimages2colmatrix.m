function outs = wellimages2colmatrix(WellsCell)
qcell(1,:) = cellfun(@(x)(reshape(x,[],1)), WellsCell, 'UniformOutput', false);
maxL = max(cell2mat(cellfun(@(x)size(x,1),qcell,'UniformOutput',false)));

q = NaN(maxL,15);
for k = 1:length(qcell)
    q(1:numel(qcell{k}),k) = qcell{k}; 
end

outs = q;
