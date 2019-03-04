function newPathDirTrainingData = copyTrainingData(pathDirTrainingData, refBrainNum)

% create temp test image subfolder
pathTrainingDataFolder = fileparts(pathDirTrainingData);
[mainFolder,name,~] = fileparts(pathTrainingDataFolder);
pathTempImageSubfolder = fullfile(mainFolder, ['temp_' refBrainNum]);
newPathDirTrainingData = fullfile(pathTempImageSubfolder, name);
if ~exist(pathTempImageSubfolder,'dir'), mkdir(pathTempImageSubfolder); end

% copy all training labels
cmd = ['rm -r ' newPathDirTrainingData];
[~,~] = system(cmd);
cmd = ['cp -r ' pathTrainingDataFolder ' ' newPathDirTrainingData];
[~,~] = system(cmd);

% list all training labels
newPathDirTrainingData = fullfile(newPathDirTrainingData, '*nii.gz');

structPathsTrainingLabels = dir(newPathDirTrainingData);
% remove labels corresponding to test images
for j=1:length(structPathsTrainingLabels)
    if contains(structPathsTrainingLabels(j).name, refBrainNum)
        cmd = ['rm ' fullfile(structPathsTrainingLabels(j).folder, structPathsTrainingLabels(j).name)]; [~,~] = system(cmd);
        break
    end
end

end
