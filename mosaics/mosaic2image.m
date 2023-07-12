function imout = mosaic2image(mosaicmat, outfile)

if nargin == 2

    switch mosaicmat
        case ischar(mosaicmat)
            fname = dir(mosaicmat);
   
            if isempty(fname)
                error('file not found');
            end

            m = load(fname.name);

        case isnumeric(mosaicmat)
            m = mosaicmat;
        otherwise
            error('Something is wrong.')
    end
     
    m = m.mosaic;
    im = imtile(m.Image, 'GridSize', [13 13]); 
    imwrite(im, [fname '.tif'], 'tif');
    im = im(3500:7500, 4000:10000);  
    q(:,:,k) = im;
    sumIntensity(k,1) = sum(im(:));
    myscale = 0.25;
    im = imresize(im, myscale);
    [height, width] = size(im);
    X_mm = [1:width]  * calibum/1000 / myscale;
    Y_mm = [1:height] * calibum/1000 / myscale;