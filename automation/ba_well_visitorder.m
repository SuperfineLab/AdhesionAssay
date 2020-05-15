function vo = ba_well_visitorder(Plate, sampling)
% BA_WELL_VISITORDER outputs the order in which to visit wells in the Adhesion Assay
%
% vo = ba_well_visitorder(platedef, sampling)
%
%
% Inputs:
% Outputs: 

if nargin < 2 || isempty(sampling)
    sampling = 'sorted';
end


    vidx = ~cellfun('isempty', Plate.Layout.Value);
    well_list = unique(Plate.Layout.Well_ID(vidx));
    N = length(well_list);
    
    switch sampling
        case 'sorted'
            vo = sort(well_list);
        case 'random'
            new_order = randsample(N, N);
            vo = well_list(new_order);
        otherwise
            error('Sampling order not recognized.');
    end
    
    
    