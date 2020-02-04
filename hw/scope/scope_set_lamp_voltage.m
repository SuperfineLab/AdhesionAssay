function scope_set_lamp_voltage(obj1, voltage)

% Flush data in input buffer
flushinput(obj1)

% Set the 'recieved' variable to false 
recieved = false;

% Makes sure that the voltage called for is within bounds
if (voltage > 12) || (voltage < 3)
    error('Voltage value not within bounds of device')
end

% Reads the input
while ~recieved    
    command = strcat('cLMC', num2str(voltage));
    data = query(obj1, command, '%s\n' ,'%s');
    if strcmp(data,'oLMC')
        disp('Lamp voltage has been set')
        recieved = true;
    else
        flushinput(obj1)
        disp('Resending command...')
    end
end