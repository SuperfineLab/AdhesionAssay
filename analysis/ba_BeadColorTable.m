function BeadColorTable = ba_BeadColorTable
% BA_BEADCOLORTABLE creates color table for datavis in Adhesion Assay project
%
% Adhesion Assay
% Analysis
%
% This function creates the color table for data visualizations generated 
% in Adhesion Assay project.
% 
% BeadColorTable = ba_BeadColorTable
%
% Outputs: 
%   BeadColorTable contains color specifications for bead functionalization
%
% Inputs:
%   (none)
%

    BeadChemistryCategories = categorical({'COOH'; 'PEG'; 'PWM'; 'WGA'; 'SNA'; 'HBE'});
    
    BeadColorTable = table('Size', [6 2], 'VariableTypes', {'categorical','double'}, ...
                                          'VariableNames', {'BeadChemistry','BeadColor'});
    
    BeadColorTable.BeadChemistry = BeadChemistryCategories;
    BeadColorTable.BeadColor = [0.5 0.5 0.5; lines(5)];

end