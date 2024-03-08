function outs = clean_sim_data(sim_data)




selectedRows = ~cellfun(@isempty, sim_data.FitObject);

% Use the logical index to select rows
Filtered_sim_data =  sim_data(selectedRows, :);
Number_of_failed_fits = height(sim_data) - height(Filtered_sim_data);


plategroups = unique(Filtered_sim_data.PlateID);
    curvecountgroups = unique(Filtered_sim_data.CurveCount);
    ci_widths = cell(length(curvecountgroups)*length(plategroups),1);

idx = 1;

        for i = 1:length(plategroups)
            % Extract data corresponding to the current group
            groupData = Filtered_sim_data(Filtered_sim_data.PlateID == plategroups(i), :);

            for k = 1:length(curvecountgroups)
                %extract data corresponding to the current subgroup
                %idx = (i*length(curvecountgroups)-1)+(k-1);
                subgroupData = groupData(groupData.CurveCount == curvecountgroups(k),:);
                ci_widths{(idx)}.PlateID = subgroupData.PlateID;
                ci_widths{(idx)}.curvecount = subgroupData.CurveCount;
                ci_widths{(idx)}.amconfwidth = diff(subgroupData.amconf,[],2);
                ci_widths{(idx)}.bmconfwidth = diff(subgroupData.bmconf,[],2);
                ci_widths{(idx)} = struct2table(ci_widths{(idx)});
                idx = idx+1;
               

            end
        end

ci_widths = vertcat(ci_widths{:});

%I want to replace values with NaN if they are greater than a certain
%value, for now i will say 1000 but will talk to jeremy to see if he
%thinks this is reasonable

am_indices = ci_widths.amconfwidth > 1000;
ci_widths.amconfwidth(am_indices) = NaN;

bm_indices = ci_widths.bmconfwidth > 1000;
ci_widths.bmconfwidth(bm_indices) = NaN;

both_nan_indices = isnan(ci_widths.amconfwidth) & isnan(ci_widths.bmconfwidth);

ci_widths = ci_widths(~both_nan_indices,:);

Number_of_failed_fits = height(sim_data) - height(ci_widths);

outs = ci_widths;

end