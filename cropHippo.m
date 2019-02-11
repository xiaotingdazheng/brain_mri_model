function [croppedRefLabels, croppedImage, cropping] = cropHippo(pathRefMaskedImage, pathRefLabels, margin, croppedFolder)

% This function takes as inputs an image and its correpsonding
% segmentation map, locates the hippocampus (or  hippocampi if both
% hemishperes) and saves the cropped images and segmentation in specified
% resul folder. The cropping is done with a specified margin.

refLabels = MRIread(pathRefLabels);
refMaskedImage = MRIread(pathRefMaskedImage);
Labels = refLabels.vol; 
Image = refMaskedImage.vol;

LabelsMask = Labels > 20000 | Labels == 17 | Labels == 53 ; % detect hippocampus labels (17 or 43) and subfields labels (>20000)
LabelsMaskMRI.vol = LabelsMask; % builds MRI object to be read by cropLabelVol function
z = zeros(4); z(1:3,1:3) = eye(3);
LabelsMaskMRI.vox2ras0 = z;

[~, cropping] = cropLabelVol(LabelsMaskMRI, margin); % finds cropping around hippocampus

% crop both image and corresponding segmentation
croppedRefLabels = single(Labels(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)));
croppedImage = single(Image(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)));

% save cropped segmentation
LabelsMaskMRI.vol = croppedRefLabels;
temp_pathRefLabels = strrep(pathRefLabels,'.nii.gz', '.mgz');
[~,name,~] = fileparts(temp_pathRefLabels);
if ~exist(croppedFolder, 'dir'), mkdir(croppedFolder); end
pathCroppedLabels = fullfile(croppedFolder, [name '.cropped.nii.gz']);
MRIwrite(LabelsMaskMRI, pathCroppedLabels);

% save cropped image
LabelsMaskMRI.vol = croppedImage;
temp_pathRefMaskedImage = strrep(pathRefMaskedImage,'.nii.gz', '.mgz');
[~,name,~] = fileparts(temp_pathRefMaskedImage);
pathCroppedImage = fullfile(croppedFolder, [name '.cropped.nii.gz']);
MRIwrite(LabelsMaskMRI, pathCroppedImage);

end