function value = ivar_extract(ivarTable,var)

i = 1;

while i <= height(ivarTable)
    if ivarTable{i,'Field_name'} == var
       value = convertStringsToChars(ivarTable{i,'Value'});
       break
    end
    i = i + 1;
end

clear i