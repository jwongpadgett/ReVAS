function RevasError(filename, message, parametersStructure)
%REVAS ERROR  Issues a error message to the GUI's command window text box if possible.
%   Issues a error message to the GUI's command window text box if possible.
%   Execution will continue after the error message is printed if using the GUI.

if isfield(parametersStructure, 'commandWindowHandle')
    dateAndTime = datestr(datetime('now'));
    time = dateAndTime(13:20);
    parametersStructure.commandWindowHandle.String = ...
        ['(' time ') ERROR: ' ...
        '(Error while processing ' filename '. Proceeding to next video.) ' ...
        message; ...
        parametersStructure.commandWindowHandle.String];
end
    
end