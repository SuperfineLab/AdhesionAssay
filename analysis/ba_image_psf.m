function ba_image_psf(stim, gaussSD, isovalue)


figure;
stFilt = imgaussfilt3(stim,gaussSD);
stFilt = double(stFilt);
stFilt = stFilt ./ max(stFilt(:));
p = patch(isosurface(stFilt,isovalue));
isonormals(stFilt,p);
p.FaceColor = 'red';
p.EdgeColor = 'none';
daspect(1./[0.692 0.692 5])
axis tight
camlight
lighting gouraud