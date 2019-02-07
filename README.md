# brain_mri_model

This repository aims to perform Brain MRI segmentation, independently of image resolution or modality.

## requirements

-recent version of matlab (>2016)

-freesurfer package: https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall

## scripts

There are several scripts that you can use. All the things you need to change are at the top of these scripts.

Nevertheless there are some naming conventions that you need to respect. Indeed the script expects several folders containing different things.

 

-  BrainSegmentation.m : performs data synthesis and label fusion on two different datasets (training and test)

main folder/test_images/test_brain##.nii.gz

main folder/test_first_labels/test_brain##_labels.nii.gz
           
main folder/test_labels/test_brain##_labels.nii.gz
           
main folder/training_labels/training_brain#_labels.nii.gz
           
main folder/classesTable.txt

 

- BrainSegmentation_LeaveOneOut.m : performs data synthesis and label fusion on same dataset with Leave One Out evaluation

main folder/test_images/test_brain##.nii.gz

main folder/test_first_labels/test_brain##_labels.nii.gz

main folder/test_labels/test_brain##_labels.nii.gz

main folder/training_labels/training_brain#_labels.nii.gz

main folder/classesTable.txt

 

- BrainSegmentation_RealImages.m : performs label fusion with real images. this time we don't have to provide the class table, because we don't need to generate new images.

main folder/test_images/test_brain##.nii.gz

main folder/test_first_labels/test_brain##_labels.nii.gz

main folder/test_labels/test_brain##_labels.nii.gz

main folder/training_labels/training_brain#_labels.nii.gz

main folder/training_images/training_brain#.nii.gz
           
## files requirement

- classTable.txt consists of two simple columns (without names). Labels are on the left and corresponding classes on the right separated by few white spaces.

- the test images, test_first_labels and test_labels must be aligned, meaning also the row volumes when you open them with matlab (labels.vol;)

- same with training images and training labels (in the case of BrainSegmentation_RealImages.m)

- training labels are the ones at high resolution (0.3mm), but never mind  because I will give them to you alongside the images.
