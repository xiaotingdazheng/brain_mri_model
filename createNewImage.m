function [pathDirSyntheticImages, pathDirSyntheticLabels] = createNewImage(pathTrainingLabels, classesStats,...
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

% define resolutions of created images
refImageMRI = MRIread(pathRefImage, 1);
refImageRes = [refImageMRI.xsize refImageMRI.ysize refImageMRI.zsize];
minTargetRes = min(refImageRes)*ones(1,3);

% names of naming variables
trainingBrainNum = findBrainNum(pathTrainingLabels);
if refImageRes(1) == refImageRes(2) && refImageRes(1) == refImageRes(3)
    isFinalImageAnisotropic = 0;
    resolution = num2str(refImageRes(1),'%.1f');
else
    isFinalImageAnisotropic = 1;
    resolution = [num2str(refImageRes(1),'%.1f'), 'x',num2str(refImageRes(2),'%.1f'), 'x',num2str(refImageRes(3),'%.1f')];
end

% paths synthetic directories
pathDirSyntheticImages = fullfile(pathTempImageSubfolder, 'floating_images');
pathDirSyntheticLabels = fullfile(pathTempImageSubfolder, 'floating_labels');
if ~exist(pathDirSyntheticImages, 'dir'), mkdir(pathDirSyntheticImages); end
if ~exist(pathDirSyntheticLabels, 'dir'), mkdir(pathDirSyntheticLabels); end

% paths synthetic image and labels
pathNewImage = fullfile(pathDirSyntheticImages, ['training_' trainingBrainNum '_synthetic_' resolution '.nii.gz']);
pathNewSegmMap = fullfile(pathDirSyntheticLabels, ['training_' trainingBrainNum '_labels_' resolution '.nii.gz']);


if recompute || ~exist(pathNewImage, 'file') || ~exist(pathNewSegmMap, 'file')
    
    disp(['% creating new image from training ' trainingBrainNum ' labels'])
    
    % read training labels and corresponding resolution
    trainingLabelsMRI = MRIread(pathTrainingLabels);
    trainingLabelsRes = [trainingLabelsMRI.xsize trainingLabelsMRI.ysize trainingLabelsMRI.zsize];
    
    % create new image by sampling from intensity prob distribution
    newImage = sampleIntensities(trainingLabelsMRI.vol, labelsList, labelClasses, classesStats, refImageRes, trainingLabelsRes);
    % blur and save isotropic image
    blurAndSave(newImage, trainingLabelsMRI, trainingLabelsRes, minTargetRes, pathNewImage, trainingLabelsMRI.vol)
    % save image and labels at target resolution
    downsample(pathNewImage, pathNewSegmMap, trainingLabelsMRI.fspec, pathFirstLabels, pathRefImage, refImageRes, minTargetRes, isFinalImageAnisotropic, freeSurferHome);
    
    if isFinalImageAnisotropic
        
        disp('% converting to anisotropic image')
        
        % reformate labels if they are anisotropic
        pathRegisteredTrainingLabels = rigidlyRegisterTrainingLabels(pathNewImage, pathTrainingLabels, pathRefImage, pathTempImageSubfolder, refImageRes, niftyRegHome, debug);
        % read training labels
        registeredTrainingLabelsMRI = MRIread(pathRegisteredTrainingLabels);
        anisotropicTrainingLabelsRes = [registeredTrainingLabelsMRI.xsize registeredTrainingLabelsMRI.ysize registeredTrainingLabelsMRI.zsize];
        
        % create new image by sampling from intensity prob distribution
        newImage = sampleIntensities(registeredTrainingLabelsMRI.vol, labelsList, labelClasses, classesStats, refImageRes, anisotropicTrainingLabelsRes);
        % blurring images
        blurAndSave(newImage, registeredTrainingLabelsMRI, anisotropicTrainingLabelsRes, refImageRes, pathNewImage, registeredTrainingLabelsMRI.vol);
        % downsample to target resolution
        downsample(pathNewImage, pathNewSegmMap, registeredTrainingLabelsMRI.fspec, pathFirstLabels, pathRefImage, refImageRes, refImageRes, 0, freeSurferHome);
        
    end
    
else
    
    disp(['% loading image generated from training ' trainingBrainNum ' labels'])
    
end

end

function new_image = sampleIntensities(labels, labelsList, labelClasses, classesStats, sampledImageRes, newImageRes)

disp('generating voxel intensities');

new_image = zeros(size(labels), 'single');
uniqueClasses = unique(labelClasses);
scalingFactor = sqrt(prod(sampledImageRes)/prod(newImageRes));

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
        new_image(voxelIndices) = classesStats(2,classLabel) + classesStats(4,classLabel)*scalingFactor*randn(size(voxelIndices)); %generate new values for these voxels
    end
    
end
new_image(new_image <0) = 0;

end

function blurAndSave(new_image, labelsMRI, inputImageRes, targetRes, pathNewImage, labels)

% initialisation 
disp('blurring image to prevent alliasing');

dilateShape = zeros(3,3,3); 
dilateShape(2,2,2)=1;
dist = bwdist(dilateShape);
dilateShape(dist<=1)=1;
imageMask = imdilate(imfill(labels > 0, 'holes'), dilateShape);

f = targetRes./inputImageRes;
sigmaFilt = 0.9*f; sigmaFilt([1 2]) = sigmaFilt([2 1]);
pixdim = [1 1 1];

% blurring images
new_image = GaussFilt3dMask(new_image, imageMask, sigmaFilt, pixdim); %new blurring
new_image(new_image<0)=0;

% save temporary image (at sampling resolution)
disp('writting created high resolution image');
labelsMRI.vol = new_image;
MRIwrite(labelsMRI, pathNewImage); %write a new nifti file.

end

function downsample(pathNewImage, pathNewSegmMap, pathOldLabels, pathFirstLabels, pathRefImage, refImageRes, targetRes, anisotropicFinalImage, freeSurferHome)

disp('dowmsampling to target resolution');

setFreeSurfer(freeSurferHome);

strTargetRes = [num2str(targetRes(1),'%.1f') ' ' num2str(targetRes(2),'%.1f') ' ' num2str(targetRes(3),'%.1f')];
strRefImageRes = [num2str(refImageRes(1),'%.1f') ' ' num2str(refImageRes(2),'%.1f') ' ' num2str(refImageRes(3),'%.1f')];

% save image and labels at target resolution
if ~isequal(strRefImageRes, strTargetRes) || anisotropicFinalImage
    cmd1 = ['mri_convert ' pathNewImage ' ' pathNewImage ' -voxsize ' strTargetRes ' -rt cubic -odt float']; % downsample at target resolution
    [~,~] = system(cmd1);
    if ~anisotropicFinalImage
        cmd2 = ['mri_convert ' pathOldLabels ' ' pathNewSegmMap ' -voxsize ' strTargetRes ' -rt nearest -odt float']; % same for labels
        [~,~] = system(cmd2);
    end
else
    cmd1 = ['mri_convert ' pathNewImage ' ' pathNewImage ' -rl ' pathRefImage ' -rt cubic -odt float']; % downsample like template image
    [~,~] = system(cmd1);
    cmd2 = ['mri_convert ' pathOldLabels ' ' pathNewSegmMap ' -rl ' pathFirstLabels ' -rt nearest -odt float']; % same for labels
    [~,~] = system(cmd2);
end

end

function pathRegisteredTrainingLabels = rigidlyRegisterTrainingLabels(pathNewImage, pathTrainingLabels, pathRefImage, pathTempImageSubfolder, ...
    refImageRes, niftyRegHome, debug)

% define naming variables
refBrainNum = findBrainNum(pathRefImage);
floBrainNum = findBrainNum(pathNewImage);
highRes = num2str(min(refImageRes)/2,'%.1f');
voxsizeTrainingLabelsHighRes = repmat([highRes ' '], 1, 3);
% paths registration functions
pathRegAladin = fullfile(niftyRegHome, 'reg_aladin');
pathRegResample = fullfile(niftyRegHome, 'reg_resample');

% define paths
aff = '/tmp/temp.aff';
pathTempRegisteredImage = '/tmp/temp_registered_anisotropic.nii.gz';
pathTempRegisteredImageHR = strrep(pathTempRegisteredImage, 'anisotropic.nii.gz', 'isotropic.high_res.nii.gz');
pathRegisteredTrainingLabelsSubfolder = fullfile(pathTempImageSubfolder, 'registered_training_labels');
pathRegisteredTrainingLabels = fullfile(pathRegisteredTrainingLabelsSubfolder, ['training_' floBrainNum '_labels_' highRes '_reg_to_' refBrainNum '.nii.gz']);
if ~exist(pathRegisteredTrainingLabelsSubfolder, 'dir'), mkdir(pathRegisteredTrainingLabelsSubfolder); end

% linear registration
cmd = [pathRegAladin ' -ref ' pathRefImage ' -flo ' pathNewImage ' -res ' pathTempRegisteredImage ' -aff ' aff ' -ln 4 -lp 3 -rigOnly -pad 0'];
if debug, system(cmd); else, cmd = [cmd ' -voff']; [~,~] = system(cmd); end

% make it full with zeros
cmd = ['mri_binarize --i ' pathTempRegisteredImage ' --o ' pathTempRegisteredImage ' --max -Inf'];
[~,~] = system(cmd);

% upsample to high resolution
cmd = ['mri_convert ' pathTempRegisteredImage ' ' pathTempRegisteredImageHR ' --voxsize ' voxsizeTrainingLabelsHighRes];
[~,~] = system(cmd);

% apply linear transformation to labels
cmd = [pathRegResample ' -ref ' pathTempRegisteredImageHR ' -flo ' pathTrainingLabels ' -trans ' aff ' -res ' pathRegisteredTrainingLabels ' -pad 0 -inter 0'];
if debug, system(cmd); else, cmd = [cmd ' -voff']; [~,~] = system(cmd); end

end