function ba_livehist(obj,event,hImage)
% BA_LIVEHIST is a callback function for ba_impreview.
%

% persistent q f myhist mypreview

% Establish all the controls on the UI. Pull out the preview window and the
% image histogram
% a = ancestor(hImage, 'axes');
% if ~contains(class(f), 'matlab.ui.Figure')
%     f = a.Parent;
%     sibs = f.Children;    
%     for k = 1:length(sibs)
%         mytag = sibs(k).Tag;        
%         switch mytag
%             case 'Live Image'
%                 mypreview = sibs(k);
%                 fprintf('Class for "f" changed. Preview sibling is %i.\n', k);
%             case 'Image Histogram'
%                 myhist = sibs(k);
%                 fprintf('Class for "f" changed. Histogram sibling is %i.\n', k);
%         end
%     end
% end

im = event.Data;

hwhandle = getappdata(hImage, 'hwhandle');
viewOps = getappdata(hImage, 'viewOps');
ghandles = getappdata(hImage, 'ghandles');

mypreview = ghandles.preview;
myhist = ghandles.histogram;


%mypreview
% Display the current image frame. Modify the min and max scale to reflect 
% the actual limits of the data returned by the camera. For example,
% the limit a 16-bit camera would be [0 65535].
% cmin = min(double(hImage.CData(:)));
% cmax = max(double(hImage.CData(:)));
cmin = min(double(im(:)));
cmax = max(double(im(:)));
% cmin = 4000;
% cmax = 12000;
if cmin == cmax
    cmin = cmax - 1;
end
% fprintf('Cmin = %i, Cmax = %i. \n', cmin, cmax);
set(mypreview, 'CLim', [uint16(cmin) uint16(cmax)]);
% set(a, 'CLim', [0 65535]);


hImage.CData = im;
% Manage the histogram
set(myhist, 'Units', 'normalized');
set(myhist, 'Position', [0.28, 0.05, 0.4, 0.17]);


D = double(im(:));

avgD = num2str(round(mean(D)), '%u');
stdD = num2str(round(std(D)), '%u');
maxD = num2str(max(D), '%u');
minD = num2str(min(D), '%u');

% q=0; assignin('base', 'focus_measure', q);

% Plot the histogram. Choose less bins for faster update of the display.
axis(ghandles.histogram);
switch class(im)
    case 'uint8'
        imhist(im, 128);
        xlim([0 260]);        
    case 'uint16'        
        imhist(im, 32768);        
        xlim([0 66000]);
end
set(gca,'YScale','log')

image_str = [avgD, ' \pm ', stdD, ' [', minD ', ', maxD, ']'];

if viewOps.focusTF
    focus_score = fmeasure(im, 'GDER');
    % q = [q focus_score];
    focus_str = [', focus score= ', num2str(focus_score)];
else
    focus_str = '';
end

%if isa(hwhandle.zhand, 'COM.MGMOTOR_MGMotorCtrl_1')
%    zpos_str = [', z = ' num2str(tm_getz(hwhandle.zhand)) ' [mm]'];
%else 
%    zpos_str = '';
%end

title([image_str, focus_str]);%, zpos_str]);

% Refresh the display.
drawnow

return
