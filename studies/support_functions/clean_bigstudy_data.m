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

    B.DetachForceTable.BeadChemistry( B.DetachForceTable.BeadChemistry == "mPEG" ) = "PEG";
    B.DetachForceTable.BeadChemistry( B.DetachForceTable.BeadChemistry == "RhoPEG" ) = "PEG";
    B.DetachForceTable.BeadChemistry = removecats(B.DetachForceTable.BeadChemistry);
%     B.DetachForceTable.BeadChemistry = reordercats(B.DetachForceTable.BeadChemistry, goodOrder);    
    
    B.DetachForceTable.SubstrateChemistry( B.DetachForceTable.SubstrateChemistry == "RhoPEG" ) = "PEG";
    B.DetachForceTable.SubstrateChemistry( B.DetachForceTable.SubstrateChemistry == "mPEG" ) = "PEG";
    B.DetachForceTable.SubstrateChemistry = removecats(B.DetachForceTable.SubstrateChemistry);

%     B.DetachForceTable.DetachForce(abs(imag(B.DetachForceTable.DetachForce)) > ...
%                                    0.1*abs(real(B.DetachForceTable.DetachForce))) = complex(NaN);
%     B.DetachForceTable.DetachForce =  abs(B.DetachForceTable.DetachForce);
%     B.DetachForceTable.DetachForce( isnan(B.DetachForceTable.DetachForce) ) = 111;
end