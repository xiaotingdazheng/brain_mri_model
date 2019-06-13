function [pathNewRefImage, pathRefFirstLabels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, pathTempImFolder, ...
    rescale, realignImages, refBrainNum, freeSurferHome, niftyRegHome, recompute, debug)

% naming variables
nChannel = length(pathRefImage);
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
% define path preprocessed subfodler
pathPreprocessedRefImageSubfolder = fullfile(pathTempImFolder, 'preprocessed_test_image');

for channel=1:nChannel
    
    % extend path if multi channel
    if multiChannel, temp_pathPreprocessedRefImFolder = fullfile(pathPreprocessedRefImageSubfolder, ['channel_' num2str(channel)]);
    else, temp_pathPreprocessedRefImFolder = pathPreprocessedRefImageSubfolder; end
    if ~exist(temp_pathPreprocessedRefImFolder, 'dir'), mkdir(temp_pathPreprocessedRefImFolder); end
    
    % convert image and labels from mgz to nii.gz
    pathRefImage{channel} = mgz2nii(pathRefImage{channel}, temp_pathPreprocessedRefImFolder, 0, 'images', channel*multiChannel, refBrainNum, freeSurferHome, recompute);
    pathRefFirstLabels{channel} = mgz2nii(pathRefFirstLabels{channel}, temp_pathPreprocessedRefImFolder, 0, 'labels', channel*multiChannel, refBrainNum, ...
        freeSurferHome, recompute);
    
    % rescale and mask image with zeros using its labels
    pathRefImage{channel} = mask(pathRefImage{channel}, pathRefFirstLabels{channel}, temp_pathPreprocessedRefImFolder, ...
        rescale, channel*multiChannel, 0, refBrainNum, pathTempImFolder, recompute, 1);
    
end

if multiChannel
    pathNewRefImage = multiChannelPreprocessing(pathRefImage, temp_pathPreprocessedRefImFolder, nChannel, rescale, ...
        realignImages, refBrainNum, pathTempImFolder, freeSurferHome, niftyRegHome, recompute, debug);
else
    pathNewRefImage = pathRefImage;
end

end

function pathNewRefImage = multiChannelPreprocessing(pathRefImage, temp_pathPreprocessedRefImFolder, nChannel, rescale, ...
    realignImages, refBrainNum, pathTempImFolder, freeSurferHome, niftyRegHome, recompute, debug)

% create concatenated image subfolder
pathCatSubfolder = fullfile(fileparts(temp_pathPreprocessedRefImFolder), 'concatenated_image');
if ~exist(pathCatSubfolder, 'dir'), mkdir(pathCatSubfolder); end
% path of concatenated result image
if rescale, pathCatRefImage = fullfile(pathCatSubfolder, ['test_' refBrainNum '_rescaled_masked_cat.nii.gz']);
else, pathCatRefImage = fullfile(pathCatSubfolder, ['test_' refBrainNum '_masked_cat.nii.gz']); end

% realign all channel with first one
if realignImages
    pathAlignedRefImages = pathRefImage;
    for channel=2:nChannel
        pathAlignedRefImages{channel} = alignImages...
            (pathRefImage{1}, pathRefImage{channel}, realignImages, channel, freeSurferHome, niftyRegHome, recompute, debug);
    end
end

% concatenate all the channels into a single image
catImages(pathAlignedRefImages, pathCatRefImage, pathTempImFolder, recompute);
pathNewRefImage = [pathRefImage pathCatRefImage];

end