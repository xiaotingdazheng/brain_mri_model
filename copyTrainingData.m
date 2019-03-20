function cellPathDirTrainingData = copyTrainingData(pathDirTrainingData, pathTempImFolder, refBrainNum, nChannel, dataType)

cellPathDirTrainingData = cell(1,nChannel);

% create folder where data is going to be copied
newPathDirTrainingData = fullfile(pathTempImFolder, ['training_' dataType]);
if ~exist(newPathDirTrainingData,'dir'), mkdir(newPathDirTrainingData); end

for channel=1:nChannel
    
    % extend path if multi channel
    if nChannel > 1
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
    temp_newPathDirTrainingData = fullfile(temp_newPathDirTrainingData, '*nii.gz');
    cellPathDirTrainingData{channel} = temp_newPathDirTrainingData;

    structPathsTrainingLabels = dir(temp_newPathDirTrainingData);
    % remove labels corresponding to test images
    for j=1:length(structPathsTrainingLabels)
        if contains(structPathsTrainingLabels(j).name, refBrainNum)
            cmd = ['rm ' fullfile(structPathsTrainingLabels(j).folder, structPathsTrainingLabels(j).name)]; [~,~] = system(cmd);
            break
        end
    end
    
end

end