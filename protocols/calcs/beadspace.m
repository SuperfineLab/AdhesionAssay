function FOV = beadspace(BeadSoln, FOVwidthheight, calibum)

FOV.width = FOVwidthheight(1);
FOV.height = FOVwidthheight(2);
FOV.calibum = calibum;
FOV.width_um = FOV.width * FOV.calibum;
FOV.height_um = FOV.height * FOV.calibum;
FOV.area_um2 = FOV.width_um .* FOV.height_um;

FOV.Nbeads = prod(FOVwidthheight ./ BeadSoln.meanfreepath_um);



