function imxy = wellpolar2mosaicxy(im, wellrphi, calibum)

r_mm = wellrphi(:,1);
r_px = r_mm * 1000 / calibum;

phi = wellrphi(:,2);


[xo,yo] = pol2cart(phi, r_px);


imcenter_xy = fliplr(size(im))./2;

imxy = imcenter_xy + [xo,-yo];

return

