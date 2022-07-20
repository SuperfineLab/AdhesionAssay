% well = 1:15; 
% 
% exptime_4x = repmat([50 50 50 200 200], 1, 3);
% exptime_10x = repmat([15 15 15 50 50], 1, 3);
% 
% calib_4x_2048x1536 = 0.858;
% calibum_10x_2048x1536 = 0.346;
calibum_10x_1024x768 = 0.692; % [um/pixel]

% well = [1 6 11];
% exptime_10x = [100 100 100];


well = [1:15];
% well = 1;
exptime_10x = 50 * ones(size(well));

exptime = exptime_10x;
calibum = calibum_10x_1024x768;

if ~exist('hw', 'var')
    hw.scope = scope_open('COM2');
    hw.zhand = tm_initz('Artemis');
    hw.ludl = stage_open_Ludl('COM6');
end

% collecting images at 4x

for k = 1:length(well)
    
%     viewOps.CameraFormat = 'F7_Raw16_2048x1536_Mode7';
    viewOps.CameraFormat = 'F7_Raw16_1024x768_Mode2';
    viewOps.exptime = exptime(k);
    viewOps.focusTF = false;
    viewOps.man_cmin = true;
    viewOps.man_cmax = true;
    viewOps.cmin = 3000;
    viewOps.cmax = 15000;
    
    plate_space_move(hw.ludl, Plate.calib, well(k))
    
%     current_focus = scope_get_focus(hw.scope);
%     best_focus = ba_findfocus(hw.scope, [current_focus - 4200, current_focus + 4200], 400, exptime(k));
%     scope_set_focus(hw.scope, best_focus);
    
    ui = ba_impreview(hw, viewOps);
    logentry('Focus the image, then press a key.');
    pause;
    close(ui);

    fname = ['well-' num2str(well(k), '%02i') '_10x_' num2str(exptime(k)) 'ms'];
    disp(fname);
    
    m = ba_grabwellmosaic(hw.ludl, Plate.calib, well(k), exptime(k), fname);
    im = imtile(m.Image, 'GridSize', [13 13]); 
    
    figure(k);
    imagesc(im); 
    colormap(gray); 
    ax = gca; 
%     ax.CLim = [0 65000];    

end



