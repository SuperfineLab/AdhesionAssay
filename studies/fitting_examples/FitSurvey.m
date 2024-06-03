%%%Fit Survey

clear lsqfit
clear gafit
clear particlefit
clear patternfit

initialstartpoint = [0.5,-1.5,0.5,0.5,-1/3,0.5];

Data = B.DetachForceTable;

do_this = 0;

if do_this
    for m =1:4
        lsqfit{m} = ba_lsqfit(Data,initialstartpoint);
    end
    
    lsq_precision = fit_precision(vertcat(lsqfit{:}),"lsqfit");
    
    for m = 1:2
        gafit{m} = ba_gafit(Data);
    end
    
    ga_precision = fit_precision(vertcat(gafit{:}),"gafit");
    
    for m = 1:4
        particlefit{m} = ba_particleswarm(Data);
    end
    
    particle_precision = fit_precision(vertcat(particlefit{:}),"particlefit");
    
    for m = 1:4
        patternfit{m} = ba_patternsearch(Data,initialstartpoint);
    end
    
    pattern_precision = fit_precision(vertcat(patternfit{:}),"patternFit");
    
    precision_table = vertcat(lsq_precision,pattern_precision,particle_precision,ga_precision);
end

%%% End of section for calculating fits on whole plates
pause(0.1)
%%% calculating fits for individual rows (using 1/3rd of data):


grouped_B = randrowcol(B);
%%This randomly assigns 1,2, or 3 for the row number and 1,2,3,4, or 5
%%for the col number so that we can subsample based on that later
if do_this

for m = 1:3
   temp = grouped_B.DetachForceTable;
    for n = 1:height(grouped_B.DetachForceTable) %loop thru each plate in detatch force table
        %extract row data
        clear Raw_Row_Data
        
        Raw_Row_Data = temp.RawData{n};
        Raw_Row_Data = Raw_Row_Data(Raw_Row_Data.row==m,:);
    
        temp.RawData(n,:) = {Raw_Row_Data};

    end


        for k =1:5
            rowlsqfit{k} = ba_lsqfit(temp,initialstartpoint);
        end
        
        lsq_rowprecision = fit_precision(vertcat(rowlsqfit{:}),"lsqfit");
        
        for k = 1:2
            rowgafit{k} = ba_gafit(temp);
        end
        
        ga_rowprecision = fit_precision(vertcat(rowgafit{:}),"gafit");
        
        for k = 1:5
            rowparticlefit{k} = ba_particleswarm(temp);
        end
        
        particle_rowprecision = fit_precision(vertcat(rowparticlefit{:}),"particlefit");
        
        for k = 1:5
            rowpatternfit{k} = ba_patternsearch(temp,initialstartpoint);
        end
        
        pattern_rowprecision = fit_precision(vertcat(rowpatternfit{:}),"patternFit");
        
        row_precision_cellarray{m} = vertcat(lsq_rowprecision,pattern_rowprecision,particle_rowprecision,ga_rowprecision);


end

end


pause(0.1)

for m = 1:5
   temp = grouped_B.DetachForceTable;
    for n = 1:height(grouped_B.DetachForceTable) %loop thru each plate in detatch force table
        %extract row data
        clear Raw_col_Data
        
        Raw_col_Data = temp.RawData{n};
        Raw_col_Data = Raw_col_Data(Raw_col_Data.Col==m,:);
    
        temp.RawData(n,:) = {Raw_col_Data};

    end


        for k =1:2
            collsqfit{k} = ba_lsqfit(temp,initialstartpoint);
        end
        
        lsq_colprecision = fit_precision(vertcat(collsqfit{:}),"lsqfit");
        
        for k = 1:2
            colgafit{k} = ba_gafit(temp);
        end
        
        ga_colprecision = fit_precision(vertcat(colgafit{:}),"gafit");
        
        for k = 1:2
            colparticlefit{k} = ba_particleswarm(temp);
        end
        
        particle_colprecision = fit_precision(vertcat(colparticlefit{:}),"particlefit");
        
        for k = 1:2
            colpatternfit{k} = ba_patternsearch(temp,initialstartpoint);
        end
        
        pattern_colprecision = fit_precision(vertcat(colpatternfit{:}),"patternFit");
        
        col_precision_cellarray{m} = vertcat(lsq_colprecision,pattern_colprecision,particle_colprecision,ga_colprecision);


end






%%%
%%% Local Functions down here
%%%


function prec_table = fit_precision(fit,fit_type_string) 
plategroups = unique(fit.PlateID);

for i = 1:length(plategroups)
            clear temp
            % Extract data corresponding to the current group
            current_plate = plategroups(i);
            platedata = fit(fit.PlateID == current_plate, :);


%% could pass another argument into function to select spread metric that we want
%% For now just using SD.          
            temp{i} = platedata.OptimizedStartParameters;
            temp = array2table(vertcat(temp{:}));
            
            prec_table{i}.PlateID = current_plate;
            prec_table{i}.fitmethod = fit_type_string;
            prec_table{i}.a_sd = std(temp.Var1);
            prec_table{i}.am_sd = std(temp.Var2);
            prec_table{i}.as_sd = std(temp.Var3);
            prec_table{i}.b_sd = std(temp.Var4);
            prec_table{i}.bm_sd = std(temp.Var5);
            prec_table{i}.bs_sd = std(temp.Var6);
            
            


    end
prec_table = struct2table(vertcat(prec_table{:}));
end



function newB = randrowcol(B)
newB = B;
        for row = 1:height(B.DetachForceTable)
            currentplate = B.DetachForceTable(row,:);
            currentdata = currentplate.RawData{:};
            numRows = height(currentdata);
            RowgroupNumbers = repmat([1, 2, 3], 1, ceil(numRows/3));
            RowgroupNumbers = RowgroupNumbers(1:numRows); 
            shuffledrowGroupNumbers = RowgroupNumbers(randperm(numRows))';
            currentdata.row = shuffledrowGroupNumbers;
            newB.DetachForceTable(row, :).RawData = {currentdata};
            colgroupNumbers = repmat([1,2,3,4,5],1,ceil(numRows/5));
            colgroupNumbers = colgroupNumbers(1:numRows);
            shuffledcolGroupNumbers = colgroupNumbers(randperm(numRows))';
            currentdata.Col = shuffledcolGroupNumbers;
            newB.DetachForceTable(row,:).RawData = {currentdata};
        end
end