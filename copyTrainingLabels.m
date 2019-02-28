function copyTrainingLabels(pathDirTrainingLabels, refBrainNum)

% create temp test image subfolder
pathTempImageSubfolder = fullfile(fileparts(fileparts(pathDirTrainingLabels)), ['temp_' refBrainNum]);
if ~exist(pathTempImageSubfolder,'dir'), mkdir(pathTempImageSubfolder); end

% copy all training labels
cmd = ['rm -r ' fullfile(pathTempImageSubfolder, 'training_labels')];
[~,~] = system(cmd);
cmd = ['cp -r ' fileparts(pathDirTrainingLabels) ' ' fullfile(pathTempImageSubfolder, 'training_labels')];
[~,~] = system(cmd);

% list all training labels
temp_pathDirTrainingLabels = fullfile(pathTempImageSubfolder, 'training_labels', '*nii.gz');
temp_structPathsTrainingLabels = dir(temp_pathDirTrainingLabels);

% remove labels corresponding to test images
for j=1:length(temp_structPathsTrainingLabels)
    if contains(temp_structPathsTrainingLabels(j).name, refBrainNum)
        pathRefTrainingLabels = fullfile(temp_structPathsTrainingLabels(j).folder, temp_structPathsTrainingLabels(j).name);
        cmd = ['rm ' pathRefTrainingLabels];
        [~,~] = system(cmd);
        break
    end
end

end