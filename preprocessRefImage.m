function [pathNewRefImage, brainVoxels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, margin, rescale, realignImages,...
    freeSurferHome, niftyRegHome, recompute, debug)

% naming variables
nChannel = length(pathRefImage);
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
refBrainNum = findBrainNum(pathRefImage{1});
% define path preprocessed subfodler
pathTempImageSubfolder = fullfile(fileparts(fileparts(pathRefImage{1})), ['temp_' refBrainNum]);
pathPreprocessedRefImageSubfolder = fullfile(pathTempImageSubfolder, 'preprocessed_test_image');
% initialisation
brainVoxels = cell(1,nChannel);

for channel=1:nChannel
    
    % extend path if multi channel
    if multiChannel
        temp_pathPreprocessedRefImFolder = fullfile(pathPreprocessedRefImageSubfolder, ['channel_' num2str(channel)]);
    else
        temp_pathPreprocessedRefImFolder = pathPreprocessedRefImageSubfolder;
    end
    if ~exist(temp_pathPreprocessedRefImFolder, 'dir'), mkdir(temp_pathPreprocessedRefImFolder); end
    
    % rescale image
    if rescale
        pathRefImage{channel} = rescaleImage(pathRefImage{channel}, temp_pathPreprocessedRefImFolder, channel*multiChannel, recompute);
    end
    
    % mask image with its labels
    padNaNs = 0;
    pathRefImage{channel} = mask(pathRefImage{channel}, pathRefFirstLabels{channel}, temp_pathPreprocessedRefImFolder, ...
        channel*multiChannel, padNaNs, freeSurferHome, recompute);
    
end

% preparing the reference image for label fusion (masking and cropping)
brainVoxels{1} = selectBrainVoxels(pathRefFirstLabels{1}, margin);

if multiChannel
    
    % create concatenated image subfolder
    pathCatSubfolder = fullfile(fileparts(temp_pathPreprocessedRefImFolder), 'concatenated_image');
    if ~exist(pathCatSubfolder, 'dir'), mkdir(pathCatSubfolder); end
    
    % realign all channel with first one
    if realignImages
        pathAlignedRefImages = pathRefImage;
        for channel=2:nChannel
            pathAlignedRefImages{channel} = alignImages...
                (pathRefImage{1}, pathRefImage{channel}, realignImages, channel, freeSurferHome, niftyRegHome, recompute, debug);
        end
        pathCatRefImage = fullfile(pathCatSubfolder, ['test_' refBrainNum '_aligned_masked_cat.nii.gz']);
    else
        pathCatRefImage = fullfile(pathCatSubfolder, ['test_' refBrainNum '_masked_cat.nii.gz']);
    end
    
    % pad all images with NaNs
    for channel=1:nChannel
        maskWithNaNs(pathAlignedRefImages{channel}, pathAlignedRefImages{channel}, pathAlignedRefImages{channel});
        if channel > 1
           brainVoxels{channel} = selectBrainVoxels(pathAlignedRefImages{channel}, margin); 
        end
    end
    
    % concatenate all the channels into a single image
    catImages(pathAlignedRefImages, pathCatRefImage, recompute);
    pathNewRefImage = [pathRefImage pathCatRefImage];
    
else
    pathNewRefImage = pathRefImage;
end

end