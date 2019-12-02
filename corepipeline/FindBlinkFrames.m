function [badFrames, varargout] = FindBlinkFrames(inputVideo, params)
%FIND BLINK FRAMES  Records in a mat file the frames in which a blink
%                   occurred. Blinks are considered to be frames in which
%                   the frame's mean and standard deviation are reduced
%                   whereas skewness and kurtosis of its histogram are
%                   increased. We use k-means clustering to find bad frames
%                   using these four image stats. There is a hard threshold
%                   for separating the two clusters, i.e., if mean values
%                   of bad frames and good frames are no different than
%                   this threshold, we take it as absence of any blinks/bad
%                   frames.
%
%   The result is stored with '_blinkframes' appended to the input video
%   file name if a |inputVideo| path is provided, and it is also returned
%   by the function. If the input video is a path, blink frames are written
%   to a file. Regardless of the input, an index array of |badFrames| is
%   returned at the first output argument.
%
%   -----------------------------------
%   Input
%   -----------------------------------
%   |inputVideo| is the path to the video or a matrix representation of the
%   video that is already loaded into memory.
%
%   |params| is a struct as specified below.
%
%
%   -----------------------------------
%   Output
%   -----------------------------------
%   |badFrames| is index array (logical) where 1s indicate bad frames.
%
%   varargout{1} = badFramesMatFilePath
%   varargout{2} = image statistics extracted from all frames.
%   varargout{3} = candidate for initial reference frame based on means.
%
%
%   -----------------------------------
%   Fields of the |params| 
%   -----------------------------------
%  overwrite           :   set to 1 to overwrite existing files resulting 
%                          from calling FindBlinkFrames.
%                          Set to 0 to abort the function call if the
%                          files exist in the current directory.
%  enableVerbosity     :   set to true to report back plots during execution.
%                          (default false)
%  stitchCriteria      :   optional--specify the maximum distance (in frames)
%                          between blinks, below which two blinks will be
%                          marked as one. For example, if badFrames is 
%                          [8, 9, 11, 12], this represents two blinks, one
%                          at frames 8 and 9, and the other at frames 
%                          11 and 12. If stitchCriteria is 2, then 
%                          badFrames becomes [8, 9, 10, 11, 12] because the
%                          distance between the blinks [8, 9] and [11, 12]
%                          are separated by only one frame, which is less
%                          than the specified stitch criteria.
%  numberOfBins        :   optional--specify number of bins for image 
%                          histogram. All image stats are computed using
%                          this histogram. The default value is 256.
%  meanDifferenceThreshold: minimum mean gray level distance between two
%                          clusters representing bad and good frames.
%                          
%   -----------------------------------
%   Example usage
%   -----------------------------------
%       videoPath = 'aoslo-blink.avi';
%       params.overwrite = true;
%       params.stitchCriteria = 1;
%       params.numberOfBins = 256;
%       params.meanDifferenceThreshold = 256;
%       FindBlinkFrames(videoPath, params);

%% Determine inputVideo type.
if ischar(inputVideo)
    % A path was passed in.
    % Read the video and once finished with this module, write the result.
    writeResult = true;
else
    % A video matrix was passed in.
    % Do not write the result; return it instead.
    writeResult = false;
end

%% Set parameters to defaults if not specified.

if nargin < 2
    params = struct;
end

if ~isfield(params, 'overwrite')
    overwrite = false; 
else
    overwrite = params.overwrite;
end

if ~isfield(params, 'enableVerbosity')
    enableVerbosity = false; 
else
    enableVerbosity = params.enableVerbosity;
end

if ~isfield(params, 'axesHandles')
    axesHandles = nan; 
else
    axesHandles = params.axesHandles;
end

if ~isfield(params, 'stitchCriteria')
    stitchCriteria = 1; % frame
    RevasWarning(['FindBlinkFrames is using default parameter for stitchCriteria: ' num2str(stitchCriteria)], params);
else
    stitchCriteria = params.stitchCriteria;
end

if ~isfield(params, 'numberOfBins')
    numberOfBins = 256; % gray levels
    RevasWarning(['FindBlinkFrames is using default parameter for numberOfBins: ' num2str(numberOfBins)], params);
else
    numberOfBins = params.numberOfBins;
end

if ~isfield(params, 'meanDifferenceThreshold')
    meanDifferenceThreshold = 10; % gray levels
    RevasWarning(['FindBlinkFrames is using default parameter for meanDifferenceThreshold: ' num2str(meanDifferenceThreshold)], params);
else
    meanDifferenceThreshold = params.meanDifferenceThreshold;
