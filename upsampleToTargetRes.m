function [pathRefImage, pathRefLabels, brainVoxels, cropping] = upsampleToTargetRes(pathRefImage, pathRefLabels, pathRefFirstLabels, pathTempImFolder, targetRes,...
    multiChannel, margin, recompute, evaluate, cropHippo)

% path upsampled ref folder
if isequal(class(pathRefLabels), 'cell'), pathRefLabels=pathRefLabels{1}; end
if ~multiChannel, brainVoxels = cell(1); end
pathUpsampledRefDataSubfolder = fullfile(pathTempImFolder, 'resampled_test_image_and_labels');
if ~exist(pathUpsampledRefDataSubfolder, 'dir'), mkdir(pathUpsampledRefDataSubfolder); end

if targetRes
    
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
        disp('resampling test image at target resolution')
        cmd = ['mri_convert ' pathRefImage{end} ' ' pathResampledRefImage ' --voxsize ' voxsize ' -odt float'];
        [~,~] = system(cmd);
    end
    % upsample ref labels
    if evaluate && (~exist(pathResampledRefLabels, 'file') || recompute)
        disp('resampling test labels at target resolution')
        mri = myMRIread(pathResampledRefImage, 1, pathTempImFolder);
        cropsize = [num2str(mri.volsize(2),'%d') ' ' num2str(mri.volsize(1),'%d') ' ' num2str(mri.volsize(3),'%d')];
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
    if targetRes
        % upsample ref first labels
        temp_pathRefFirstLabels = strrep(pathRefFirstLabels{1},'.nii.gz','.mgz'); [~,name,~] = fileparts(temp_pathRefFirstLabels);
        pathResampledRefFirstLabels = fullfile(pathUpsampledRefDataSubfolder, [name '_' resolution '.nii.gz']);
        if ~exist(pathResampledRefFirstLabels, 'file') || recompute
            disp('upsampling first ref labels to target res');
            cmd = ['mri_convert ' pathRefFirstLabels{1} ' ' pathResampledRefFirstLabels ' --voxsize ' voxsize ' -rt nearest -odt float'];
            [~,~] = system(cmd);
        end
    end
    % crop hippo with upsampled first labels
    disp('cropping ref image around hippocampus')
    mri = myMRIread(pathResampledRefFirstLabels, 0, pathTempImFolder);
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