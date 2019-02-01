function [pathDirFloatingImages, pathDirFloatingLabels] = preprocessTrainingImages(pathRefImage, pathFirstLabels, pathDirTrainingImages, pathDirTrainingLabels,...
    targetResolution, recompute)

% files handling
structPathsTrainingImages = dir(pathDirTrainingImages);
structPathsTrainingLabels = dir(pathDirTrainingLabels);
refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'.nii.gz')-1);
pathTempImageSubfolder = fullfile(fileparts(structPathsTrainingLabels(1).folder), ['temp_' refBrainNum]);
if ~exist(pathTempImageSubfolder, 'dir'), mkdir(pathTempImageSubfolder); end

% create images from stats using training labels
for i=1:length(structPathsTrainingLabels)
    
    disp(['% preprocessing ' structPathsTrainingLabels(i).name])
    pathTrainingImage = fullfile(structPathsTrainingImages(i).folder, structPathsTrainingImages(i).name);
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    [pathDirFloatingImages, pathDirFloatingLabels] = ...
        downsampleTrainingImage(pathTrainingImage, pathTrainingLabels, pathRefImage, pathFirstLabels, targetResolution, pathTempImageSubfolder, recompute);
    
end

end

function [pathDirFloatingImages, pathDirFloatingLabels] = ...
    downsampleTrainingImage(pathTrainingImage, pathTrainingLabels, pathRefImage, pathFirstLabels, targetResolution, pathTempImageSubfolder, recompute)


% name of handled files
if targetResolution(1) == targetResolution(2) && targetResolution(1) == targetResolution(3)
    resolution = num2str(targetResolution(1),'%.1f');
else
    resolution = [num2str(targetResolution(1),'%.1f'), 'x',num2str(targetResolution(2),'%.1f'), 'x',num2str(targetResolution(3),'%.1f')];
end
TrainingBrainNum = pathTrainingLabels(regexp(pathTrainingLabels,'brain'):regexp(pathTrainingLabels,'_labels.nii.gz')-1);
pathDirFloatingImages = fullfile(pathTempImageSubfolder, 'training_images');
if ~exist(pathDirFloatingImages, 'dir'), mkdir(pathDirFloatingImages); end
pathNewImage = fullfile(pathDirFloatingImages, ['training_' TrainingBrainNum '.' resolution '.nii.gz']);
pathDirFloatingLabels = fullfile(pathTempImageSubfolder, 'training_labels');
if ~exist(pathDirFloatingLabels, 'dir'), mkdir(pathDirFloatingLabels); end
pathNewLabels = fullfile(pathDirFloatingLabels, ['training_' TrainingBrainNum '_labels.' resolution '.nii.gz']);
voxsize = [num2str(targetResolution(1),'%.1f') ' ' num2str(targetResolution(2),'%.1f') ' ' num2str(targetResolution(3),'%.1f')];

if recompute || ~exist(pathNewImage, 'file') || ~exist(pathNewLabels, 'file')
    
    % downsample image and labels at target resolution
    disp('downsampling to target resolution ')
    setFreeSurfer();
    refImageMRI = MRIread(pathRefImage);
    refImageRes = [num2str(refImageMRI.xsize,'%.1f') ' ' num2str(refImageMRI.ysize,'%.1f') ' ' num2str(refImageMRI.zsize,'%.1f')];
    if isequal(refImageRes, voxsize)
        cmd1 = ['mri_convert ' pathTrainingImage ' ' pathNewImage ' -voxsize ' voxsize ' -rl ' pathRefImage ' -rt cubic -odt float'];
        cmd2 = ['mri_convert ' pathTrainingLabels ' ' pathNewLabels ' -voxsize ' voxsize ' -rl ' pathFirstLabels ' -rt nearest -odt float'];
    else
        cmd1 = ['mri_convert ' pathTrainingImage ' ' pathNewImage ' -voxsize ' voxsize ' -rt cubic -odt float'];
        cmd2 = ['mri_convert ' pathTrainingLabels ' ' pathNewLabels ' -voxsize ' voxsize ' -rt nearest -odt float'];
    end
    [~,~] = system(cmd1);
    [~,~] = system(cmd2);
    
end

end