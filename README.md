# brain_mri_model

This repository aims to perform Brain MRI segmentation, independently of image resolution or modality.


## requirements

- recent version of matlab (>2016)

- freesurfer package: https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall

- nifty_reg package: http://cmictig.cs.ucl.ac.uk/wiki/index.php/NiftyReg


## run segmentation

The script to run is called BrainSegmentation.m

All the parameters and file paths to be changed are at the top of this script.

Nevertheless there are some naming conventions that you need to respect. Indeed the script expects several folders containing different things.

 
- Mandatory folders (replace # by numbers):

main_folder/test_images/test_brain#.nii.gz

main_folder/test_first_labels/test_brain#_labels.nii.gz
           
main_folder/test_labels/test_brain#_labels.nii.gz
           
main_folder/training_labels/training_brain#_labels.nii.gz


- Optional folders/ files
           
main_folder/classesTable.txt (if you run the label fusion with synthetic images)

main_folder/training_images/training_brain#.nii.gz (if you run label fusion with real images)

          
## files requirement

- All the above-mentionned folders have to be under the same directory (called main_folder in this example)

- classTable.txt consists of two simple columns (without names). Labels are on the left and corresponding classes on the right separated by few white spaces.

- the images/labels contained in test_images, test_first_labels and test_labels must be aligned, meaning also the raw volumes when you open them with matlab

- the images/labels contained in training_images and training_labels must also be aligned (when runnoing label fusion with real images)


## Parallel label fusion

SingleBrainSegmentation.m is a function that will allow you to run simultaneously several brain segmentation (on a cluster for example).

The pararemeters to change are also placed at the top of that function, but you still need to provide the individual name of the test image along with its first_labels and labels.

The same architecture described in the run segmentation section must be applied.