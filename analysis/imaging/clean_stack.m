clear s stack cim

addpath(genpath('K:\expts\AdhesionAssay\staining mucus-coated glass\mucusglass_code'))

darkfiles = dir('K:\expts\AdhesionAssay\staining mucus-coated glass\2023.04.13__Pro-Q488_glycoproteindye_15well_HillLabOrca\ORCA camera Controls\videos\shutter_closed_stack\*.tif');
shadefiles = dir('K:\expts\AdhesionAssay\staining mucus-coated glass\2023.04.13__Pro-Q488_glycoproteindye_15well_HillLabOrca\ORCA camera Controls\videos\blank_slide_stack\*.tif');

dark_image = load_dark_images(darkfiles);
shade_image = load_shade_images(shadefiles);

dirlist = { 'K:\expts\AdhesionAssay\staining mucus-coated glass\2023.04.13__Pro-Q488_glycoproteindye_15well_HillLabOrca\Booger\well01_mosaic_stack_10pct_overlap\Folder_20230424', ...
            'K:\expts\AdhesionAssay\staining mucus-coated glass\2023.04.13__Pro-Q488_glycoproteindye_15well_HillLabOrca\Booger\well15_mosaic_stack_10pct_overlap\Folder_20230420', ...
            'K:\expts\AdhesionAssay\staining mucus-coated glass\2023.04.13__Pro-Q488_glycoproteindye_15well_HillLabOrca\Booger\well01_mosaic_stack_no_overlap', ...
            'K:\expts\AdhesionAssay\staining mucus-coated glass\2023.04.13__Pro-Q488_glycoproteindye_15well_HillLabOrca\Booger\well15_mosaic_stack_no_overlap', ...
            };

stacklist = { 'Individual_images_well_01_*.vsi', ...
              'Well 15 Individual Images_redo_*.vsi', ...
              'Well01_individual_nooverlap_doneright_*.vsi', ...
              'Well15_individual_nooverlap_*.vsi', ...
              };

titlelist = { 'mucus, stain, 10% overlap', ...
              'mucus, no stain, 10% overlap', ...
              'mucus, stain, no overlap', ...
              'mucus, no stain, no overlap', ...
              };

for f = 1:length(stacklist)

    cout{f} = fix_stack(dirlist{f}, stacklist{f}, dark_image, shade_image);
    
    display_montage(cout{f}, titlelist{f})

end

function cim = fix_stack(stackdir, stackfilemask, dark_image, shade_image)
    startdir = pwd;
    cd(stackdir);
    [stack, metaout] = load_bfstack(stackfilemask);

    stagexy = extract_bfstagecoords(metaout);
    xylocs = stagepos2mosaicloc(stagexy);
    
    for k = 1:size(xylocs,1) 
        s{xylocs(k,1), xylocs(k,2)} = stack{k,1}; 
    end
    
    cim = correct_images(dark_image, shade_image, s);    
    
    cd(startdir);
end

function display_montage(cim, titlestring)
    figure;
    montage(cim);
    ax = gca;
    ax.CLimMode = 'auto';
    title(titlestring);
end