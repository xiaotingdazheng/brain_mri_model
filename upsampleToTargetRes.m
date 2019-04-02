function [pathRefImage, pathRefLabels, brainVoxels, cropping] = upsampleToTargetRes(pathRefImage, pathRefLabels, pathRefFirstLabels, pathTempImFolder, targetRes,...
    multiChannel, margin, refBrainNum, recompute, evaluate, cropHippo)

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
    pathUpsampledRefFirstLabels = fullfile(pathUpsampledRefDataSubfolder, [name '_first_' resolution '.nii.gz']);
    
    % upsample ref image
    if (~exist(pathUpsampledRefImage, 'file') || recompute)
        cmd = ['mri_convert ' pathRefImage{end} ' ' pathUpsampledRefImage ' --voxsize ' voxsize ' -odt float'];
        [~,~] = system(cmd);
    end
    % upsample ref first labels image
    if (~exist(pathUpsampledRefFirstLabels, 'file') || recompute)
        cmd = ['mri_convert ' pathRefFirstLabels{1} ' ' pathUpsampledRefFirstLabels ' --voxsize ' voxsize ' -rt nearest -odt float'];
        [~,~] = system(cmd);
    end
    % mask ref image with nans and put it back in the cell
    mask(pathUpsampledRefImage, pathUpsampledRefImage, pathUpsampledRefImage, 0, NaN, 0, refBrainNum, pathTempImFolder, '', 1, 0, 5);
    pathRefImage{end} = pathUpsampledRefImage;
    pathRefFirstLabels{1} = pathUpsampledRefFirstLabels;
    
    if evaluate
        % upsample ref labels
        if ~exist(pathUpsampledRefLabels, 'file') || recompute
            cmd = ['mri_convert ' pathRefLabels ' ' pathUpsampledRefLabels ' --voxsize ' voxsize ' -odt float -rt nearest'];
            [~,~] = system(cmd);
        end
        pathRefLabels = pathUpsampledRefLabels;
    end
    
elseif ~any(targetRes) && evaluate
    % converting ref labels to nii if needed
    [~,name,ext] = fileparts(pathRefLabels);
    if strcmp(ext,'.mgz')
        pathUpsampledRefLabels = fullfile(pathUpsampledRefDataSubfolder, [name '.nii.gz']);
        cmd = ['mri_convert ' pathRefLabels ' ' pathUpsampledRefLabels ' -odt float -rt nearest'];
        [~,~] = system(cmd);
        % put back paths of modified ref labels
        pathRefLabels = pathUpsampledRefLabels;
    end
    
end

if cropHippo
    mri = myMRIread(pathRefFirstLabels{1});
    [~,cropping] = cropLabelVol(mri, 20, 'hippo');
else
    cropping = 0;
end

% find brain voxels
if multiChannel
    brainVoxels = selectBrainVoxels(pathRefImage{end}, margin, pathTempImFolder);
else
    brainVoxels{1} = selectBrainVoxels(pathRefImage{end}, margin, pathTempImFolder);
end

end