function outpwd = ba_mkdatadir(foldername)
% BA_MKDATADIR creates typical folder set for running an Adhesion assay.
%
% outs = ba_mkdatadir(foldername)
%
% This function creates a data directory and its typical subdirectories for
% mosaics and eventual tracking and metadata backup files.
%

    mkdir(foldername);
    chdir(foldername);
    
    mkdir('mosaics_before'); 
    mkdir('mosaics_after');
    mkdir('evt_backup');
    mkdir('metadata_backup');

    outpwd = pwd;

end