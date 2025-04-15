function TableColTF = isTableCol(TableIn, ColName)
% ISTABLECOL returns whether ColName is an existing column in TableIn
%
%   TableColTF = isTableCol(TableIn, ColName)
% 
% Inputs:
%   TableIn* - table input
%   ColName* - name of column to check in TableIn
%
% (*) required inputs
%

if nargin < 2 || isempty(ColName)
    error('Column Name is not defined.');
end

if nargin < 1 || isempty(TableIn)
    error('Table input not defined.');
end

if ~contains(class(TableIn),'table')
    error('Input is not a table.');
end

    TableColTF = ismember(ColName, TableIn.Properties.VariableNames);

end