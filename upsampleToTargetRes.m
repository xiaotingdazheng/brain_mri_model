function [pathRefImage, pathRefLabels, brainVoxels, cropping] = upsampleToTargetRes(pathRefImage, pathRefLabels, pathRefFirstLabels, pathTempImFolder, targetRes,...
    multiChannel, margin, recompute, evaluate, cropHippo)

% path upsampled ref folder
if isequal(class(pathRefLabels), 'cell'), pathRefLabels=pathRefLabels{1}; end
if ~multiChannel, brainVoxels = cell(1); end
pathUpsampledRefDataSubfolder = fullfile(pathTempImFolder, 'resampled_test_image_and_labels');
if ~exist(pathUpsampledRefDataSubfolder, 'dir'), mkdir(pathUpsampledRefDataSubfolder); end

if targetRes
    
    disp('resampling ref image at target resolution')
    
    % naming variables
    voxsize = [num2str(targetRes(1),'%.2f') ' ' num2str(targetRes(2),'%.2f') ' ' num2str(targetRes(3),'%.2f')];
    if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3), resolution = num2str(targetRes(1),'%.1f');
    else, resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')]; end
    % paths upsampled data
    temp_pathRefImage = strrep(pathRefImage{end},'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_pathRefImage);
    pathResampledRefImage = fullfile(pathUpsampledRefDataSubfolder, [name '_' resolution '.nii.gz']);
    temp_pathRefLabels = strrep(pathRefLabels,'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_pathRefLabels);
    pathResampledRefLabels = fullfile(pathUpsampledRefDataSubfolder, [name '_' resolution '.nii.gz']);
    
    % upsample ref image
    if ~exist(pathResampledRefImage, 'file') || recompute
        cmd = ['mri_convert ' pathRefImage{end} ' ' pathResampledRefImage ' --voxsize ' voxsize ' -odt float'];
        [~,~] = system(cmd);
    end
    % upsample ref labels
    if evaluate && (~exist(pathResampledRefLabels, 'file') || recompute)
        mri = myMRIread(pathResampledRefImage, 1, pathTempImFolder);
        cropsize = [num2str(mri.volsize(1),'%d'), 'x',num2str(mri.volsize(2),'%d'), 'x',num2str(mri.volsize(3),'%d')];
        cmd = ['mri_convert ' pathRefLabels ' ' pathResampledRefLabels ' --voxsize ' voxsize ' --cropsize ' cropsize ' -odt float -rt nearest'];
        [~,~] = system(cmd);
    end
    % update names
    pathRefImage{end} = pathResampledRefImage;
    pathRefLabels = pathResampledRefLabels;
    
elseif ~any(targetRes) && evaluate
    
    % converting ref labels to nii if needed
    [~,name,ext] = fileparts(pathRefLabels);
    if strcmp(ext,'.mgz')
        pathResampledRefLabels = fullfile(pathUpsampledRefDataSubfolder, [name '.nii.gz']);
        cmd = ['mri_convert ' pathRefLabels ' ' pathResampledRefLabels ' -odt float -rt nearest'];
        [~,~] = system(cmd);
        pathRefLabels = pathResampledRefLabels;
    end
    
end

% crop Hippocampus
if cropHippo
    disp('cropping ref image around hippocampus')
    mri = myMRIread(pathRefFirstLabels{1}, 1, pathTempImFolder);
    [~,cropping] = cropLabelVol(mri, 20, 'hippo');
else
    cropping = 0;
end

% find brain voxels
disp('selecting brain voxels in ref image')
if multiChannel
    brainVoxels = selectBrainVoxels(pathRefImage{end}, margin, pathTempImFolder);
else
    brainVoxels{1} = selectBrainVoxels(pathRefImage{end}, margin, pathTempImFolder);
end

end