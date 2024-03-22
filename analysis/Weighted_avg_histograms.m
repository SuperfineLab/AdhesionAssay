function outs = Weighted_avg_histograms(sim_data,master_curves)
%master curves argument is the output from running resample_study(Broot,1,1,true)
%sim_data is the output from resample_study()




selectedRows = ~cellfun(@isempty, sim_data.FitObject);

% Use the logical index to select rows
Filtered_sim_data =  sim_data(selectedRows, :);
Number_of_failed_fits = height(sim_data) - height(Filtered_sim_data);


plategroups = unique(Filtered_sim_data.PlateID);
curvecountgroups = unique(Filtered_sim_data.CurveCount);


idx = 1;

        
Filtered_sim_data.am_weights = ba_weights(Filtered_sim_data.amconf,0.95);
Filtered_sim_data.bm_weights = ba_weights(Filtered_sim_data.bmconf,0.95);

am_and_bm = vertcat(Filtered_sim_data.am,Filtered_sim_data.bm);

weights = vertcat(Filtered_sim_data.am_weights,Filtered_sim_data.bm_weights);

am_bm_table.PlateID = vertcat(Filtered_sim_data.PlateID,Filtered_sim_data.PlateID);
am_bm_table.curvecount = vertcat(Filtered_sim_data.CurveCount,Filtered_sim_data.CurveCount);
am_bm_table.m = am_and_bm;
am_bm_table.weights = weights;
am_bm_table = struct2table(am_bm_table);
%combine all am's and bm's into single table with their corresponding
%weights


%need to filter out m's with NAN weights
am_bm_selectedRows = ~isnan(am_bm_table.weights);

% Use the logical index to select rows
filtered_am_bm_table =  am_bm_table(am_bm_selectedRows, :);
nan_num = height(am_bm_table) - height(filtered_am_bm_table);



%%% You will need to run master_curves = splitvars(master_curves, 'amconf');
%%% and also master_curves = splitvars(master_curves, 'bmconf');
%%% for the function to work properly

idx = 1;
plategroups = unique(filtered_am_bm_table.PlateID);
curvecountgroups = unique(filtered_am_bm_table.curvecount);

binWidth = 0.17;



%%%Plot histograms for am data
        for i = 1:length(plategroups) %%reversing loop was important to make the colors look right and match up with their legend color
            hold off;
            % Extract data corresponding to the current group
            current_plate = plategroups(i);
            groupData = filtered_am_bm_table(filtered_am_bm_table.PlateID == current_plate, :);

            for  k = length(curvecountgroups):-1:1
                
                %extract data corresponding to the current subgroup
                subgroupData = groupData(groupData.curvecount == curvecountgroups(k),:);
                subgroupData = subgroupData(subgroupData.m <= 10,:);
                edges = -3:binWidth:max(subgroupData.m);
                histogram(subgroupData.m, edges);
             
                legendStrings{k} = sprintf('%d curves', curvecountgroups(k));
                hold on;
              
            end
            title(["Combined am and bm histogram for ", current_plate])
            legend(legendStrings);

            m_weighted_mean = sum((subgroupData.m.*subgroupData.weights))/sum(subgroupData.weights);
            
            yLimit = 150; % Get the current y-axis limits
            
            plot([m_weighted_mean,m_weighted_mean], [0,yLimit], 'k--', 'LineWidth', 1.5, 'DisplayName', 'Weighted Mean'); 
            
        end


            
end

        
