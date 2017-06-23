function TrimVideo(inputVideoPath, parametersStructure)
%TRIM VIDEO Removes upper and right edge of video
%   Removes the upper few rows and right few columns. The number to be
%   removed is specified by |parametersStructure.borderTrimAmount| or is
%   assumed to be 24 pixels if not provided.
%
%   |inputVideoPath| is the path to the video. The result is that the
%   trimmed version of this video is stored with '_dwt' appended to the
%   original file name. |parametersStructure.overwrite| determines whether
%   an existing output file should be overwritten and replaced if it
%   already exists.

outputVideoPath = [inputVideoPath(1:end-4) '_dwt' inputVideoPath(end-3:end)];

%% Handle overwrite scenarios.
if ~exist(outputVideoPath, 'file')
    % left blank to continue without issuing warning in this case
elseif ~isfield(parametersStructure, 'overwrite') || ~parametersStructure.overwrite
    warning('TrimVideo() did not execute because it would overwrite existing file.');
    return;
else
    warning('TrimVideo() is proceeding and overwriting an existing file.');
end

%% Trim the video frame by frame

writer = VideoWriter(outputVideoPath, 'Grayscale AVI');
open(writer);

% Sets the width of each trim to 24 pixels if no amount is specified.
if nargin == 1
    parametersStructure.borderTrimAmount = 24;
end

[videoInputArray, ~] = VideoPathToArray(inputVideoPath);

height = size(videoInputArray, 1);
width = size(videoInputArray, 2);
numberOfFrames = size(videoInputArray, 3);

% Preallocate.
trimmedFrames = zeros(height - parametersStructure.borderTrimAmount, ...
    width - parametersStructure.borderTrimAmount, numberOfFrames, 'uint8');

for frameNumber = 1:numberOfFrames
    frame = videoInputArray(:,:,frameNumber);
    trimmedFrames(:,:,frameNumber) = ...
        frame(parametersStructure.borderTrimAmount+1 : height, ...
       1 : width-parametersStructure.borderTrimAmount);
end

writeVideo(writer, trimmedFrames);
close(writer);

end