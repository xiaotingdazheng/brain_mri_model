function [pathFolderFloatingImages, pathFolderFloatingLabels] = preprocessRealTrainingImages(pathDirTrainingImages, pathDirTrainingLabels, ...
    pathRefImage, targetRes, rescale, freeSurferHome, niftyRegHome, recompute, debug)

% initialisation
nChannel = length(pathDirTrainingImages);
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
structPathsTrainingLabels = dir(pathDirTrainingLabels{1});
cellPathsNewImages = cell(length(structPathsTrainingLabels), nChannel);
cellPathsNewLabels = cell(length(structPathsTrainingLabels), 1);

for channel=1:nChannel
    
    % define resolutions of created images
    refImageMRI = MRIread(pathRefImage{channel}, 1);
    refImageRes = [refImageMRI.xsize refImageMRI.ysize refImageMRI.zsize];
    if ~any(targetRes), targetRes = refImageRes; end % set targetRes to refImageRes if specified
    % naming variables
    voxsize = [num2str(targetRes(1),'%.2f') ' ' num2str(targetRes(2),'%.2f') ' ' num2str(targetRes(3),'%.2f')];
    if targetRes(1) == targetRes(2) && targetRes(1) == targetRes(3)
        resolution = num2str(targetRes(1),'%.1f');
    else
        resolution = [num2str(targetRes(1),'%.1f'), 'x',num2str(targetRes(2),'%.1f'), 'x',num2str(targetRes(3),'%.1f')];
    end
    
    % files handling
    structPathsTrainingImages = dir(pathDirTrainingImages{channel});
    structPathsTrainingLabels = dir(pathDirTrainingLabels{channel});
    if multiChannel
        pathTempImageSubfolder = fileparts(fileparts(fileparts(pathRefImage{1})));
        pathFolderFloatingImages = fullfile(pathTempImageSubfolder, 'floating_images', ['channel_' num2str(channel)]);
        pathFolderFloatingLabels = fullfile(pathTempImageSubfolder, 'floating_labels');
    else
        pathTempImageSubfolder = fileparts(fileparts(pathRefImage{1}));
        pathFolderFloatingImages = fullfile(pathTempImageSubfolder, 'floating_images');
        pathFolderFloatingLabels = fullfile(pathTempImageSubfolder, 'floating_labels');
    end
    if ~exist(pathFolderFloatingImages, 'dir'), mkdir(pathFolderFloatingImages); end
    if ~exist(pathFolderFloatingLabels, 'dir'), mkdir(pathFolderFloatingLabels); end
    
    % downsample image and labels at target resolution
    for i=1:length(structPathsTrainingImages)
        
        % paths training images/labels
        pathTrainingImage = fullfile(structPathsTrainingImages(i).folder, structPathsTrainingImages(i).name);
        pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
        floBrainNum = findBrainNum(pathTrainingLabels);
        cellPathsNewLabels{i,channel} = fullfile(pathFolderFloatingLabels, ['training_' floBrainNum '_labels_' resolution '.nii.gz']);
        
        if multiChannel, disp(['% preprocessing training ' floBrainNum ' channel ' num2str(channel)]); 
        else, disp(['% preprocessing training ' floBrainNum]); end
        
        % rescale and/or mask image
        if rescale
            pathRescaledTrainingImage = rescaleImage(pathTrainingImage, pathFolderFloatingImages, channel, recompute);
            pathMaskedTrainingImage = mask(pathRescaledTrainingImage, pathTrainingLabels, pathFolderFloatingImages, channel, 0, 1, ...
                freeSurferHome, recompute, 1);
            cellPathsNewImages{i,channel} = fullfile(pathFolderFloatingImages, ['training_' floBrainNum '_real_rescaled_masked_' resolution '.nii.gz']);
            [~,~]=system(['rm ' pathRescaledTrainingImage]); % delete temp image
        else
            pathMaskedTrainingImage = mask(pathTrainingImage, pathTrainingLabels, pathFolderFloatingImages, channel, 0, 1, freeSurferHome, recompute, 1);
            cellPathsNewImages{i,channel} = fullfile(pathFolderFloatingImages, ['training_' floBrainNum '_real_masked_' resolution '.nii.gz']);
        end
        
        % downsample image and labels at target resolution
        if channel == 1 && (recompute || ~exist(cellPathsNewImages{i,channel}, 'file') || ~exist(cellPathsNewLabels{i,channel}, 'file'))
            disp(['downsampling training ' floBrainNum ' image to target resolution'])
            setFreeSurfer(freeSurferHome);
            cmd1 = ['mri_convert ' pathMaskedTrainingImage ' ' cellPathsNewImages{i, channel} ' -voxsize ' voxsize ' -rt cubic -odt float'];
            cmd2 = ['mri_convert ' pathTrainingLabels ' ' cellPathsNewLabels{i,channel} ' -voxsize ' voxsize ' -rt nearest -odt float'];
            [~,~] = system(cmd1);
            [~,~] = system(cmd2);
            mask(cellPathsNewImages{i,channel}, cellPathsNewLabels{i,channel}, cellPathsNewImages{i,channel}, 0, NaN, 0, freeSurferHome, 1, 0);
        end
        if channel == 1, [~,~] = system(['rm ' pathMaskedTrainingImage]); else, movefile(pathMaskedTrainingImage, cellPathsNewImages{i,channel}); end
        
        % align images
        if multiChannel && channel > 1
            % realign the images coming from the same labels
            cellPathsNewImages{i,channel} = alignImages...
                (cellPathsNewImages{i,1}, cellPathsNewImages{i,channel}, 1, channel, freeSurferHome, niftyRegHome, recompute, debug);
            mask(cellPathsNewImages{i,channel}, cellPathsNewLabels{i,1}, cellPathsNewImages{i,channel}, 0, NaN, 0, freeSurferHome, 1, 0);
        end
        
    end
    
end

pathFolderFloatingImages = fileparts(cellPathsNewImages{1,1});
pathFolderFloatingLabels = fileparts(cellPathsNewLabels{1,1});

if multiChannel
    pathFolderFloatingImages =  strrep(pathFolderFloatingImages, 'channel_1', 'concatenated_images');
    for i=1:length(structPathsTrainingImages)
        % concatenate all the channels into a single image
        pathCatRefImage = strrep(cellPathsNewImages{i,1}, 'channel_1', 'concatenated_images');
        pathCatRefImage = strrep(pathCatRefImage, '.nii.gz', '_cat.nii.gz');
        catImages(cellPathsNewImages(i,:), pathCatRefImage, recompute);
    end
end

end