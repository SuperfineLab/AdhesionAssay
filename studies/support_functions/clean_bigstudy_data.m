function B = clean_bigstudy_data(B)
% short function for cleaning a bigstudy style dataset. This function is 
% painfully specific to the datasets we've already collected and will not
% scale well as the studies grow in size and complexity.

%             goodOrder = {'PEG', 'WGA', 'HBE'};
%             goodOrder = {'COOH', 'PEG', 'HBE'};
            goodOrder = {'PEG', 'PWM', 'WGA', 'SNA', 'HBE'};
%             goodOrder = {'COOH', 'PEG', 'PWM', 'WGA', 'SNA', 'HBE'};

% XXX @jeremy TODO: Fix the category reordering issue here. Consult control and paper studies to find compatible solution for all present cases.
    B.FileTable.BeadChemistry( B.FileTable.BeadChemistry == "mPEG" ) = "PEG";
    B.FileTable.BeadChemistry( B.FileTable.BeadChemistry == "RhoPEG" ) = "PEG";
    B.FileTable.BeadChemistry = removecats(B.FileTable.BeadChemistry);
%     B.FileTable.BeadChemistry = reordercats(B.FileTable.BeadChemistry, goodOrder);
    
    B.FileTable.SubstrateChemistry( B.FileTable.SubstrateChemistry == "mPEG" ) = "PEG";
    B.FileTable.SubstrateChemistry( B.FileTable.SubstrateChemistry == "RhoPEG" ) = "PEG";
    B.FileTable.SubstrateChemistry = removecats(B.FileTable.SubstrateChemistry);

    B.ForceFitTable.BeadChemistry( B.ForceFitTable.BeadChemistry == "mPEG" ) = "PEG";
    B.ForceFitTable.BeadChemistry( B.ForceFitTable.BeadChemistry == "RhoPEG" ) = "PEG";
    B.ForceFitTable.BeadChemistry = removecats(B.ForceFitTable.BeadChemistry);
%     B.ForceFitTable.BeadChemistry = reordercats(B.ForceFitTable.BeadChemistry, goodOrder);    
    
    B.ForceFitTable.SubstrateChemistry( B.ForceFitTable.SubstrateChemistry == "RhoPEG" ) = "PEG";
    B.ForceFitTable.SubstrateChemistry( B.ForceFitTable.SubstrateChemistry == "mPEG" ) = "PEG";
    B.ForceFitTable.SubstrateChemistry = removecats(B.ForceFitTable.SubstrateChemistry);

    B.OptimizedStartTable.BeadChemistry( B.OptimizedStartTable.BeadChemistry == "RhoPEG" ) = "PEG";
    B.OptimizedStartTable.BeadChemistry( B.OptimizedStartTable.BeadChemistry == "mPEG" ) = "PEG";
    B.OptimizedStartTable.BeadChemistry = removecats(B.OptimizedStartTable.BeadChemistry);
%     B.OptimizedStartTable.BeadChemistry = reordercats(B.OptimizedStartTable.BeadChemistry, goodOrder);    
    
    B.OptimizedStartTable.SubstrateChemistry( B.OptimizedStartTable.SubstrateChemistry == "RhoPEG" ) = "PEG";
    B.OptimizedStartTable.SubstrateChemistry( B.OptimizedStartTable.SubstrateChemistry == "mPEG" ) = "PEG";
    B.OptimizedStartTable.SubstrateChemistry = removecats(B.OptimizedStartTable.SubstrateChemistry);

    B.DetachForceTable.BeadChemistry( B.DetachForceTable.BeadChemistry == "RhoPEG" ) = "PEG";
    B.DetachForceTable.BeadChemistry( B.DetachForceTable.BeadChemistry == "mPEG" ) = "PEG";
    B.DetachForceTable.BeadChemistry = removecats(B.DetachForceTable.BeadChemistry);
%     B.DetachForceTable.BeadChemistry = reordercats(B.DetachForceTable.BeadChemistry, goodOrder);    
    
    B.DetachForceTable.SubstrateChemistry( B.DetachForceTable.SubstrateChemistry == "RhoPEG" ) = "PEG";
    B.DetachForceTable.SubstrateChemistry( B.DetachForceTable.SubstrateChemistry == "mPEG" ) = "PEG";
    B.DetachForceTable.SubstrateChemistry = removecats(B.DetachForceTable.SubstrateChemistry);
    
end