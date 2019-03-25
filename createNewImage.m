function [pathNewImage, pathNewLabels] = createNewImage(pathTrainingLabels, classesStats, pathTempImFolder, pathRefImage, ...
    targetRes, labelsList, labelClasses, channel, refBrainNum, recompute, freeSurferHome, niftyRegHome, debug)

% This script generates a synthetic image from a segmentation map and basic
% statistics of intensity distribution for all the regions in the brain.
% For each voxel, we sample a value drawn from the model of the class it
% belongs to (identified thanks to the segmentation map).
% This results in an image of the same resolution as the provided segm map.
% We still need to blur the obtained image before downsample it to the
% desired target resolution, before saving the final result.


% resolutions of ref image
refImageMRI = myMRIread(pathRefImage, 1, pathTempImFolder);
refImageRes = [refImageMRI.xsize refImageMRI.ysize refImageMRI.zsize];
if ~any(targetRes), targetRes = refImageRes; end % set targetRes to refImageRes if specified

% define names of naming variables
trainingBrainNum = findBrainNum(pathTrainingLabels);
if refImageRes(1) == refImageRes(2) && refImageRes(1) == refImageRes(3)
    isFinalImageAnisotropic = 0;
    if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3), resolution = num2str(targetRes(1),'%.1f'); 
    else, resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')]; end
else
    isFinalImageAnisotropic = 1; 
    if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3) && channel
        targetRes = refImageRes;
        resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')];
    else
        resolution = num2str(targetRes(1),'%.1f');
    end
end
minTargetRes = min(targetRes)*ones(1,3); % = targetRes if isotropic

% paths synthetic directories
pathDirSyntheticImages = fullfile(pathTempImFolder, 'floating_images');
pathDirSyntheticLabels = fullfile(pathTempImFolder, 'floating_labels');
if channel
    pathDirSyntheticImages = fullfile(pathDirSyntheticImages, ['channel_' num2str(channel)]);
    pathDirSyntheticLabels = fullfile(pathDirSyntheticLabels, ['channel_' num2str(channel)]);
end
if ~exist(pathDirSyntheticImages, 'dir'), mkdir(pathDirSyntheticImages); end
if ~exist(pathDirSyntheticLabels, 'dir'), mkdir(pathDirSyntheticLabels); end

% paths synthetic image and labels
pathNewImage = fullfile(pathDirSyntheticImages, ['training_' trainingBrainNum '_synthetic_' resolution '.nii.gz']);
pathNewLabels = fullfile(pathDirSyntheticLabels, ['training_' trainingBrainNum '_labels_' resolution '.nii.gz']);

% path registered training labels
pathRegTrainingLabelsSubfolder = fullfile(pathTempImFolder, 'registered_training_labels');
if channel, pathRegTrainingLabelsSubfolder = fullfile(pathRegTrainingLabelsSubfolder, ['channel_' num2str(channel)]); end
pathRegTrainingLabels = fullfile(pathRegTrainingLabelsSubfolder, ['training_' trainingBrainNum '_labels_reg_to_' refBrainNum '.nii.gz']);


if recompute || ~exist(pathNewImage, 'file') || ~exist(pathNewLabels, 'file')
    
    if channel, disp(['% creating channel' num2str(channel) ' image from training ' trainingBrainNum ' labels']);
    else, disp(['% creating image from training ' trainingBrainNum ' labels']); end
    
    % read training labels and corresponding resolution
    trainingLabelsMRI = myMRIread(pathTrainingLabels, 0, pathTempImFolder);
    trainingLabelsRes = [trainingLabelsMRI.xsize trainingLabelsMRI.ysize trainingLabelsMRI.zsize];
    RefToFloAxisMap = findAxis(refImageMRI, trainingLabelsMRI);
    
    if isFinalImageAnisotropic == 0 || (isFinalImageAnisotropic && ~exist(pathRegTrainingLabels, 'file')) || recompute
        % create new image by sampling from intensity prob distribution
        newImage = sampleIntensities(trainingLabelsMRI.vol, labelsList, labelClasses, classesStats, refImageRes, trainingLabelsRes);
        % blur and save isotropic image
        blurAndSave(newImage, trainingLabelsMRI, trainingLabelsRes, minTargetRes, pathNewImage, trainingLabelsMRI.vol, RefToFloAxisMap, pathTempImFolder)
        % save image and labels at target resolution
        downsample(pathNewImage, pathNewLabels, trainingLabelsMRI.fspec, minTargetRes, isFinalImageAnisotropic, RefToFloAxisMap, freeSurferHome);
    end
    
    if isFinalImageAnisotropic
        
        % reformate labels if they are anisotropic
        pathRegTrainingLabels = rigidlyRegisterTrainingLabels(pathNewImage, pathTrainingLabels, pathRefImage, pathTempImFolder, ...
            channel, refBrainNum, niftyRegHome, debug, recompute);
        % read training labels
        regTrainingLabelsMRI = myMRIread(pathRegTrainingLabels, 0, pathTempImFolder);
        regTrainingLabelsRes = [regTrainingLabelsMRI.xsize regTrainingLabelsMRI.ysize regTrainingLabelsMRI.zsize];
        RefToFloAxisMap = findAxis(refImageMRI, regTrainingLabelsMRI);
        
        % create new image by sampling from intensity prob distribution
        newImage = sampleIntensities(regTrainingLabelsMRI.vol, labelsList, labelClasses, classesStats, refImageRes, regTrainingLabelsRes);
        % blurring images
        blurAndSave(newImage, regTrainingLabelsMRI, regTrainingLabelsRes, targetRes, pathNewImage, regTrainingLabelsMRI.vol, RefToFloAxisMap, pathTempImFolder);
        % downsample to target resolution
        downsample(pathNewImage, pathNewLabels, regTrainingLabelsMRI.fspec, targetRes, 0, RefToFloAxisMap, freeSurferHome);
        
    end
    
