function cal = ba_calibrate_plate(ludl, platelayout)
% BA_CALIBRATE_PLATE uses the fiducial marking images taken by the camera and the
% location of the stage in ludl coordinates at that location to calculate
% the location of the sample on the ludl stage

if nargin < 2 || isempty(platelayout)
    platelayout = '15v2';
end

plate = platedef(platelayout);

cameraname = 'Grasshopper3';
switch lower(cameraname)
    case 'grasshopper3'
        imSpec.Width = 1024;
        imSpec.Height = 768;
        imSpec.SE_radius = 22;
    case 'dragonfly2'
        imSpec.Width = 648;
        imSpec.Height = 488;
        imSpec.SE_radius = 14;        
end

plate.length_ticks = mm2tick(ludl, plate.length_mm);
plate.width_ticks = mm2tick(ludl, plate.width_mm);

% check for open impreview window
h = findobj('Name', 'vid_impreview');
if ~isempty(h)
    logentry('Found open preview window. Closing.')
    close(h);
    pause(0.1);
end


% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.
[pos, imstack] = fiducial_position_array(ludl, plate, imSpec);

% Finds the ludl coordinates that would place the fiducial center in the
% center of the image
[x,y] = image_center_find(imstack, pos, imSpec);
cal.centers(:,1) = x;
cal.centers(:,2) = y;


cal.theta = calculate_tilt_angle(cal);

cal.errormatrix = calculate_error_matrix(cal, plate);

% If we had a preview, restore it once we're done collecting data
% if ~isempty(h)
%     ba_impreview(hw, viewOps);
% end

return


function [FidLudlLocs, imstack] = fiducial_position_array(ludl, plate, imSpec)
% FIDUCIAL_POSITION_ARRAY opens a viewing window for the user to manually
% locate the fiducial marks, then stores the images and the positions in 
% ludl coordinates at which each image was taken.

    
    plate.length_ticks = mm2tick(ludl, plate.length_mm);
    plate.width_ticks = mm2tick(ludl, plate.width_mm);

    % WARNING: Adjust the size of imstack according to image size!
    imstack = zeros(imSpec.Height, imSpec.Width, 4);

    FiducialOffsets = [                  0,                   0 ; ...
                                         0, -plate.length_ticks ; ...
                        -plate.width_ticks, -plate.length_ticks ; ...
                        -plate.width_ticks,                   0 ];
    FidLudlLocs = zeros(4,2);



    % Get positions and images for each fiducial mark after 'Enter' is hit
    disp('Starting...')

    % preview(vid);
    f = ba_impreview;

    for k = 1:size(FiducialOffsets,1)

        disp(strcat('Locate Point #',num2str(k))) 

        if k == 1
            pause;
        else
            stage_move_Ludl(ludl, FidLudlLocs(1,:) + FiducialOffsets(k,:));
            pause;
        end

    %     frame = getsnapshot(vid);

        % This uses the ba_impreview function and relies on knowing the EXACT
        % configuration of the ba_impreview figure. The code should be changed
        % to something way more robust than this.
        sibs = f.Children;    
        for m = 1:length(sibs)
            mytag = sibs(m).Tag;        
            switch mytag
                case 'Live Image'
                    ax = sibs(m);
                case 'Image Histogram'

            end
        end

        frame = ax.Children.CData;

    %     imwrite(frame,strcat('im',num2str(k),'.tif'));
        imstack(:,:,k) = frame;
        ludl = stage_get_pos_Ludl(ludl);
        FidLudlLocs(k,:) = ludl.Pos;
    end

    % closepreview(vid);
    close(f);

    % Convert points into uint8
    switch class(frame)
        case 'uint8'
            imstack = uint8(imstack);
        case 'uint16'
            imstack = uint16(imstack);
    end

return


function [x_center, y_center, x_disp, y_disp] = image_center_find(imstack, xypos, imSpec)
% IMAGE_CENTER_FIND locates the center of each fiducial mark and determines 
% the ludl coordinates that the stage would need to be in such that the 
% center of each fiducial mark would be at the center of the image

    % Define structuring element
    SE = strel('disk', imSpec.SE_radius);
    factor = 45;

    Nframes = size(imstack,3);
    x_center = NaN(Nframes,1); y_center = NaN(Nframes,1); 
    for k = 1:Nframes
        
        % Binarize and erode/dilate image
        test = imstack(:,:,k);
        test = imbinarize(test);

        if sum(test(:)) > 1/2 * (imSpec.Width * imSpec.Height)       
            test = imcomplement(test); 
        end

        test = imdilate(test,SE); 
        test = imerode(test,SE); 

        % (10:end-10,10:end-10)
        % Find/plot center of mass
        [x, y] = centerofmass(test);

        % Find pixel displacement from center and convert to ticks
        % x_disp = (635/2 - x) * -factor;
        % y_disp = (470/2 - y) * factor;

        x_disp = (imSpec.Width/2 - x) * -factor;
        y_disp = (imSpec.Height/2 - y) * factor;

        % Find coordinates for the center of the fiducial markings in ludl
        % coordinates
        x_center(k,1) = xypos(k,1) + x_disp;
        y_center(k,1) = xypos(k,2) + y_disp;

%         % Debug plot (comment out later)
%         figure; 
%         imshow(test)
%         hold on
%             plot(x, y, 'or');
%             plot(x_center, y_center, 'xg');   
%         hold off
%         legend('center of mass', 'center of field');
    end

return


function theta = calculate_tilt_angle(cal)
    % Find the angle of tilt in radians
    Ftop_leftXY = cal.centers(1,:);
    Ftop_rightXY = cal.centers(2,:);
    Fbottom_rightXY = cal.centers(3,:);
    Fbottom_leftXY = cal.centers(4,:);

    theta = atan(abs(Ftop_rightXY(1) - Ftop_leftXY(1))/abs(Ftop_rightXY(2) - Ftop_leftXY(2)));
return


function errormatrix = calculate_error_matrix(cal, plate)
    
    Ftop_leftXY = cal.centers(1,:);
    Ftop_rightXY = cal.centers(2,:);
    Fbottom_rightXY = cal.centers(3,:);
    Fbottom_leftXY = cal.centers(4,:);

    cal.theta = atan(abs(Ftop_rightXY(1) - Ftop_leftXY(1))/abs(Ftop_rightXY(2) - Ftop_leftXY(2)));

    % Create error matrix of side lengths, order sides as NSEW, with top length as "North"
    errormatrix = zeros(4,2);

    % Finds error in tick marks (col 1)
    errormatrix(1,1) = pdist([Ftop_leftXY;Ftop_rightXY]) - plate.length_ticks;
    errormatrix(2,1) = pdist([Fbottom_rightXY;Fbottom_leftXY]) - plate.length_ticks;
    errormatrix(3,1) = pdist([Ftop_rightXY;Fbottom_rightXY]) - plate.width_ticks;
    errormatrix(4,1) = pdist([Ftop_leftXY;Fbottom_leftXY]) - plate.width_ticks;

    % Finds percent error (col 2)
    errormatrix(1,2) = errormatrix(1,1)/plate.length_ticks * 100;
    errormatrix(2,2) = errormatrix(2,1)/plate.length_ticks * 100;
    errormatrix(3,2) = errormatrix(3,1)/plate.width_ticks * 100;
    errormatrix(4,2) = errormatrix(4,1)/plate.width_ticks * 100;

return

