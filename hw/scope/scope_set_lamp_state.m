function scope_set_lamp_state(obj1, state)

% Flush data in input buffer
flushinput(obj1)

% Increase the timeout to avoid flooding the buffer
set(obj1, 'Timeout', 100.0);

% Set the 'recieved' variable to false 
recieved = false;

% Reads the input
while ~recieved    
    command = strcat('cLMS', num2str(state));
    data = query(obj1, command, '%s\n' ,'%s');
    if strcmp(data,'oLMS')
        disp('Lamp state has been set')
        recieved = true;
    else
        flushinput(obj1)
        disp('Resending command...')
    end
end