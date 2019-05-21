function [pathNewImage, pathNewLabels] = createNewImage(pathTrainingLabels, classesStats, pathTempImFolder, pathRefImage, ...
    targetRes, labelsList, labelClasses, channel, refBrainNum, floBrainNum, recompute, freeSurferHome, niftyRegHome, debug)

% This script generates a synthetic image from a segmentation map and basic
% statistics of intensity distribution for all the regions in the brain.
% For each voxel, we sample a value drawn from the model of the class it
% belongs to (identified thanks to the segmentation map).
% This results in an image of the same resolution as the provided segm map.
% We still need to blur the obtained image before downsample it to the
% desired target resolution, before saving the final result.


% resolution of ref image
refImageMRI = myMRIread(pathRefImage, 1, pathTempImFolder);
refImageRes = [refImageMRI.xsize refImageMRI.ysize refImageMRI.zsize];
if ~any(targetRes), targetRes = refImageRes; end % set targetRes to refImageRes if targetRes isn't specified

% define names of naming variables
if all(refImageRes == refImageRes(1))
    if all(targetRes == targetRes(1)), resolution = num2str(targetRes(1),'%.1f'); 
    else, resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')]; end
else
    if all(targetRes == targetRes(1)) && channel
        %image is synthetised anisotropically (refImageRes) and will then be aligned (rigid registration) with isotropic t1
        targetRes = refImageRes; 
        resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')];
    elseif all(targetRes == targetRes(1))
        resolution = num2str(targetRes(1),'%.1f');
    else
        resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')];
    end
end

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
pathNewImage = fullfile(pathDirSyntheticImages, ['training_' floBrainNum '_synthetic_' resolution '.nii.gz']);
pathNewLabels = fullfile(pathDirSyntheticLabels, ['training_' floBrainNum '_labels_' resolution '.nii.gz']);


if recompute || ~exist(pathNewImage, 'file') || ~exist(pathNewLabels, 'file')
    
    if channel, disp(['% creating channel' num2str(channel) ' image from training ' floBrainNum ' labels']);
    else, disp(['% creating image from training ' floBrainNum ' labels']); end
    
    % read training labels and corresponding resolution
    trainingLabelsMRI = myMRIread(pathTrainingLabels, 0, pathTempImFolder);
    trainingLabelsRes = [trainingLabelsMRI.xsize trainingLabelsMRI.ysize trainingLabelsMRI.zsize];
    RefToFloAxisMap = findAxis(refImageMRI, trainingLabelsMRI);
    
    % create new image by sampling from intensity prob distribution
    newImage = sampleIntensities(trainingLabelsMRI.vol, labelsList, labelClasses, classesStats, refImageRes, trainingLabelsRes);
    % blur and save isotropic image
    blurAndSave(newImage, trainingLabelsMRI, trainingLabelsRes, targetRes, pathNewImage, trainingLabelsMRI.vol, RefToFloAxisMap, pathTempImFolder)
    % rigidly register training labels for other channels
    if channel == 1
        registerLabels(pathNewImage, pathTrainingLabels, pathRefImage, pathTempImFolder, refBrainNum, niftyRegHome, debug, recompute); 
    end
    % downsample image at target res, only in isotropic case
    downsample(pathNewImage, pathNewLabels, pathTrainingLabels, targetRes, RefToFloAxisMap, freeSurferHome);
    
else
    % display massage
    if channel, disp(['% channel' num2str(channel) ' image from training ' floBrainNum ' labels already generated']);
    else, disp(['% image from training ' floBrainNum ' labels already generated']); end
end

end

function newImage = sampleIntensities(labels, labelsList, labelClasses, classesStats, sampledImageRes, newImageRes)

disp('generating voxel intensities');

newImage = zeros(size(labels), 'single');
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
        newImage(voxelIndices) = classesStats(2,classLabel) + classesStats(4,classLabel)*scalingFactor*randn(size(voxelIndices)); %generate new values
    end
    
