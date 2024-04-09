function outs = compare_before_after_mosaics(before, after, hw, Plate, mytitle)

calibum = 0.858;
subplot = @(m,n,p) subtightplot(m, n, p, [0.01 0.005], [0.1 0.01], [0.1 0.01]);

% [height, width] = size(im);
height = 8 * 1536;
width = 6 * 2048;
X_mm = [1:width]  * calibum/1000;
Y_mm = [1:height] * calibum/1000;

bins = [0:200:7000];

g = findgroups(before.Well);

foo = splitapply(@(x){sa_delaunay_table(x)}, before.Centers, g);

% Dbefore = cellfun(@create_delaunay_table, before.centers, 'UniformOutput',false);
% Dafter = cellfun(@create_delaunay_table, after.centers, 'UniformOutput',false);

% maxbefore = cell2num(cellfun(@(m)max(m,[],'all'), Dbefore.Area, 'UniformOutput',false));
% maxafter = cell2num(cellfun(@(m)max(m,[],'all'), after.centers, 'UniformOutput',false));
% mmax = max([maxbefore(:)' maxafter(:)'], [], 'all');

f = figure; 
% g = figure; 
h = figure; 
% BeforePatchfig = figure; 
% AfterPatchfig = figure;

for k = 1 : 15

    idxb = find(before.Well == k);
    idxa = find(after.Well == k);

    mybefore = before.Centers(idxb,:);
    myafter = after.Centers(idxa,:);
    Nbefore(k,1) = size(mybefore, 1);
    Nafter(k,1) = size(myafter, 1);

    magnetpos = Plate.fov(k).Pos;
    [wellnum, xyoffset_mm] = plate2well(hw.ludl, Plate.calib, magnetpos);
    imagecenterxy_mm = [max(X_mm)/2, max(Y_mm)/2];
    magnetdrop_mm = imagecenterxy_mm + xyoffset_mm;
    magnetdrop_px = (magnetdrop_mm * 1000) / calibum;

    distmbefore = sqrt(sum((mybefore - repmat(magnetdrop_px,Nbefore(k),1)) .^ 2,2));
    distmafter = sqrt(sum((myafter - repmat(magnetdrop_px,Nafter(k),1)) .^ 2,2));
    
    hbefore(:,k) = histcounts(distmbefore, bins);
    hafter(:,k) = histcounts(distmafter, bins);

        figure(f);
        subplot(3,5,k);
        plot(bins(1:end-1)*calibum/1000, hbefore(:,k));
        hold on;
        plot(bins(1:end-1)*calibum/1000, hafter(:,k));
        hold off;
        if k==1, legend('before', 'after'); end
        f.Name = [mytitle, ', N beads removed by distance, mm'];
        ylim([0 50]);
        xlim([0 6.5]);
        fax = gca;
        fax.XTick = [1:6];
        if any(k == [1,6,11])            
            ylabel('bead count');
        end

        if any(k == 11:15)
            xlabel('mm from poletip');
        end
%         figure(g);
%         subplot(3,5,k);
%         plot(bins(1:end-1)*calibum/1000, hbefore-hafter);
%         g.Name = 'N beads removed, before-after';
%         ylim([0 50]);
        
        figure(h);
        subplot(3,5,k);[mytitle, ', N beads removed by distance, mm'];
        h.Name = [mytitle, ', bead removal fraction 1-(after/before)'];
        plot(bins(1:end-1)*calibum/1000, 1-(hafter(:,k)./hbefore(:,k)));
        ylim([0 1.1]);        
        xlim([0 6.5]);
        fax = gca;
        fax.XTick = [1:6];
        if any(k == [1,6,11])            
            ylabel('removal fraction');
        end

        if any(k == 11:15)
            xlabel('mm from poletip');
        end
    cmap = hot(65535);
%         D = table(DelaunayVertLocs, Xvertices, Yvertices, Area, ...
%         'VariableNames', {'DelaunayVertLocs', 'Xvertices', 'Yvertices', 'Area'});

    Dafter = create_delaunay_table(after.Centers(idxa,:));
%     plot_patches(Dafter, AfterPatchfig, k);
    
    % CustomNormValue = max(Dafter.Area,[],'all');
    
    Dbefore = create_delaunay_table(before.Centers(idxb,:));
%     plot_patches(Dbefore,BeforePatchfig, k);

end

outs.bins(:,1) = bins(1:end-1);
outs.histbefore = hbefore;
outs.histafter = hafter;
outs.removalfraction = 1-(hafter./hbefore);

return




function D = create_delaunay_table(XYcenters)

    x = XYcenters(:,1); 
    y = XYcenters(:,2);       

    DelaunayVertLocs = delaunay(x, y);
    Xvertices = reshape(x(DelaunayVertLocs,1),size(DelaunayVertLocs));
    Yvertices = reshape(y(DelaunayVertLocs,1),size(DelaunayVertLocs));
    Area = triarea(DelaunayVertLocs, XYcenters);

    D = table(DelaunayVertLocs, Xvertices, Yvertices, Area, ...
        'VariableNames', {'DelaunayVertLocs', 'Xvertices', 'Yvertices', 'Area'});
   
return

function outs = sa_delaunay_table(XYcenters)

    x = XYcenters(:,1); 
    y = XYcenters(:,2);       

    DelaunayVertLocs = delaunay(x, y);
    Xvertices = reshape(x(DelaunayVertLocs,1),size(DelaunayVertLocs));
    Yvertices = reshape(y(DelaunayVertLocs,1),size(DelaunayVertLocs));
    Area = triarea(DelaunayVertLocs, XYcenters);

    outs = [DelaunayVertLocs, Xvertices, Yvertices, Area];
return

% (...cmap, CustomNormValue)
%     cmapN = size(cmap,1);
%     flipcmap = flipud(cmap);
%     NormValue = max(D.Area,[],'all');
%     if exist('CustomNormValue', 'var') && ~isempty(CustomNormValue)
%         NormValue = CustomNormValue;
%     end
%    
% 
%     D.AreaNorm = floor(D.Area * (cmapN-1) / NormValue)+1;
%     D.PatchColor = flipcmap(D.AreaNorm,:);


function outs = plot_patches(D,h,k)
    if nargin < 2 || isempty(h)
        h = figure;
    end
    
    [r,c] = size(D.PatchColor); 
    patchColor = reshape(D.PatchColor,r,1,c);
    
    Xt = transpose(reshape(D.x(D.DelaunayVertLocs,1),size(D.DelaunayVertLocs)));
    Yt = transpose(reshape(D.y(D.DelaunayVertLocs,1),size(D.DelaunayVertLocs)));
    
        figure(h);
        subplot(3,5,k);
        htri = triplot(D.DelaunayVertLocs, D.x, D.y, '');
        htri.LineStyle = 'none';
        patch(Xt,Yt,patchColor);
        axis image
        xlim([1 12288]);
        ylim([1 12288]);
        axis off;
    
    outs = 0;

return