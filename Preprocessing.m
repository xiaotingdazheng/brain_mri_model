pathDirLabels = '/home/benjamin/data/CobraLab/original_labels/*nii.gz';
pathDirHipppoLabels = '/home/benjamin/data/CobraLab/hippocampus_labels/*nii.gz';

structPathsHipppoLabels = dir(pathDirHipppoLabels);
structPathsLabels = dir(pathDirLabels);

pathPreprocessedLabelsFolder = '/home/benjamin/data/OASIS/label_fusion/training_labels';

numberOfSmoothing = 2;

for i=1:length(structPathsHipppoLabels)
    
    pathHipppoLabels = fullfile(structPathsHipppoLabels(i).folder, structPathsHipppoLabels(i).name);
    pathLabels = fullfile(structPathsLabels(i).folder, structPathsLabels(i).name);

    CobraLabPreProcessing(pathLabels, pathHipppoLabels, numberOfSmoothing, pathPreprocessedLabelsFolder);

end