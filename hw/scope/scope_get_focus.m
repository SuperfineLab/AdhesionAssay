function pos = scope_get_focus(obj1)

% Flush data in input buffer
flushinput(obj1)

% Set the 'recieved' variable to false 
recieved = false;

% Reads the input
while ~recieved    
    data = query(obj1, 'rSPR', '%s\n' ,'%s');
    if strcmp(data(1:4),'aSPR')
        pos = str2double(data(5:end));
        recieved = true;
    else
        flushinput(obj1)
        disp('Resending command...')
    end
end