end


%% Handle overwrite scenarios.
if writeResult
    badFramesMatFilePath = [inputVideo(1:end-4) '_blinkframes.mat'];
    if nargout > 1 
        varargout{1} = badFramesMatFilePath;
    end
    
    if ~exist(badFramesMatFilePath, 'file')
        % left blank to continue without issuing warning in this case
    elseif ~overwrite
        load(badFramesMatFilePath,'badFrames','imStats','initialRef');
        if nargout > 2
            varargout{2} = imStats;
        end
        if nargout > 3
            varargout{3} = initialRef;
        end
        RevasWarning(['FindBadFrames() did not execute because it would overwrite existing file. (' badFramesMatFilePath ')'], params);
        return;
    else
        RevasWarning(['FindBadFrames() is proceeding and overwriting an existing file. (' badFramesMatFilePath ')'], params);
    end
end





%% Read in video frames and collect some image statistics

if writeResult
    reader = VideoReader(inputVideo);
    numberOfFrames = reader.FrameRate * reader.Duration;
else
    [~, ~, numberOfFrames] = size(inputVideo);
end

means = zeros(numberOfFrames,1);
stds = zeros(numberOfFrames,1);
skews = zeros(numberOfFrames,1);
kurtoses = zeros(numberOfFrames,1);

% go over frames and compute image stats for each frame
for fr = 1:numberOfFrames
    
    % get next frame
    if writeResult
        % handle rgb frames
        frame = readFrame(reader);
        if ndims(frame) == 3
            frame = rgb2gray(frame);
        end
    else
        frame = inputVideo(:, :, fr);
    end
    
    % compute image histogram
    [counts, bins] = imhist(frame, numberOfBins);
    
    % compute image stats from histogram
    numOfPixels = sum(counts);
    means(fr) = sum(bins .* counts) / numOfPixels;
    stds(fr) = sqrt(sum((bins - means(fr)) .^ 2 .* counts) / (numOfPixels-1));
    skews(fr) = sum((bins - means(fr)) .^ 3 .* counts) / ((numOfPixels - 1) * stds(fr)^3);
    kurtoses(fr) = sum((bins - means(fr)) .^ 4 .* counts) / ((numOfPixels - 1) * stds(fr)^4);
end


%% Identify bad frames

% use all image stats to detect 2 clusters
[idx, centroids] = kmeans([means stds skews kurtoses],2);

% if centroids are too close, no blinks found.
if abs(diff(centroids(:,1))) < meanDifferenceThreshold
    badFrames = [];
else
    % select the cluster with smaller mean as the bad frames
    [~,whichClusterRepresentsBadFrames] = min(centroids(:,2));
    badFrames = idx == whichClusterRepresentsBadFrames;
    
    % Lump together blinks that are < |stitchCriteria| frames apart
    [st, en] = GetOnsetOffset(badFrames);
    [st, en] = MergeEvents(st, en, stitchCriteria);
    
    % note that we keep badFrames in a logical array format to preserve the
    % length of the original video.
    badFrames = GetIndicesFromOnsetOffset(st,en,numberOfFrames);
end


%% Return image stats if user asks for it or results are to be written to a file

if nargout > 2 || writeResult
    imStats = struct;
    imStats.means = means;
    imStats.stds = stds;
    imStats.skews = skews;
    imStats.kurtoses = kurtoses;
    varargout{2} = imStats;
end


%% If user asks for it or results are to be written to a file, get a candidate frame for initial ref

if nargout > 3 || writeResult
    [~,initialRef] = max(means);
    varargout{3} = initialRef;
end


%% Save to output mat file

if writeResult
    save(badFramesMatFilePath, 'badFrames','imStats','initialRef');
end


%% if verbosity enabled, show the found blink frames

if enableVerbosity
    % Plotting bottom right corner of box surrounding stimulus.
    if all(ishandle(axesHandles))
        axes(axesHandles(2)); 
        colormap(axesHandles(2), 'default');
    else
        figure(312);
    end
    cla;
    plot(means,'-','linewidth',2); hold on;
    plot(stds,'-','linewidth',2);
    plot(skews,'-','linewidth',2);
    plot(kurtoses,'-','linewidth',2); 
    plot(badFrames * max(kurtoses),'-k','linewidth',2); hold on;
    
    title('Image stats and detected blink frames');
    xlabel('Frame number');
    ylabel('Image stats');
    legend('show');
    legend('means', 'stds','skews','kurtoses','badFrames');
    set(gca,'fontsize',14);
    grid on;
    drawnow;
end


