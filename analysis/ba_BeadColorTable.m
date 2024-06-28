function BeadColorTable = ba_BeadColorTable

    BeadChemistryCategories = categorical({'COOH'; 'PEG'; 'PWM'; 'WGA'; 'SNA'; 'HBE'});
    
    BeadColorTable = table('Size', [6 2], 'VariableTypes', {'categorical','double'}, ...
                                          'VariableNames', {'BeadChemistry','BeadColor'});
    
    BeadColorTable.BeadChemistry = BeadChemistryCategories;
    BeadColorTable.BeadColor = [0.5 0.5 0.5; lines(5)];

end