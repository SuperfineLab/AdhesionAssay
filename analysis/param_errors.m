function outs = param_errors(Broot, agg_num,sample_type)
%%% agg_num - how many beads do you want to sample from each plate?
%%% sample_type - A Boolean; true means with replacement, false means
%%% without replacement

FileVarsToKeep = {'PlateID', 'Fid', 'Well', 'PlateRow', 'PlateColumn', 'SubstrateChemistry','FirstFrameBeadCount', 'LastFrameBeadCount'};
%%% I got rid of Bead Chemistry because in all of these plates, the bead
%%% chemistry is the same as the substrate chemistry, so having both
%%% variables is redundant.
%%%I also got rid of Buffer, and PH, because for every observation they
%%%were PBS, and 7, respectively

file_force_table = innerjoin(Broot.FileTable(:,FileVarsToKeep), Broot.ForceTable, 'Keys', {'Fid'}); %% keeps only relevant columns

[g, gT] = findgroups(file_force_table(:,'PlateID'));

%groups by both plateID and well and calculates the total beads in each
%well, for each plate
beadtotals = groupsummary(file_force_table, {'PlateID', 'Well'}, 'sum', 'FirstFrameBeadCount');

%%individual wells are overrepresented, the variable groupcount tells us
%%how many times each individual well appears in the groupsummary
%%calculation, so by dividing the beadtotals by the groupcount, we can find
%%the actual number of beads in each well.
beadtotals.actual_count = beadtotals.sum_FirstFrameBeadCount./beadtotals.GroupCount;

[s,sT] = findgroups(beadtotals(:,"PlateID"));
gT.total_beads_on_plate = splitapply(@(x)sum(x),beadtotals.actual_count,s);

gT.MaxBeadCount = splitapply(@(x)max(x), file_force_table.SpotID, g);
%%%gT.MeanBeadCount = splitapply(@(x)mean(x), file_force_table.SpotID, g);
gT.MeanBeadCount = gT.total_beads_on_plate./15;
%gT.TotalBeadCount = sum(summarydata.sum_FirstFrameBeadCount/summarydata.GroupCount);
file_force_table = innerjoin(file_force_table,gT);




%%% Master Curve Parameter Calculations:

[m,master_params] = findgroups(file_force_table(:,"PlateID"));
blah = splitapply(@(x1,x2,x3)ba_fit_erf(x1,x2,x3), log10(file_force_table.Force), ...
                                                       file_force_table.FractionLeft, ...
                                                       file_force_table.Weights,m);

blah_table = struct2table(blah);

master_params.am = blah_table.am;
master_params.as = blah_table.as;
master_params.bm = blah_table.bm;
master_params.bs = blah_table.bs;


%%% end of Master Curve Param Calculation


for k = 1:length(agg_num)



for i = 1:50
Nsample_array{i,1} = grouped_resample(file_force_table,agg_num(k),sample_type);
end
result_array{k,1} = vertcat(Nsample_array{:});


end

result_array = vertcat(result_array{:});



summary = groupsummary(result_array,{'PlateID','Nbeads'},{'mean','std'},'am');
%[a,aT] = findgroups(Nsample_array(:,"PlateID"));

confidence_widths = grouped_confwidth(result_array);

uniquePlateID = unique(confidence_widths.PlateID);

% Plot data for each unique PlateID separately
figure;
hold on; 
for i = 1:length(uniquePlateID)
    % Filter data for the current PlateID
    plateData = confidence_widths(confidence_widths.PlateID == uniquePlateID(i), :);
    
    % Plot the data as a line plot
    plot(plateData.Nbeads, plateData.amconfwidth, '-o', 'DisplayName', char(uniquePlateID(i)));
end

% Add labels and title
xlabel('Nbeads');
ylabel('Confidence Interval Width of am');
title('Line Graph for Each PlateID');
legend('show'); % Show legend with PlateID labels

pause(0.1)



end


function outs = grouped_resample(measurements, agg_num,sample_type)

    % Take the logarithm of measurements
    measurements.log_forces = log10(measurements.Force);
    
    
    % Preallocate cell array to store sampled points
    sampledbeads = cell(4,1);

    groups = unique(measurements.PlateID);

          
    for i = 1:length(groups)
        % Extract data corresponding to the current group
        groupData = measurements(measurements.PlateID == groups(i), :);
    
        % Sample 'agg_num' random points from the current group
        sampledbeads{i} = datasample(groupData, agg_num, 'Replace', sample_type);
    end

 
  result_array = cell(4,1);
    for i = 1:length(sampledbeads)
        % Extract data for the current plate group
        currentGroupData = sampledbeads{i};
        
     
        % calculate fit parameters for each group
        result = struct2table(ba_fit_erf(currentGroupData.log_forces, ...
            currentGroupData.FractionLeft, ...
            currentGroupData.Weights));
        
        
        
        result_array{i}.PlateID = unique(currentGroupData.PlateID);
        result_array{i}.Nbeads = agg_num;
        result_array{i}.am = result.am;
        result_array{i}.as = result.as;
        result_array{i}.bm = result.bm;
        result_array{i}.bs = result.bs;
        result_array{i}.amconf = result.amconf;
        result_array{i}.asconf = result.asconf;
        result_array{i}.bmconf = result.bmconf;
        result_array{i}.bsconf = result.bsconf;
     %   result_array{i} = RMSE COLUMN
        result_array{i} = struct2table(result_array{i});
        
    
        %why dont these work??
        
     
    end
   

    outs = vertcat(result_array{:});
end



function outs = grouped_confwidth(table)

    plategroups = unique(table.PlateID);
    Nbeadgroups = unique(table.Nbeads);
    ci_widths = cell(length(Nbeadgroups)*length(plategroups),1);
    

          
        for i = 1:length(plategroups)
            % Extract data corresponding to the current group
            groupData = table(table.PlateID == plategroups(i), :);

            for k = 1:length(Nbeadgroups)
                %extract data corresponding to the current subgroup
                idx = (i*length(Nbeadgroups)-1)+(k-1);
                subgroupData = groupData(groupData.Nbeads == Nbeadgroups(k),:);
                ci_widths{(idx)}.PlateID = plategroups(i);
                ci_widths{(idx)}.Nbeads = Nbeadgroups(k);
                ci_widths{(idx)}.amconfwidth = quantile(subgroupData.am,0.95) - quantile(subgroupData.am,0.05);
                ci_widths{(idx)}.bmconfwidth = quantile(subgroupData.bm,0.95) - quantile(subgroupData.bm,0.05);
                ci_widths{(idx)} = struct2table(ci_widths{(idx)});
                
            end
        end


    ci_widths = vertcat(ci_widths{:});

    outs = ci_widths;

end