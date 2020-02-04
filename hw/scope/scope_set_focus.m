function scope_set_focus(obj1, pos)

% Flush data in input buffer
flushinput(obj1)

% Set the 'recieved' variable to false 
recieved = false;

% Reads the input
while ~recieved    
    command = strcat('cSMV', num2str(pos));
    data = query(obj1, command, '%s\n' ,'%s');
    if strcmp(data,'oSMV')
        disp('Focus has been set')
        recieved = true;
    else
        flushinput(obj1)
        disp('Resending command...')
    end
end