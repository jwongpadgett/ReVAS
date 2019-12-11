function success = Tester_GammaCorrect

% suppress warnings
origState = warning;
warning('off','all');


try
    %% read in sample video
    
    % the video resides under /testing folder.
    inputVideo = 'tslo-dark.avi';

    str = which(inputVideo);
    if isempty(str)
        success = false;
        return;
    else
        [filepath,name,ext] = fileparts(str);
        inputVideo = [filepath filesep inputVideo];
    end    
    
    %% First test
    % use default params
    p = struct; 
    p.overwrite = true;

    % test with a video path with default settings 
    outputVideoPath = GammaCorrect(inputVideo, p); %#ok<*ASGLU>
    
    %% Second test
    % test with a video array
    videoArray = ReadVideoToArray(inputVideo);
    
    % assume some of the frames were bad
    clear p;
    p = struct;
    p.overwrite = true;
    p.method = 'histEq';
    p.badFrames = false(1,size(videoArray,3));
    p.badFrames([1 3]) = true;

    outputVideo = GammaCorrect(videoArray,p); %#ok<*NASGU>
    
    assert(size(videoArray,3) - size(outputVideo,3) == sum((p.badFrames)));
    
    %% Third test
    p.badFrames = false(7,1); % intentionally out of bounds
    p.badFrames([2 4 6]) = true;
    p.method = 'toneMapping';
    [toneCurve, p.toneCurve] = GetToneCurve(31,1.6,200);
    outputVideo2 = GammaCorrect(videoArray,p);
    
    success = true;
    
    %% cleanup
    delete(outputVideoPath);

catch 
    success = false;
end

warning(origState);

