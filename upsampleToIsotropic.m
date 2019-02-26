function [pathNewRefImage, pathNewRefFirstLabels, pathNewRefLabels] = upsampleToIsotropic(pathDirSyntheticImages, pathDirSyntheticLabels,...
    pathRefImage, pathRefFirstLabels, pathRefLabels, targetResolution)

% struct of floating images/labels
structPathsSyntheticImages = dir(pathDirSyntheticImages);
structPathsSyntheticLabels = dir(pathDirSyntheticLabels);
% subfolders of upsampled ref images/labels
pathTempImageSubfolder = fileparts(pathDirSyntheticImages);
pathDirPreprocessedRefImage = fullfile(pathTempImageSubfolder, 'test_image_preprocessed');
pathDirPreprocessedRefLabels = fullfile(pathTempImageSubfolder, 'test_labels_preprocessed');
if ~exist(pathDirPreprocessedRefImage, 'dir'), mkdir(pathDirPreprocessedRefImage); end
if ~exist(pathDirPreprocessedRefLabels, 'dir'), mkdir(pathDirPreprocessedRefLabels); end
% paths of upsampled ref images/labels
[~,name,ext] = fileparts(pathRefImage);
pathNewRefImage = fullfile(pathDirPreprocessedRefImage, [name ext]);
pathNewRefFirstLabels = fullfile(pathDirPreprocessedRefLabels, ['upsampled_first_' name ext]);
pathNewRefLabels = fullfile(pathDirPreprocessedRefLabels, ['upsampled_' name ext]);
% new resolution
isotropicResolutionStr = repmat([num2str(min(targetResolution),'%.1f') ' '], 1, 3);

% upsample ref image
cmd = ['mri_convert ' pathRefImage ' ' pathNewRefImage ' --voxsize ' isotropicResolutionStr ' -rt nearest -odt float'];
[~,~]=system(cmd);
% upsample ref image
cmd = ['mri_convert ' pathRefFirstLabels ' ' pathNewRefFirstLabels ' --voxsize ' isotropicResolutionStr ' -rt nearest -odt float'];
[~,~]=system(cmd);
% upsample ref image
cmd = ['mri_convert ' pathRefLabels ' ' pathNewRefLabels ' --voxsize ' isotropicResolutionStr ' -rt nearest -odt float'];
[~,~]=system(cmd);
% upsample floating images
for i=1:length(structPathsSyntheticImages)
    pathSyntheticImage = fullfile(structPathsSyntheticImages(i).folder, structPathsSyntheticImages(i).name);
    cmd = ['mri_convert ' pathSyntheticImage ' ' pathSyntheticImage ' --voxsize ' isotropicResolutionStr ' -odt float'];
    [~,~]=system(cmd);
end
% upsample floating labels
for i=1:length(structPathsSyntheticLabels)
    pathSyntheticLabels = fullfile(structPathsSyntheticLabels(i).folder, structPathsSyntheticLabels(i).name);
    cmd = ['mri_convert ' pathSyntheticLabels ' ' pathSyntheticLabels ' --voxsize ' isotropicResolutionStr ' -rt nearest -odt float'];
    [~,~]=system(cmd);
end

end