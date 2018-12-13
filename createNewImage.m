function new_image = createNewImage(mergedLabelsMRI, classesStats, listClassesToGenerate, labelsList, labelClasses, gaussianType, targetRes,...
    pathNewImagesFolder, pathStatsMatrix, pathLabels, pathImageResliceLike, downsampleWithMatlab, subfieldsSmoothing)

% This script generates a synthetic image from a segmentation map and basic
% statistics of intensity distribution for all the regions in the brain.
% For each voxel, we sample a value drawn from the model of the class it 
% belongs to (identified thanks to the segmentation map).
% This results in an image of the same resolution as the provided segm map.
% We still need to blur the obtained image before downsample it to the
% desired target resolution, before saving the final result.

mergedLabels = mergedLabelsMRI.vol;
sampleRes=[mergedLabelsMRI.xsize, mergedLabelsMRI.ysize, mergedLabelsMRI.zsize];

%classesStats: matrix containing stats computed for each class
% 1st row = mean
% 2nd row = median
% 3rd row = standard deviation
% 4th row = 1.4826*median absolute deviation (ie sigmaMAD)

new_image = zeros(size(mergedLabels));

for lC=1:length(listClassesToGenerate)
    disp(['generating voxel intensities for class ', num2str(lC)]);
    
    classLabel = listClassesToGenerate(lC);
    labelsBelongingToClass = labelsList(labelClasses == classLabel); %labels belonging to class lC
    for l=1:length(labelsBelongingToClass)
        voxelIndices = find(mergedLabels == labelsBelongingToClass(l)); %find voxels with label l
        if strcmp(gaussianType, 'median')
            new_image(voxelIndices) = classesStats(2,classLabel) + classesStats(4,classLabel)*sqrt(8)*randn(size(voxelIndices)); %generate new values for these voxels
        elseif strcmp(gaussianType, 'mean')
            new_image(voxelIndices) = classesStats(1,classLabel) + classesStats(1,classLabel)*sqrt(8)*randn(size(voxelIndices)); %generate new values for these voxels
        else
            error('gaussianType not recognised. Should be "mean" or "median"')
        end
    end
end

disp('blurring image to prevent alliasing');
f=targetRes./sampleRes;
sigmaFilt=0.9*f;
new_image = imgaussfilt3(new_image, sigmaFilt); %apply gaussian filter

if downsampleWithMatlab
    disp('dowmsampling to target resolution');
    new_image=new_image(1:round(f(1)):end,1:round(f(2)):end,1:round(f(3)):end); %subsample to obtain target resolution
    mergedLabelsMRI.xsize = targetRes(1); mergedLabelsMRI.ysize = targetRes(2); mergedLabelsMRI.zsize = targetRes(3);
end

disp('writting created image');
mergedLabelsMRI.vol = new_image;

%name of the file
brain_num = pathLabels(regexp(pathLabels,'brain')+5);
mri_type = pathStatsMatrix(regexp(pathStatsMatrix, 'ClassesStats_')+13:regexp(pathStatsMatrix, 'ClassesStats_')+14);
if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3)
    name = ['brain',brain_num,'.synthetic.',mri_type,'.',num2str(targetRes(1),'%.1f')];
else
    resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')];
    name = ['brain',brain_num,'.synthetic.',mri_type,'.',resolution];
end
if subfieldsSmoothing, name = [name '.smoothed']; end
pathNewImage = fullfile(pathNewImagesFolder, [name,'.nii.gz']);

MRIwrite(mergedLabelsMRI, pathNewImage); %write a new mgz file.

if ~downsampleWithMatlab
    disp('dowmsampling to target resolution');
    
    % downsample and reslice like template image
    setFreeSurfer(); % calls freesurfer package
    cmd = ['mri_convert ' pathNewImage ' ' pathNewImage ' -rl ' pathImageResliceLike ' -rt nearest -odt float'];
    [~,~] = system(cmd);
    
    % do the same to corresponding aseg+subfields
    pathNewImage = strrep(pathNewImage, '.nii.gz', '.mgz');    
    [dir,name,~] = fileparts(pathNewImage);
    pathNewSegmMap = fullfile(dir,[name,'.labels.nii.gz']);
    cmd = ['mri_convert ' mergedLabelsMRI.fspec ' ' pathNewSegmMap ' -rl ' pathImageResliceLike ' -rt nearest -odt float'];
    [~,~] = system(cmd);
end

end