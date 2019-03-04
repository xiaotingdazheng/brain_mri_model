function [pathDirFloatingImages, pathDirFloatingLabels] = preprocessRealTrainingImages(pathDirTrainingImages, pathDirTrainingLabels, ...
    pathRefImage, targetRes, rescale, recompute, freeSurferHome)

% naming variables
voxsize = [num2str(targetRes(1),'%.1f') ' ' num2str(targetRes(2),'%.1f') ' ' num2str(targetRes(3),'%.1f')];
if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3)
    resolution = num2str(targetRes(1),'%.1f');
else
    resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')];
end
% files handling
structPathsTrainingImages = dir(pathDirTrainingImages);
structPathsTrainingLabels = dir(pathDirTrainingLabels);
pathTempImageSubfolder = fileparts(fileparts(pathRefImage));
% paths floating images/labels directories
pathDirFloatingImages = fullfile(pathTempImageSubfolder, 'floating_images');
pathDirFloatingLabels = fullfile(pathTempImageSubfolder, 'floating_labels');
if ~exist(pathDirFloatingImages, 'dir'), mkdir(pathDirFloatingImages); end
if ~exist(pathDirFloatingLabels, 'dir'), mkdir(pathDirFloatingLabels); end

% downsample image and labels at target resolution
for i=1:length(structPathsTrainingLabels)
    
    % paths training images/labels
    pathTrainingImage = fullfile(structPathsTrainingImages(i).folder, structPathsTrainingImages(i).name);
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    floBrainNum = findBrainNum(pathTrainingLabels);
    pathNewLabels = fullfile(pathDirFloatingLabels, ['training_' floBrainNum '_labels_' resolution '.nii.gz']);
    
    disp(['% preprocessing training ' floBrainNum]);
    
    % rescale and/or mask image
    if rescale
        pathRescaledTrainingImage = rescaleImage(pathTrainingImage, pathDirFloatingImages, recompute);
        disp(['masking ' floBrainNum]);
        pathMaskedTrainingImage = mask(pathRescaledTrainingImage, pathTrainingLabels, pathDirFloatingImages, freeSurferHome);
        pathNewImage = fullfile(pathDirFloatingImages, ['training_' floBrainNum '_real_rescaled_masked_' resolution '.nii.gz']);
        [~,~]=system(['rm ' pathRescaledTrainingImage]); % delete temp image
    else
        disp(['masking ' floBrainNum]);
        pathMaskedTrainingImage = mask(pathTrainingImage, pathTrainingLabels, pathDirFloatingImages, freeSurferHome);
        pathNewImage = fullfile(pathDirFloatingImages, ['training_' floBrainNum '_real_masked_' resolution '.nii.gz']);
    end
    
    % downsample image and labels at target resolution
    if recompute || ~exist(pathNewImage, 'file') || ~exist(pathNewLabels, 'file')
        disp(['downsampling training ' floBrainNum ' to target resolution'])
        setFreeSurfer(freeSurferHome);
        cmd1 = ['mri_convert ' pathMaskedTrainingImage ' ' pathNewImage ' -voxsize ' voxsize ' -rt cubic -odt float'];
        cmd2 = ['mri_convert ' pathTrainingLabels ' ' pathNewLabels ' -voxsize ' voxsize ' -rt nearest -odt float'];
        [~,~] = system(cmd1);
        [~,~] = system(cmd2);
        [~,~] = system(['rm ' pathMaskedTrainingImage]);
    end
    
end

end