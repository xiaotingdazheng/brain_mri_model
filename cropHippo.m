function [croppedSegmentation, croppedImage, cropping] = cropHippo(Segmentation, Image, margin, resultsFolder, refBrainNum)

% This function takes as inputs an image and its correpsonding
% segmentation map, locates the hippocampus (or  hippocampi if both
% hemishperes) and saves the cropped images and segmentation in specified
% resul folder. The cropping is done with a specified margin.

SegmentationMask = Segmentation > 20000 | Segmentation == 17 | Segmentation == 53 ; % detect hippocampus labels (17 or 43) and subfields labels (>20000)
SegmentationMaskMRI.vol = SegmentationMask; % builds MRI object to be read by cropLabelVol function
z = zeros(4); z(1:3,1:3) = eye(3);
SegmentationMaskMRI.vox2ras0 = z;

[~, cropping] = cropLabelVol(SegmentationMaskMRI, margin); % finds cropping around hippocampus

% crop both image and corresponding segmentation
croppedSegmentation = Segmentation(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
croppedImage = Image(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));

% save cropped segmentation
SegmentationMaskMRI.vol = croppedSegmentation;
pathCroppedSegmentation = fullfile(resultsFolder, [refBrainNum '.labels.cropped.nii.gz']);
MRIwrite(SegmentationMaskMRI, pathCroppedSegmentation);

% save cropped image
SegmentationMaskMRI.vol = croppedImage;
pathCroppedImage = fullfile(resultsFolder, [refBrainNum '.cropped.nii.gz']);
MRIwrite(SegmentationMaskMRI, pathCroppedImage);

end