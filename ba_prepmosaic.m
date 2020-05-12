function [x,y] = ba_prepmosaic(ludl, plate, wellrc)

    centers = plate.calib.centers;
    
    plate_space_move(ludl, centers, wellrc);
    Center = stage_get_pos_Ludl(ludl);
    Xlocs = [Center.Pos(1)-42000 : 6840 : Center.Pos(1)+42000];
    Ylocs = [Center.Pos(2)+42000 : -8640 : Center.Pos(2)-42000]';
    Xmat = repmat(Xlocs, size(Ylocs,1), 1);
    Ymat = repmat(Ylocs, 1, size(Xlocs,2));
    x = Xmat(:);
    y = Ymat(:);

return