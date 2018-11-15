function [HippoSyntheticImages, HippoLabels, HippoRealImages] = cropHippocampus(cellPathsSyntheticImages, cellPathsLabels, cellPathsRealImages, maxCropping)

addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

if length(cellPathsSyntheticImages) ~= length(cellPathsLabels) || length(cellPathsSyntheticImages) ~= length(cellPathsRealImages)
    error('not same number of synthetic images, real images and label maps')
end

HippoSyntheticImages=cellPathsSyntheticImages;
HippoLabels=cellPathsLabels;
HippoRealImages=cellPathsRealImages;

disp('cropping synthetic images')
for i=1:length(cellPathsSyntheticImages)
    
    % read full image
    tempMRI = MRIread(cellPathsSyntheticImages{i});
    
    % modify components of nifty file
    tempMRI.vol = tempMRI.vol(maxCropping(1):maxCropping(2),maxCropping(3):maxCropping(4),maxCropping(5):maxCropping(6));
    tempMRI.volsize = [maxCropping(2)-maxCropping(1)+1,maxCropping(3)-maxCropping(4)+1,maxCropping(5)-maxCropping(6)+1];
    tempMri.height = tempMRI.volsize(1); tempMri.width = tempMRI.volsize(2); tempMri.depth = tempMRI.volsize(3);
    
    % writing cropped synthetic image and saving path in HippoSyntheticImages
    newPath = strrep(cellPathsSyntheticImages{i},'.nii.gz','.hippo.cropped.nii.gz');
    tempMRI.fspec = newPath;
    MRIwrite(tempMRI, newPath);
    HippoSyntheticImages{i} = newPath;

end

disp('cropping labels')
for i=1:length(cellPathsLabels)
    
    tempMRI = MRIread(cellPathsLabels{i});
    
    tempMRI.vol = tempMRI.vol(maxCropping(1):maxCropping(2),maxCropping(3):maxCropping(4),maxCropping(5):maxCropping(6));
    tempMRI.volsize = [maxCropping(2)-maxCropping(1)+1,maxCropping(3)-maxCropping(4)+1,maxCropping(5)-maxCropping(6)+1];
    tempMri.height = tempMRI.volsize(1); tempMri.width = tempMRI.volsize(2); tempMri.depth = tempMRI.volsize(3);
    
    newPath = strrep(cellPathsLabels{i},'.nii.gz','.hippo.cropped.nii.gz');
    MRIwrite(tempMRI, newPath);
    
    HippoLabels{i} = newPath;

end

disp('cropping real images')
for i=1:length(cellPathsRealImages)

    tempMRI = MRIread(cellPathsRealImages{i});
    
    tempMRI.vol = tempMRI.vol(maxCropping(1):maxCropping(2),maxCropping(3):maxCropping(4),maxCropping(5):maxCropping(6));
    tempMRI.volsize = [maxCropping(2)-maxCropping(1)+1,maxCropping(3)-maxCropping(4)+1,maxCropping(5)-maxCropping(6)+1];
    tempMri.height = tempMRI.volsize(1); tempMri.width = tempMRI.volsize(2); tempMri.depth = tempMRI.volsize(3);
    
    newPath = strrep(cellPathsRealImages{i},'.nii.gz','.hippo.cropped.nii.gz');
    MRIwrite(tempMRI, newPath);
    
    HippoRealImages{i} = newPath;

end


end