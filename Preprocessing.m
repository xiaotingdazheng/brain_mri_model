clear

% pathDirLabels = '/home/benjamin/data/CobraLab/original_labels/*nii.gz';
% pathDirSupport = '/home/benjamin/data/CobraLab/hippocampus_labels/*nii.gz'; % hippo labels
pathDirLabels = '/home/benjamin/data/OASIS/labels/original_labels/*nii.gz';
pathDirSupport = '/home/benjamin/data/OASIS/images/original_images/*nii.gz'; % images

pathPreprocessedLabelsFolder = '/home/benjamin/data/OASIS/test';

numberOfSmoothing = 2;
targetResolution = [1 1 1]; % optional, to downsample the labels to target resolution directly here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structPathsSupport = dir(pathDirSupport);
structPathsLabels = dir(pathDirLabels);

if ~isempty(regexp(pathDirLabels,'CobraLab', 'once')), dataType = 'CobraLab'; else, dataType = 'Oasis'; end

if isequal(dataType, 'CobraLab')
    for i=1:length(structPathsSupport)
        disp(['%% processing ' structPathsLabels(i).name])
        pathHipppoLabels = fullfile(structPathsSupport(i).folder, structPathsSupport(i).name);
        pathLabels = fullfile(structPathsLabels(i).folder, structPathsLabels(i).name);
        CobraLabPreProcessing(pathLabels, pathHipppoLabels, numberOfSmoothing, pathPreprocessedLabelsFolder, targetResolution);
        disp(' ');
    end
    
elseif isequal(dataType, 'Oasis')
    for i=1:length(structPathsSupport)
        disp(['%% processing ' structPathsLabels(i).name])
        pathImage = fullfile(structPathsSupport(i).folder, structPathsSupport(i).name);
        pathLabels = fullfile(structPathsLabels(i).folder, structPathsLabels(i).name);
        OASISpreProcessing(pathLabels, pathImage, numberOfSmoothing, pathPreprocessedLabelsFolder);
        disp(' ');
    end
end