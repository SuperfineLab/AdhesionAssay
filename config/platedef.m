function plate = platedef(platelayout)

plate.name = platelayout;

switch platelayout
        case '15v1' 
            plate.length_mm = 69.6;
            plate.width_mm = 44.476;
            plate.well_one_center = [7.2 10.9];
            plate.interwell_dist = [16.2, 11.79];
        case '15v2'
            plate.length_mm = 57.96;
            plate.width_mm = 43.2;
            plate.well_one_center = [5.4, 5.4];
%             plate.interwell_dist  = [16.2, 11.79];
            plate.interwell_dist  = [11.79, 16.2];
        case 'nunc-96' % nunc spec.
            error('nunc-96 is not yet defined.');
%         plate.well_one_center = [14.32 11.25];
    otherwise 
        error('This plate definition is not found. Add specs to platedef.m');
    end