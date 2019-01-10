function new_image = createNewImage(preprocessedLabelsMRI, classesStats, listClassesToGenerate, labelsList, labelClasses, gaussianType, targetRes,...
    pathNewImagesFolder, pathImageResliceLike, brainNum, imageModality, smoothingName)

% This script generates a synthetic image from a segmentation map and basic
% statistics of intensity distribution for all the regions in the brain.
% For each voxel, we sample a value drawn from the model of the class it 
% belongs to (identified thanks to the segmentation map).
% This results in an image of the same resolution as the provided segm map.
% We still need to blur the obtained image before downsample it to the
% desired target resolution, before saving the final result.

preprocessedLabels = preprocessedLabelsMRI.vol;
sampleRes=[preprocessedLabelsMRI.xsize, preprocessedLabelsMRI.ysize, preprocessedLabelsMRI.zsize];

%classesStats: matrix containing stats computed for each class
% 1st row = mean
% 2nd row = median
% 3rd row = standard deviation
% 4th row = 1.4826*median absolute deviation (ie sigmaMAD)

new_image = zeros(size(preprocessedLabels));

for lC=1:length(listClassesToGenerate)
    disp(['generating voxel intensities for class ', num2str(lC)]);
    
    classLabel = listClassesToGenerate(lC);
    labelsBelongingToClass = labelsList(labelClasses == classLabel); %labels belonging to class lC
    for l=1:length(labelsBelongingToClass)
        voxelIndices = find(preprocessedLabels == labelsBelongingToClass(l)); %find voxels with label l
        if strcmp(gaussianType, 'median')
            new_image(voxelIndices) = classesStats(2,classLabel) + classesStats(4,classLabel)*sqrt(8)*randn(size(voxelIndices)); %generate new values for these voxels
        elseif strcmp(gaussianType, 'mean')
            new_image(voxelIndices) = classesStats(1,classLabel) + classesStats(1,classLabel)*sqrt(8)*randn(size(voxelIndices)); %generate new values for these voxels
        else
            error('gaussianType not recognised. Should be "mean" or "median"')
        end
    end
end

% blurring images
disp('blurring image to prevent alliasing');
f=targetRes./sampleRes;
sigmaFilt=0.9*f;
new_image = imgaussfilt3(new_image, sigmaFilt); %apply gaussian filter

disp('writting created image');
preprocessedLabelsMRI.vol = new_image;

% names of created files (image and segmentation)
if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3)
    resolution = num2str(targetRes(1),'%.1f');
else
    resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')];
end
pathNewImage = fullfile(pathNewImagesFolder, [brainNum,'.',imageModality,'.synthetic.',resolution,'.',smoothingName,'nii.gz']);
pathNewSegmMap = fullfile(pathNewImagesFolder, [brainNum,'.',imageModality,'.synthetic.',resolution,'.',smoothingName,'labels.nii.gz']);

% save temporary image (at sampling resolution)
MRIwrite(preprocessedLabelsMRI, pathNewImage); %write a new nifti file.

% save image and labels at target resolution
disp('dowmsampling to target resolution');
setFreeSurfer();
cmd = ['mri_convert ' pathNewImage ' ' pathNewImage ' -rl ' pathImageResliceLike ' -rt nearest -odt float']; % downsample like template image
[~,~] = system(cmd);
cmd = ['mri_convert ' preprocessedLabelsMRI.fspec ' ' pathNewSegmMap ' -rl ' pathImageResliceLike ' -rt nearest -odt float']; % same for labels
[~,~] = system(cmd);

end