function plate = platedef(platelayout)

switch platelayout
        case '15v1' % nunc spec.
    %         plate.well_one_center = [14.32 11.25];
            plate.length_mm = 69.6;
            plate.width_mm = 44.476;
            plate.well_one_center = [7.2 10.9];
            plate.interwell_dist = [16.2, 11.79];
        case '15v2'
            plate.length_mm = 57.96;
            plate.width_mm = 43.2;
            plate.well_one_center = [5.4, 5.4];
            plate.interwell_dist  = [16.2, 11.79];
    end