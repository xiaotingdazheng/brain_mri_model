pathDirLabels = '/home/benjamin/data/CobraLab/original_labels/*nii.gz';
pathDirSupport = '/home/benjamin/data/CobraLab/hippocampus_labels/*nii.gz'; % hippo labels
% pathDirLabels = '/home/benjamin/data/OASIS/original_labels/*nii.gz';
% pathDirSupport = '/home/benjamin/data/OASIS/original_images/*nii.gz'; % images

pathPreprocessedLabelsFolder = '/home/benjamin/data/OASIS/label_fusion/training_labels';

numberOfSmoothing = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structPathsSupport = dir(pathDirSupport);
structPathsLabels = dir(pathDirLabels);

if ~isempty(regexp(pathDirLabels,'CobraLab', 'once')), dataType = 'CobraLab'; else, dataType = 'Oasis'; end

if isequal(dataType, 'CobraLab')
    for i=1:length(structPathsSupport)
        disp(['%% processing ' structPathsLabels(i).name])
        pathHipppoLabels = fullfile(structPathsSupport(i).folder, structPathsSupport(i).name);
        pathLabels = fullfile(structPathsLabels(i).folder, structPathsLabels(i).name);
        CobraLabPreProcessing(pathLabels, pathHipppoLabels, numberOfSmoothing, pathPreprocessedLabelsFolder);
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