function [pathRefImage, pathRefLabels, brainVoxels] = upsampleToTargetRes(pathRefImage, pathRefLabels, targetRes,...
    multiChannel, margin)

voxsize = [num2str(targetRes(1),'%.2f') ' ' num2str(targetRes(2),'%.2f') ' ' num2str(targetRes(3),'%.2f')];
if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3), resolution = num2str(targetRes(1),'%.1f');
else, resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')]; end
if multiChannel
    pathTempImageSubfolder = fileparts(fileparts(fileparts(pathRefImage{1})));
else
    pathTempImageSubfolder = fileparts(fileparts(pathRefImage{1}));
    brainVoxels = cell(1);
end
pathUpsampledRefDataSubfolder = fullfile(pathTempImageSubfolder, 'upsampled_test_image_and_labels');
if ~exist(pathUpsampledRefDataSubfolder, 'dir'), mkdir(pathUpsampledRefDataSubfolder); end
temp_pathRefImage = strrep(pathRefImage{end},'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_pathRefImage);
pathUpsampledRefImage = fullfile(pathUpsampledRefDataSubfolder, [name '_' resolution '.nii.gz']);
temp_pathRefLabels = strrep(pathRefLabels,'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_pathRefLabels);
pathUpsampledRefLabels = fullfile(pathUpsampledRefDataSubfolder, [name '_' resolution '.nii.gz']);

% upsample ref image
if ~exist(pathUpsampledRefImage, 'file') || recompute
    cmd = ['mri_convert ' pathRefImage{end} ' ' pathUpsampledRefImage ' --voxsize ' voxsize ' -odt float'];
    [~,~] = system(cmd);
end
% mask ref image with nans
mask(pathUpsampledRefImage, pathUpsampledRefImage, pathUpsampledRefImage, 0, NaN, 0, '', 1, 0);

% upsample ref labels
if ~exist(pathUpsampledRefLabels, 'file') || recompute
    cmd = ['mri_convert ' pathRefLabels ' ' pathUpsampledRefLabels ' --voxsize ' voxsize ' -odt float -rt nearest'];
    [~,~] = system(cmd);
end

% put back paths of modified images
pathRefImage{end} = pathUpsampledRefImage;
pathRefLabels = pathUpsampledRefLabels;

% find brain voxels
if multiChannel
    brainVoxels = selectBrainVoxels(pathRefImage{end}, margin);
else
    brainVoxels{1} = selectBrainVoxels(pathRefImage{end}, margin);
end

end