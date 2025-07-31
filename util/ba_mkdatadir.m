function new_data_dir = ba_mkdatadir(foldername)
% BA_MKDATADIR creates typical folder set for running an Adhesion assay.
%
% This function creates a data directory and its typical subdirectories for
% mosaics and eventual tracking and metadata backup files.
%
% new_data_dir = ba_mkdatadir(foldername)
%

    mkdir(foldername);
    chdir(foldername);
    
    mkdir('mosaics_before'); 
    mkdir('mosaics_after');
    mkdir('evt_backup');
    mkdir('metadata_backup');

    new_data_dir = pwd;

end