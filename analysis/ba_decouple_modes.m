function ParamTable = ba_decouple_modes(ForceFitTable, groupvars)
% BA_DECOUPLE_MODES outputs fit parameters decoupled mode-by-mode from full fit equation
%
% ParamTable = ba_decouple_modes(ForceFitTable, groupvars)
%
% inputs:
%   ForceFitTable - from the ba_process_expt output structure
%   groupvars - grouping variables from the run, can also be found in
%               ba_process_expt output structure.
%
% output:
%   ParamTable - new table containing unstacked parameter values from fits
%
% Note: YOU MUST USE ALL GROUPING VARS HERE FOR YOUR STUDY OR UNSTACK WILL 
%       DO STATS ON YOUR PARAMETERS!
%

% The goal here is to output a new table that contains fit parameters 
% decoupled mode-by-mode from full fit equation.

groupvars = unique(['PlateID', groupvars], 'stable');
Ngroupvars = numel(groupvars);

% Add the fitting parameters and their confidence intervals as variables
% for the new table
T = ForceFitTable(:, [groupvars, 'FitParams', 'confFitParams']);

% Weirdness in code somewhere that embeds parameter list into a secondary
% level cell class/type. Until I dig it out, this will extract the
% parameters from the secondary level.
for k = 1:height(T)
    if contains(class(T.FitParams{k}), 'cell')
        T.FitParams{k} = T.FitParams{k}{1}; 
        T.confFitParams{k} = T.confFitParams{k}{1};
    end
end

% Declare and copy class types for the new table
Nvars = size(T,2);
mytype = cell(1,Nvars);
for c = 1:Nvars
    mytype{1,c} = class(T{:,c}); 
end


% Begin prepping data for new table by ensuring the parameter list is a
% column vector, where a row vector of parameters is the default shape. 
% Doing this preps for the unstacking operation that occurs later on
T.FitParams= cellfun(@(x)(x(:)),T.FitParams,'UniformOutput',false);
T.confFitParams = cellfun(@transpose,T.confFitParams,'UniformOutput',false);


% Initialize the new table 
new_varlist = [groupvars, 'ModeIndex', 'ParamIndex', 'ParamValue', 'confParamValue'];
new_vartypes = [mytype(1:Ngroupvars), 'double', 'double', 'double', 'double'];

ParamListTable = table('Size', [0 numel(new_varlist)], ...
                       'VariableTypes', new_vartypes, ...
                       'VariableNames', new_varlist);

% Fill new table with decoupled Fit Modes from full fit equation
for t = 1:height(T)
    myRow = T(t,:);
    myParams = myRow.FitParams{1};
    myconfParams = myRow.confFitParams{1};
    Nmodes = numel(myParams)/3;
    
    [mode_index, param_index] = meshgrid(1:Nmodes,1:3);

    % throw out anything not a grouping variable
    myRow = myRow(:,groupvars);

    newRows = repmat(myRow,Nmodes*3,1);

    newRows.ModeIndex = mode_index(:);
    newRows.ParamIndex = param_index(:);
    newRows.ParamValue = myParams;
    newRows.confParamValue = myconfParams;
    ParamListTable = vertcat(ParamListTable, newRows);
end

% "Unstacking" each of the newly decoupled modes separates the parameters 
% according to their function in the equation, labeled here for each "Mode"
% as "Scale", "Force", and "Spread", where each parameter is defined in the 
% AdhesionAssay standard fit function form, i.e., 
% [ ModeScale * erfc( (Fd-ModeForce)/(sqrt(2)*ModeSpread))  ]
ParamDataTable = unstack(ParamListTable, {'ParamValue', 'confParamValue'}, 'ParamIndex');

% Rename auto-generated table variable names
oldnames = {'ParamValue_x1', 'ParamValue_x2', 'ParamValue_x3', ...
            'confParamValue_x1', 'confParamValue_x2', 'confParamValue_x3'};
newnames = {'ModeScale', 'ModeForce', 'ModeSpread', ...
            'confModeScale', 'confModeForce', 'confModeSpread'};
ParamDataTable = renamevars(ParamDataTable, oldnames, newnames);

% XXX @jeremy TODO Fix this function according to note below:
%%%%%% EVERYTHING BELOW HERE IS NO LONGER DECOUPLING ANYTHING. INSTEAD IT
%%%%%% IS CALCULATING/FILTERING FORCE STUFF.
ParamDataTable.RelWidth = ba_relwidthCI(ParamDataTable.ModeForce, ParamDataTable.confModeForce);

logForceThreshLow = -1.5;
logForceThreshHigh = 2.5; % log space
RelWidthThreshLow = 1e-5;
RelWidthThreshHigh = 1000; % not log space

InBoundsForces = ( ParamDataTable.ModeForce > logForceThreshLow & ...
                   ParamDataTable.ModeForce < logForceThreshHigh ) & ...
                 ( ParamDataTable.RelWidth  > RelWidthThreshLow & ...
                   ParamDataTable.RelWidth  < RelWidthThreshHigh );
ParamDataTable.IncludeTF = InBoundsForces;


DataCollectEfficiency = sum(ParamDataTable.IncludeTF) ./ height(ParamDataTable);
logentry(['Fraction of data passing thresholds: ', num2str(DataCollectEfficiency, '%3.2f')]);

% figure; 
% plot(ParamDataTable.ModeForce(~ParamDataTable.IncludeTF), ParamDataTable.ModeSpread(~ParamDataTable.IncludeTF), 'rx', ...
%      ParamDataTable.ModeForce( ParamDataTable.IncludeTF), ParamDataTable.ModeSpread( ParamDataTable.IncludeTF), 'k.');
% ax = gca; ax.XScale = "log"; ax.YScale = "log";
% xlabel("log_{10}(ModeForce)"); ylabel("log_{10}(ModeSpread)");
% grid on

% figure; 
% plot(ParamDataTable.ModeForce( ParamDataTable.IncludeTF), ParamDataTable.ModeSpread( ParamDataTable.IncludeTF), 'k.');
% xlabel("log_{10}(ModeForce)"); ylabel("log_{10}(ModeSpread)");
% grid on

ParamTable = ParamDataTable;