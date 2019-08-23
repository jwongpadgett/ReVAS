function SampleRunner
% SampleRunner
%  An example script of how to run the modules.
%
%  MTS 8/22/19 wrote the initial version

%% Example of running pipeline without writing result after each module.

inputVideoPath = 'demo/sample10deg.avi';
outputVideoPath = 'demo/sampleRunnerResult.avi';

% Read the input video and pass the matrix into the functions to skip
% writing intermediate videos to file after each module.
reader = VideoReader(inputVideoPath);
numberOfFrames = reader.Framerate * reader.Duration;

% preallocate
video = zeros(reader.Height, reader.Width, numberOfFrames, 'uint8');

for frameNumber = 1:numberOfFrames
    video(1:end, 1:end, frameNumber) = readFrame(reader);
end


% Run desired modules.
% Also see example usages in the header comment of each module file.
parametersStructure = struct;
video = TrimVideo(video, parametersStructure);

stimulus = struct;
stimulus.size = 11;
stimulus.thickness = 1;
video = RemoveStimuli(video, stimulus, parametersStructure);

parametersStructure.isHistEq = false;
parametersStructure.isGammaCorrect = true;
video = GammaCorrect(video, parametersStructure);

video = BandpassFilter(video, parametersStructure);


% Write the video when finished with desired modules.
writer = VideoWriter(outputVideoPath, 'Grayscale AVI');
% some videos are not 30fps, we need to keep the same framerate as
% the source video.
writer.FrameRate=reader.Framerate;
open(writer);
for frameNumber = 1:numberOfFrames
   writeVideo(writer, video(1:end, 1:end, frameNumber));
end

close(writer);

end