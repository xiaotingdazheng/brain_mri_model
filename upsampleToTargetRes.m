function [pathRefImage, pathRefLabels, brainVoxels] = upsampleToTargetRes(pathRefImage, pathRefLabels, pathTempImFolder, targetRes,...
    multiChannel, margin, refBrainNum, recompute)

% path upsampled ref folder
if ~multiChannel, brainVoxels = cell(1); end
pathUpsampledRefDataSubfolder = fullfile(pathTempImFolder, 'upsampled_test_image_and_labels');
if ~exist(pathUpsampledRefDataSubfolder, 'dir'), mkdir(pathUpsampledRefDataSubfolder); end

if targetRes
    % naming variables
    voxsize = [num2str(targetRes(1),'%.2f') ' ' num2str(targetRes(2),'%.2f') ' ' num2str(targetRes(3),'%.2f')];
    if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3), resolution = num2str(targetRes(1),'%.1f');
    else, resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')]; end
    % paths upsampled data
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
    mask(pathUpsampledRefImage, pathUpsampledRefImage, pathUpsampledRefImage, 0, NaN, 0, refBrainNum, '', 1, 0);
    % upsample ref labels
    if ~exist(pathUpsampledRefLabels, 'file') || recompute
        cmd = ['mri_convert ' pathRefLabels ' ' pathUpsampledRefLabels ' --voxsize ' voxsize ' -odt float -rt nearest'];
        [~,~] = system(cmd);
    end
    % put back paths of modified images
    pathRefImage{end} = pathUpsampledRefImage;
else
    [~,name,ext] = fileparts(pathRefLabels);
    if strcmp(ext,'.mgz')
        pathUpsampledRefLabels = fullfile(pathUpsampledRefDataSubfolder, [name '.nii.gz']);
        cmd = ['mri_convert ' pathRefLabels ' ' pathUpsampledRefLabels ' -odt float -rt nearest'];
        [~,~] = system(cmd);
    end
end

% put back paths of modified ref labels
pathRefLabels = pathUpsampledRefLabels;

% find brain voxels
if multiChannel
    brainVoxels = selectBrainVoxels(pathRefImage{end}, margin);
else
    brainVoxels{1} = selectBrainVoxels(pathRefImage{end}, margin);
end

end