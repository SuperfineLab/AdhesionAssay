function value = ivar_extract(ivarTable,var)

k = 1;

while k <= height(ivarTable)
    if ivarTable{k,'Field_name'} == var
       value = convertStringsToChars(ivarTable{k,'Value'});
       break
    end
    k = k + 1;
end

