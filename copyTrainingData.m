function cellPathDirTrainingData = copyTrainingData(pathDirTrainingData, pathTempImFolder, refBrainNum, nChannel, dataType, freeSurferHome, recompute, leaveOneOut)

cellPathDirTrainingData = cell(1,nChannel);
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end

% create folder where data is going to be copied
newPathDirTrainingData = fullfile(pathTempImFolder, ['training_' dataType]);
if ~exist(newPathDirTrainingData,'dir'), mkdir(newPathDirTrainingData); end

for channel=1:nChannel
    
    % extend path if multi channel
    if multiChannel
        temp_newPathDirTrainingData = fullfile(newPathDirTrainingData, ['channel_' num2str(channel)]);
    else 
        temp_newPathDirTrainingData = newPathDirTrainingData;
    end
    
    % copy all training labels
    cmd = ['rm -r ' temp_newPathDirTrainingData];
    [~,~] = system(cmd);
    pathTrainingDataFolder = fileparts(pathDirTrainingData{channel});
    cmd = ['cp -r ' pathTrainingDataFolder ' ' temp_newPathDirTrainingData];
    [~,~] = system(cmd);

    % list all training labels
    temp_newPathDirTrainingData = fullfile(temp_newPathDirTrainingData, '*gz');
    cellPathDirTrainingData{channel} = temp_newPathDirTrainingData;

    structPathsTrainingLabels = dir(temp_newPathDirTrainingData);
    % remove labels corresponding to test images
    for j=1:length(structPathsTrainingLabels)
        temp_pathTrainingData = fullfile(structPathsTrainingLabels(j).folder, structPathsTrainingLabels(j).name);
        temp_brainNum = findBrainNum(temp_pathTrainingData);
        if strcmp(temp_brainNum, refBrainNum) && leaveOneOut
            cmd = ['rm ' temp_pathTrainingData]; [~,~] = system(cmd);
            continue
        end
        floBrainNum = findBrainNum(temp_pathTrainingData);
        mgz2nii(temp_pathTrainingData, 'same', 1, dataType, channel*multiChannel, floBrainNum, freeSurferHome, recompute);
    end
    
end

end