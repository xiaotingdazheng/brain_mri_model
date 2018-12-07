function [croppedSegmentation, croppedImage, cropping] = cropHippo(Segmentation, Image, margin, resultsFolder)

% This function takes as inputs an image and its correpsonding
% segmentation map, locates the hippocampus (or  hippocampi if both 
% hemishperes) and saves the cropped images and segmentation in specified
% resul folder. The cropping is done with a specified margin.

SegmentationMask = Segmentation > 20000 | Segmentation == 17 | Segmentation == 43 ; % detect hippocampus labels (17 or 43) and subfields labels (>20000)
SegmentationMaskMRI.vol = SegmentationMask; % builds MRI object to be read by cropLabelVol function
SegmentationMaskMRI.vox2ras0 = zeros(4);

[~, cropping] = cropLabelVol(SegmentationMaskMRI, margin); % finds cropping around hippocampus

% crop both image and corresponding segmentation
croppedSegmentation = Segmentation(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
croppedImage = Image(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));

% save cropped segmentation
pathCroppedSegmentation = fullfile(resultsFolder, [refBrainNum '_GT_segmentation_map.nii.gz']);
save(pathCroppedSegmentation, 'croppedSegmentation');

% save cropped image
pathCroppedImage = fullfile(resultsFolder, [refBrainNum '_cropped_image.nii.gz']);
save(pathCroppedImage, 'croppedImage');

end