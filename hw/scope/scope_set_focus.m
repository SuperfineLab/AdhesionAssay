function scope_set_focus(obj1, pos)
% SCOPE_SET_FOCUS sets the focus of the microscope

% Flush data in input buffer
flushinput(obj1)

% Set the tolerance value to which the final position should be within
tol = 50;

% Set the 'recieved' variable to false 
recieved = false;
tic

% build the command
command = strcat('cSMV', num2str(pos));

% Reads the input
while ~recieved    
    data = query(obj1, command, '%s\n' ,'%s');
    disp(data)
    if strcmp(data,'oSMV')
        if abs(scope_get_focus(obj1) - pos) <= tol
            disp('Focus has been set')
            recieved = true;
        end
    else
        flushinput(obj1)
        disp('Resending command...')
    end
end

toc