function cellPathDirTrainingData = copyTrainingData(pathDirTrainingData, pathTempImFolder, refBrainNum, nChannel)

cellPathDirTrainingData = cell(1,nChannel);

% create temp test image subfolder
pathTrainingDataFolder = fileparts(pathDirTrainingData{1});
[~,name,~] = fileparts(pathTrainingDataFolder);
name = strrep(name, '_t1', ''); name = strrep(name, '_t2', '');
newPathDirTrainingData = fullfile(pathTempImFolder, name);
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