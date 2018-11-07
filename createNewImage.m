function new_image = createNewImage(fusedLabelsMRI, classesStats, listClassesToGenerate, labelsList, labelClasses, gaussianType, targetRes, pathNewImagesFolder, pathLabels)

fusedLabels = fusedLabelsMRI.vol;
sampleRes=[fusedLabelsMRI.xsize, fusedLabelsMRI.ysize, fusedLabelsMRI.zsize];

%classesStats: matrix containing stats computed for each class
% 1st row = mean
% 2nd row = median
% 3rd row = standard deviation
% 4th row = 1.4826*median absolute deviation (ie sigmaMAD)

new_image = zeros(size(fusedLabels));

for lC=1:length(listClassesToGenerate)
    disp(['generating voxel intensities for class ', num2str(lC)]);
    
    classLabel = listClassesToGenerate(lC);
    labelsBelongingToClass = labelsList(labelClasses == classLabel); %labels belonging to class lC
    for l=1:length(labelsBelongingToClass)
        voxelIndices = find(fusedLabels == labelsBelongingToClass(l)); %find voxels with label l
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

disp('dowmsampling to target resolution');
new_image=new_image(1:round(f(1)):end,1:round(f(2)):end,1:round(f(3)):end); %subsample to obtain target resolution

disp('writting created image');
fusedLabelsMRI.vol = new_image;
fusedLabelsMRI.xsize = targetRes(1); fusedLabelsMRI.ysize = targetRes(2); fusedLabelsMRI.zsize = targetRes(3);

%name of the file
[~,~,ext] = fileparts(pathLabels);
brain_num = pathLabels(regexp(pathLabels,'brain')+5);
if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3)
    name = ['brain',brain_num,'.synthetic.',num2str(targetRes(1),'%.1f')];
else
    resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')];
    name = ['brain',brain_num,'.synthetic.',resolution];
end
pathNewImage = fullfile(pathNewImagesFolder, [name,ext]);

MRIwrite(fusedLabelsMRI, pathNewImage); %write a new mgz file.

end