else
    
    if channel, disp(['% channel' num2str(channel) ' image from training ' trainingBrainNum ' labels already generated']);
    else, disp(['% image from training ' trainingBrainNum ' labels already generated']); end
    
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
    if isnan(mean(mean(classesStats,'omitnan'),'omitnan')), error('only nans intensities'); end
    while isnan(classesStats(2,classLabel)) || isnan(classesStats(4,classLabel))
        classLabel = randi(size(classesStats, 2));
    end
    
    % sample from prob distribution lC
    for l=1:length(labelsBelongingToClass)
        voxelIndices = find(labels == labelsBelongingToClass(l)); %find voxels with label l
        new_image(voxelIndices) = classesStats(2,classLabel) + classesStats(4,classLabel)*scalingFactor*randn(size(voxelIndices)); %generate new values
    end
    
end
new_image(new_image <0) = 0;

end

function blurAndSave(new_image, labelsMRI, inputImageRes, targetRes, pathNewImage, labels, RefToFloAxisMap, pathTempImFolder)

% initialisation 
disp('blurring image to prevent alliasing');

dilateShape = zeros(3,3,3); 
dilateShape(2,2,2)=1;
dist = bwdist(dilateShape);
dilateShape(dist<=1)=1;
imageMask = imdilate(imfill(labels > 0, 'holes'), dilateShape);

f = targetRes./inputImageRes;
sigmaFilt = 0.9*f;
sigmaFilt([1 2 3]) = sigmaFilt(RefToFloAxisMap);
sigmaFilt([1 2]) = sigmaFilt([2 1]);
pixdim = [1 1 1];

% blurring images
new_image = GaussFilt3dMask(new_image, imageMask, sigmaFilt, pixdim); %new blurring
new_image(new_image<0)=0;

% save temporary image (at sampling resolution)
disp('writting created high resolution image');
labelsMRI.vol = new_image;
myMRIwrite(labelsMRI, pathNewImage, 'float', pathTempImFolder); %write a new nifti file.

end

function downsample(pathNewImage, pathNewSegmMap, pathOldLabels, targetRes, anisotropicFinalImage, RefToFloAxisMap, freeSurferHome)

disp('dowmsampling to target resolution');

setFreeSurfer(freeSurferHome);

targetRes([1 2 3]) = targetRes(RefToFloAxisMap);
strTargetRes = [num2str(targetRes(1),'%.2f') ' ' num2str(targetRes(2),'%.2f') ' ' num2str(targetRes(3),'%.2f')];

% save image and labels at target resolution
cmd1 = ['mri_convert ' pathNewImage ' ' pathNewImage ' -voxsize ' strTargetRes ' -rt cubic -odt float']; % downsample at target resolution
[~,~] = system(cmd1);
if ~anisotropicFinalImage
    cmd2 = ['mri_convert ' pathOldLabels ' ' pathNewSegmMap ' -voxsize ' strTargetRes ' -rt nearest -odt float']; % same for labels
    [~,~] = system(cmd2);
end

end

function pathRegTrainingLabels = rigidlyRegisterTrainingLabels(pathNewImage, pathTrainingLabels, pathRefImage, pathTempImageSubfolder, ...
    channel, refBrainNum, niftyRegHome, debug, recompute)

% define naming variables
floBrainNum = findBrainNum(pathNewImage);
% paths registration functions
pathRegAladin = fullfile(niftyRegHome, 'reg_aladin');
pathRegResample = fullfile(niftyRegHome, 'reg_resample');
% path rigid transformation
pathRigidTransFolder = fullfile(pathTempImageSubfolder, 'rigid_transformations');
aff = fullfile(pathRigidTransFolder, [floBrainNum '_to_' refBrainNum '.aff']);
if ~exist(pathRigidTransFolder, 'dir'), mkdir(pathRigidTransFolder); end
% path registered training labels
pathRegTrainingLabelsSubfolder = fullfile(pathTempImageSubfolder, 'registered_training_labels');
if channel, pathRegTrainingLabelsSubfolder = fullfile(pathRegTrainingLabelsSubfolder, ['channel_' num2str(channel)]); end
pathRegTrainingLabels = fullfile(pathRegTrainingLabelsSubfolder, ['training_' floBrainNum '_labels_reg_to_' refBrainNum '.nii.gz']);
if ~exist(pathRegTrainingLabelsSubfolder, 'dir'), mkdir(pathRegTrainingLabelsSubfolder); end

if ~exist(aff, 'file') || recompute
    disp('registering temporary isotropic image to anistropic test image');
    % linear registration
    res = '/tmp/res.nii.gz';
    cmd = [pathRegAladin ' -ref ' pathRefImage ' -flo ' pathNewImage ' -aff ' aff ' -res ' res ' -ln 4 -lp 3 -rigOnly -pad 0'];
    if debug, system(cmd); else, [~,~] = system(cmd); end
    [~,~]=system(['rm ' res]);
else
    disp('temporary isotropic image already registered to test image')
end

if ~exist(pathRegTrainingLabels, 'file') || recompute
    disp('applying rigid transformation to training labels');
    % apply linear transformation to labels
    cmd = [pathRegResample ' -ref ' pathTrainingLabels ' -flo ' pathTrainingLabels ' -trans ' aff ' -res ' pathRegTrainingLabels ' -pad 0 -inter 0'];
    if debug, system(cmd); else, cmd = [cmd ' -voff']; [~,~] = system(cmd); end
else
    disp('rigid transformation already applied to training labels')
end

end