function [pathNewRefImage, brainVoxels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, rescale, recompute, margin, freeSurferHome)

% naming variables
refBrainNum = findBrainNum(pathRefImage);
% define path preprocessed subfodler
pathTempImageSubfolder = fullfile(fileparts(fileparts(pathRefImage)), ['temp_' refBrainNum]);
pathPreprocessedRefImageSubfolder = fullfile(pathTempImageSubfolder, 'preprocessed_test_image');
if ~exist(pathPreprocessedRefImageSubfolder, 'dir'), mkdir(pathPreprocessedRefImageSubfolder); end

% rescale image
if rescale
    pathRefImage = rescaleImage(pathRefImage, pathPreprocessedRefImageSubfolder, recompute);
end

% mask image with its labels
disp(['masking ' refBrainNum]);
pathNewRefImage = mask(pathRefImage, pathRefFirstLabels, pathPreprocessedRefImageSubfolder, freeSurferHome);

% preparing the reference image for label fusion (masking and cropping)
brainVoxels = selectBrainVoxels(pathRefFirstLabels, margin);

end