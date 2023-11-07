% well = 1:15; 
% 
% exptime_4x = repmat([50 50 50 200 200], 1, 3);
% exptime_10x = repmat([15 15 15 50 50], 1, 3);
% 
calibum_4x_2048x1536 = 0.858;
calibum_10x_2048x1536 = 0.346;
calibum_10x_1024x768 = 0.692; % [um/pixel]

% well = [1 6 11];
exptime_10x = 8;
exptime_4x = 20;


% well = [1:15];
% exptime = exptime_10x * ones(size(well));;
% calibum = calibum_10x_1024x768;


well = [1:15];
exptime = exptime_4x * ones(size(well));
calibum = calibum_4x_2048x1536;

if ~exist('hw', 'var')
    hw.zhand = tm_initz('Artemis');
    hw.scope = scope_open('COM2');
    hw.ludl = stage_open_Ludl('COM4');
end

% collecting images at 4x
f = figure;
for k = 1:length(well)
    
%     viewOps.CameraFormat = 'F7_Raw16_2048x1536_Mode7';
    viewOps.CameraFormat = 'F7_Raw16_1024x768_Mode2';
    viewOps.exptime = exptime(k);
    viewOps.gain = 15;
    viewOps.focusTF = false;
    viewOps.man_cmin = true;
    viewOps.man_cmax = true;
    viewOps.cmin = 4500;
    viewOps.cmax = 50000;
    
    plate_space_move(hw.ludl, Plate.calib, well(k))
        

% if isfield(Plate, 'focus') && numel(Plate.focus) >= k
%     logentry(['Setting focus to: ' num2str(Plate.focus(k))]);
%     pause(2);
%     scope_set_focus(hw.scope, Plate.focus(k));    
%     logentry(['Focus set to: ' num2str(scope_get_focus(hw.scope))]);
%     pause(2);
% else
    ui = ba_impreview(hw, viewOps);
% % % %     current_focus = scope_get_focus(hw.scope);
% % % %     best_focus = ba_findfocus(hw.scope, [current_focus - 4200, current_focus + 4200], 400, exptime(k));
% % % %     scope_set_focus(hw.scope, best_focus);
    logentry('Focus the image, then press a key.');
    pause;
    close(ui);
% end
    
    

    fname = ['well-' num2str(well(k), '%02i') '_10x_' num2str(exptime(k)) 'ms'];
    disp(fname);
    
    myscale = 0.25;
%     m = ba_grabwellmosaic(hw.ludl, Plate.calib, well(k), exptime(k), 'normal', fname);
    m = ba_grabwellmosaic(hw.ludl, Plate.calib, well(k), exptime(k), 'oxplow', fname);
    m = sortrows(m, {'RowID', 'ColumnID'}, {'ascend','ascend'});
%     im = imtile(m.Image, 'GridSize', [13 13]); 
    im = imtile(m.Image, 'GridSize', [8 6]); 
    im = imresize(im, myscale, 'bicubic');

    figure(f);
    subplot(3,5,well(k));
    imagesc(im); 
    axis image;
    colormap(gray); 
    ax = gca; 
    ax.CLim = [4500 60000];    

end