end
newImage(newImage <0) = 0;

end

function blurAndSave(newImage, labelsMRI, inputImageRes, targetRes, pathNewImage, labels, RefToFloAxisMap, pathTempImFolder)

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
newImage = GaussFilt3dMask(newImage, imageMask, sigmaFilt, pixdim); %new blurring
newImage(newImage<0)=0;

% save temporary image (at sampling resolution)
disp('writting created high resolution image');
labelsMRI.vol = newImage;
myMRIwrite(labelsMRI, pathNewImage, 'float', pathTempImFolder); %write a new nifti file.

end

function downsample(pathNewImage, pathNewSegmMap, pathOldLabels, targetRes, RefToFloAxisMap, freeSurferHome)

disp('downsampling to target resolution');

setFreeSurfer(freeSurferHome);

targetRes([1 2 3]) = targetRes(RefToFloAxisMap);
strTargetRes = [num2str(targetRes(1),'%.2f') ' ' num2str(targetRes(2),'%.2f') ' ' num2str(targetRes(3),'%.2f')];

% save image and labels at target resolution
cmd1 = ['mri_convert ' pathNewImage ' ' pathNewImage ' -voxsize ' strTargetRes ' -rt cubic -odt float']; % downsample at target resolution
[~,~] = system(cmd1);
cmd2 = ['mri_convert ' pathOldLabels ' ' pathNewSegmMap ' -voxsize ' strTargetRes ' -rt nearest -odt float']; % same for labels
[~,~] = system(cmd2);

end

function pathRegTrainingLabels = registerLabels(pathNewImage, pathTrainingLabels, pathRefImage, pathTempImFolder, ...
    refBrainNum, niftyRegHome, debug, recompute)

% define naming variables
floBrainNum = findBrainNum(pathNewImage);
% paths registration functions
pathRegAladin = fullfile(niftyRegHome, 'reg_aladin');
pathRegResample = fullfile(niftyRegHome, 'reg_resample');
% path registered training labels
pathRegTrainingLabelsFolder = fullfile(pathTempImFolder, 'registered_training_labels');
pathRegTrainingLabels = fullfile(pathRegTrainingLabelsFolder, ['training_labels_' floBrainNum '_to_' refBrainNum '.nii.gz']);
if ~exist(pathRegTrainingLabelsFolder, 'dir'), mkdir(pathRegTrainingLabelsFolder); end
% path rigid transformation
aff = fullfile(pathRegTrainingLabelsFolder, ['training_labels_' floBrainNum '_to_' refBrainNum '.aff']);

if ~exist(aff, 'file') || recompute
    disp('registering temporary isotropic image to anistropic test image');
    % linear registration
    cmd = [pathRegAladin ' -ref ' pathRefImage ' -flo ' pathNewImage ' -aff ' aff ' -ln 4 -lp 3 -rigOnly -pad 0'];
    if debug, system(cmd); else, [~,~] = system(cmd); end
else
    disp('temporary isotropic image already registered to test image')
end

if ~exist(pathRegTrainingLabels, 'file') || recompute
    disp('applying rigid transformation to training labels');
    pathPaddedTrainingLabels = '/tmp/paddedTrainingLabels.nii.gz';
    padImage(pathTrainingLabels, pathPaddedTrainingLabels, 170, pathTempImFolder);
    % apply linear transformation to labels
    cmd = [pathRegResample ' -ref ' pathPaddedTrainingLabels ' -flo ' pathPaddedTrainingLabels ' -trans ' aff ' -res ' pathRegTrainingLabels ' -pad 0 -inter 0'];
    if debug, system(cmd); else, cmd = [cmd ' -voff']; [~,~] = system(cmd); end
    [~,~] = system(['rm ' pathPaddedTrainingLabels]);
    mri = myMRIread(pathRegTrainingLabels); [mri,~] = cropLabelVol(mri); myMRIwrite(mri,pathRegTrainingLabels);
else
    disp('rigid transformation already applied to training labels')
end

end