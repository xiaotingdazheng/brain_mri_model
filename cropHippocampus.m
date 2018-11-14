function [HippoSyntheticImages, HippoLabels, HippoRealImages] = cropHippocampus(SyntheticImages, Labels, RealImages, maxCropping)

addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

if length(SyntheticImages) ~= length(Labels) || length(SyntheticImages) ~= length(RealImages)
    error('not same number of synthetic images, real images and label maps')
end

HippoSyntheticImages=SyntheticImages;
HippoLabels=Labels;
HippoRealImages=RealImages;

disp('cropping synthetic images')
for i=1:length(SyntheticImages)
    
    % read full image
    tempMRI = MRIread(SyntheticImages{i});
    
    % modify components of nifty file
    tempMRI.vol = tempMRI.vol(maxCropping(1):maxCropping(2),maxCropping(3):maxCropping(4),maxCropping(5):maxCropping(6));
    tempMRI.volsize = [maxCropping(2)-maxCropping(1)+1,maxCropping(3)-maxCropping(4)+1,maxCropping(5)-maxCropping(6)+1];
    tempMri.height = tempMRI.volsize(1); tempMri.width = tempMRI.volsize(2); tempMri.depth = tempMRI.volsize(3);
    
    % writing cropped synthetic image and saving path in HippoSyntheticImages
    newPath = strrep(SyntheticImages{i},'.nii.gz','hippo.cropped.nii.gz');
    MRIwrite(tempMRI, newPath);
    HippoSyntheticImages{i} = newPath;

end

disp('cropping labels')
for i=1:length(Labels)
    
    tempMRI = MRIread(Labels{i});
    
    tempMRI.vol = tempMRI.vol(maxCropping(1):maxCropping(2),maxCropping(3):maxCropping(4),maxCropping(5):maxCropping(6));
    tempMRI.volsize = [maxCropping(2)-maxCropping(1)+1,maxCropping(3)-maxCropping(4)+1,maxCropping(5)-maxCropping(6)+1];
    tempMri.height = tempMRI.volsize(1); tempMri.width = tempMRI.volsize(2); tempMri.depth = tempMRI.volsize(3);
    
    newPath = strrep(Labels{i},'.nii.gz','hippo.cropped.nii.gz');
    MRIwrite(tempMRI, newPath);
    
    HippoLabels{i} = newPath;

end

disp('cropping real images')
for i=1:length(RealImages)

    tempMRI = MRIread(RealImages{i});
    
    tempMRI.vol = tempMRI.vol(maxCropping(1):maxCropping(2),maxCropping(3):maxCropping(4),maxCropping(5):maxCropping(6));
    tempMRI.volsize = [maxCropping(2)-maxCropping(1)+1,maxCropping(3)-maxCropping(4)+1,maxCropping(5)-maxCropping(6)+1];
    tempMri.height = tempMRI.volsize(1); tempMri.width = tempMRI.volsize(2); tempMri.depth = tempMRI.volsize(3);
    
    newPath = strrep(RealImages{i},'.nii.gz','hippo.cropped.nii.gz');
    MRIwrite(tempMRI, newPath);
    
    HippoRealImages{i} = newPath;

end


end