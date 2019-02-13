function [pathDirSyntheticImages, pathDirSyntheticLabels] = createNewImage(pathTrainingLabels, classesStats, targetResolution,...
    pathTempImageSubfolder, pathRefImage, pathFirstLabels, recompute, freeSurferHome, niftyRegHome, debug)

% This script generates a synthetic image from a segmentation map and basic
% statistics of intensity distribution for all the regions in the brain.
% For each voxel, we sample a value drawn from the model of the class it
% belongs to (identified thanks to the segmentation map).
% This results in an image of the same resolution as the provided segm map.
% We still need to blur the obtained image before downsample it to the
% desired target resolution, before saving the final result.

% internal usage of labels and associated classes
labelsList = [  2,3, 4, 5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,...
    53,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
labelClasses = [2,1,12,12,4,3, 7, 8,10,11,12,12, 5,14,15,16, 9, 6,18,13, 2, 1,12,12, 4, 3, 7, 8,10,11,...
    14,15, 9, 6,18,13,17,  2,  2,  2,  2,  2,   14,   14,   14,   14,    2,   14,   14,   14,   14,    2];

% names of naming variables
idx = regexp(pathTrainingLabels,'brain');
TrainingBrainNum = pathTrainingLabels(idx(end):regexp(pathTrainingLabels,'_labels.nii.gz')-1);
voxsize = [num2str(targetResolution(1),'%.1f') ' ' num2str(targetResolution(2),'%.1f') ' ' num2str(targetResolution(3),'%.1f')];
if targetResolution(1) == targetResolution(2) && targetResolution(1) == targetResolution(3)
    resolution = num2str(targetResolution(1),'%.1f');
else
    resolution = [num2str(targetResolution(1),'%.1f'), 'x',num2str(targetResolution(2),'%.1f'), 'x',num2str(targetResolution(3),'%.1f')];
end

% paths synthetic directories
pathDirSyntheticImages = fullfile(pathTempImageSubfolder, 'synthetic_images');
pathDirSyntheticLabels = fullfile(pathTempImageSubfolder, 'synthetic_labels');
if ~exist(pathDirSyntheticImages, 'dir'), mkdir(pathDirSyntheticImages); end
if ~exist(pathDirSyntheticLabels, 'dir'), mkdir(pathDirSyntheticLabels); end

% paths synthetic image and labels
pathNewImage = fullfile(pathDirSyntheticImages, ['training_' TrainingBrainNum '.synthetic.' resolution '.nii.gz']);
pathNewSegmMap = fullfile(pathDirSyntheticLabels, ['training_' TrainingBrainNum '_labels.synthetic.' resolution '.nii.gz']);


if recompute || ~exist(pathNewImage, 'file') || ~exist(pathNewSegmMap, 'file')
    
    disp(['% creating new image from training ' TrainingBrainNum ' labels'])
    
    % read training labels
    labelsMRI = MRIread(pathTrainingLabels);
    labels = labelsMRI.vol;
    
    % create new image by sampling from intensity prob distribution
    disp('generating voxel intensities');
    new_image = sampleIntensities(labels, labelsList, labelClasses, classesStats);
    
    % reformate labels if they are anisotropic
    if ~(targetResolution(1) == targetResolution(2) && targetResolution(1) == targetResolution(3))
        [new_image, labelsMRI] = formateAnisotropicImage(new_image, labelsMRI, pathRefImage, pathTrainingLabels, pathTempImageSubfolder, ...
            labelsList, labelClasses, classesStats, niftyRegHome, debug);
    end
    
    % blurring images
    disp('blurring image to prevent alliasing');
    sampleRes = [labelsMRI.xsize, labelsMRI.ysize, labelsMRI.zsize]; % should be 0.3
    f=targetResolution./sampleRes;
    sigmaFilt=0.9*f;
    new_image = imgaussfilt3(new_image, sigmaFilt); %apply gaussian filter
    
    % save temporary image (at sampling resolution)
    disp('writting created image');
    labelsMRI.vol = new_image;
    MRIwrite(labelsMRI, pathNewImage); %write a new nifti file.
    
    % save image and labels at target resolution
    disp('dowmsampling to target resolution');
    setFreeSurfer(freeSurferHome);
    refImageMRI = MRIread(pathRefImage);
    refImageRes = [num2str(refImageMRI.xsize,'%.1f') ' ' num2str(refImageMRI.ysize,'%.1f') ' ' num2str(refImageMRI.zsize,'%.1f')];
    if isequal(refImageRes, voxsize)
        cmd1 = ['mri_convert ' pathNewImage ' ' pathNewImage ' -voxsize ' voxsize ' -rl ' pathRefImage ' -rt cubic -odt float']; % downsample like template image
        cmd2 = ['mri_convert ' labelsMRI.fspec ' ' pathNewSegmMap ' -voxsize ' voxsize ' -rl ' pathFirstLabels ' -rt nearest -odt float']; % same for labels
    else
        cmd1 = ['mri_convert ' pathNewImage ' ' pathNewImage ' -voxsize ' voxsize ' -rt cubic -odt float']; % downsample like template image
        cmd2 = ['mri_convert ' labelsMRI.fspec ' ' pathNewSegmMap ' -voxsize ' voxsize ' -rt nearest -odt float']; % same for labels
    end
    [~,~] = system(cmd1);
    [~,~] = system(cmd2);
    
else
    
    disp(['% loading image generated from training ' TrainingBrainNum ' labels'])
    
end

end

function new_image = sampleIntensities(labels, labelsList, labelClasses, classesStats)

new_image = zeros(size(labels), 'single');
uniqueClasses = unique(labelClasses);
for lC=1:length(uniqueClasses)
    
    % find labels belonging to class lC
    classLabel = uniqueClasses(lC);
    labelsBelongingToClass = labelsList(labelClasses == classLabel);
    
    % give a random class number to classLabel if it wasn't present in labels we sampled from
    while isnan(classesStats(2,classLabel)) || isnan(classesStats(4,classLabel))
        classLabel = randi(size(classesStats, 2));
    end
    
    % sample from prob distribution lC
    for l=1:length(labelsBelongingToClass)
        voxelIndices = find(labels == labelsBelongingToClass(l)); %find voxels with label l
        new_image(voxelIndices) = classesStats(2,classLabel) + classesStats(4,classLabel)*sqrt(8)*randn(size(voxelIndices)); %generate new values for these voxels
    end
    
end
new_image(new_image <0) = 0;

end

function [new_image, labelsMRI] = formateAnisotropicImage...
    (new_image, labelsMRI, pathRefImage, pathTrainingLabels, pathTempImageSubfolder, labelsList, labelClasses, classesStats, niftyRegHome, debug)

% define naming variables
idx = regexp(pathRefImage,'brain');
refBrainNum = pathRefImage(idx(end):regexp(pathRefImage,'.nii.gz')-1);
temp_pathTrainingLabels = strrep(pathTrainingLabels, '.nii.gz','.mgz');
[~,name,~] = fileparts(temp_pathTrainingLabels);
% paths registration functions
pathRegAladin = fullfile(niftyRegHome, 'reg_aladin');
pathRegResample = fullfile(niftyRegHome, 'reg_resample');
% paths writen files
pathNewImage = '/tmp/temp_anisotropic.nii.gz';
pathTempRegisteredImage = '/tmp/temp_registered_anisotropic.nii.gz';
aff = '/tmp/temp.aff';
pathRegisteredTrainingLabelsSubfolder = fullfile(pathTempImageSubfolder, 'registered_training_labels');
pathRegisteredTrainingLabels = fullfile(pathRegisteredTrainingLabelsSubfolder, [name '.reg_to_' refBrainNum '.nii.gz']);
if ~exist(pathRegisteredTrainingLabelsSubfolder, 'dir'), mkdir(pathRegisteredTrainingLabelsSubfolder); end

%write new image in nifti file.
labelsMRI.vol = new_image;
MRIwrite(labelsMRI, pathNewImage);

% linear registration
cmd = [pathRegAladin ' -ref ' pathRefImage ' -flo ' pathNewImage ' -res ' pathTempRegisteredImage ' -aff ' aff ' -pad 0'];
if debug, system(cmd); else, cmd = [cmd ' -voff']; [~,~] = system(cmd); end

% apply linear transformation to labels
cmd = [pathRegResample ' -ref ' pathTempRegisteredImage ' -flo ' pathTrainingLabels ' -trans ' aff ' -res ' pathRegisteredTrainingLabels ' -pad 0 -inter 0'];
if debug, system(cmd); else, cmd = [cmd ' -voff']; [~,~] = system(cmd); end

% resample new intensities according to newly registered labels
labelsMRI = MRIread(pathRegisteredTrainingLabels);
labels = labelsMRI.vol;
labelsMRI.fspec = pathRegisteredTrainingLabels;
new_image = sampleIntensities(labels, labelsList, labelClasses, classesStats);

end