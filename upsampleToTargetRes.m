function [pathRefImage, pathRefLabels, brainVoxels] = upsampleToTargetRes(pathRefImage, pathRefLabels, targetRes,...
    multiChannel, margin)

voxsize = [num2str(targetRes(1),'%.2f') ' ' num2str(targetRes(2),'%.2f') ' ' num2str(targetRes(3),'%.2f')];
if multiChannel
    pathTempImageSubfolder = fileparts(fileparts(fileparts(pathRefImage{1})));
else
    pathTempImageSubfolder = fileparts(fileparts(pathRefImage{1}));
    brainVoxels = cell(1);
end
pathUpsampledRefDataSubfolder = fullfile(pathTempImageSubfolder, 'upsampled_test_image_and_labels');
if ~exist(pathUpsampledRefDataSubfolder, 'dir'), mkdir(pathUpsampledRefDataSubfolder); end
[~,name,ext] = fileparts(pathRefImage{end});
pathUpsampledRefImage = fullfile(pathUpsampledRefDataSubfolder, [name ext]);
[~,name,ext] = fileparts(pathRefLabels);
pathUpsampledRefLabels = fullfile(pathUpsampledRefDataSubfolder, [name ext]);

% upsample ref image
cmd = ['mri_convert ' pathRefImage{end} ' ' pathUpsampledRefImage ' --voxsize ' voxsize ' -odt float'];
[~,~] = system(cmd);
% mask ref image with nans
maskWithNaNs(pathUpsampledRefImage, pathUpsampledRefImage, pathUpsampledRefImage);

% upsample ref labels
cmd = ['mri_convert ' pathRefLabels ' ' pathUpsampledRefLabels ' --voxsize ' voxsize ' -odt float -rt nearest'];
[~,~] = system(cmd);

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