function [pathFolderFloImagesNew, pathFolderFloLabelsNew] = preprocessRealTrainingImages(pathDirTrainingImages, pathDirTrainingLabels, ...
    pathRefImage, pathTempImFolder, targetRes, nChannel, rescale, freeSurferHome, niftyRegHome, recompute, debug)

% initialisation
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
structPathsTrainingLabels = dir(pathDirTrainingLabels{1});
cellPathsNewImages = cell(length(structPathsTrainingLabels), nChannel);
cellPathsNewLabels = cell(length(structPathsTrainingLabels), 1);

for channel=1:nChannel
    
    % define resolutions of created images
    refImageMRI = myMRIread(pathRefImage{channel}, 1);
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
    if multiChannel, pathFolderFloImages = fullfile(pathTempImFolder, 'floating_images', ['channel_' num2str(channel)]);
    else, pathFolderFloImages = fullfile(pathTempImFolder, 'floating_images'); end
    pathFolderFloLabels = fullfile(pathTempImFolder, 'floating_labels');
    if ~exist(pathFolderFloImages, 'dir'), mkdir(pathFolderFloImages); end
    if ~exist(pathFolderFloLabels, 'dir'), mkdir(pathFolderFloLabels); end
    
    % downsample image and labels at target resolution
    for i=1:length(structPathsTrainingImages)
        
        % paths training images/labels
        pathTrainingImage = fullfile(structPathsTrainingImages(i).folder, structPathsTrainingImages(i).name);
        pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
        floBrainNum = findBrainNum(pathTrainingLabels);
        if rescale, cellPathsNewImages{i,channel} = fullfile(pathFolderFloImages, ['training_' floBrainNum '_real_rescaled_masked_' resolution '.nii.gz']);
        else, cellPathsNewImages{i,channel} = fullfile(pathFolderFloImages, ['training_' floBrainNum '_real_masked_' resolution '.nii.gz']); end
        cellPathsNewLabels{i,channel} = fullfile(pathFolderFloLabels, ['training_' floBrainNum '_labels_' resolution '.nii.gz']);
        
        if multiChannel, disp(['% preprocessing training ' floBrainNum ' channel ' num2str(channel)]); 
        else, disp(['% preprocessing training ' floBrainNum]); end
        
        % resample image and labels at target resolution or align them with first channel
        if channel == 1 
            if recompute || ~exist(cellPathsNewImages{i,channel}, 'file') || ~exist(cellPathsNewLabels{i,channel}, 'file')
                pathTrainingImage = mask(pathTrainingImage, pathTrainingLabels, pathFolderFloImages, rescale, 1, 0, floBrainNum, pathTempImFolder, 1, 1);
                disp(['downsampling training ' floBrainNum ' image to target resolution'])
                setFreeSurfer(freeSurferHome);
                cmd1 = ['mri_convert ' pathTrainingImage ' ' cellPathsNewImages{i, channel} ' -voxsize ' voxsize ' -rt cubic -odt float'];
                cmd2 = ['mri_convert ' pathTrainingLabels ' ' cellPathsNewLabels{i,channel} ' -rl ' cellPathsNewImages{i, channel} ' -rt nearest -odt float'];
                [~,~] = system(cmd1);
                [~,~] = system(cmd2);
                [~,~] = system(['rm ' pathTrainingImage]);
            end
            pathFolderFloImagesNew = fileparts(cellPathsNewImages{1,1});
            pathFolderFloLabelsNew = fileparts(cellPathsNewLabels{1,1});
        else
            if recompute || ~exist(cellPathsNewImages{i,channel}, 'file')
                % rescale and mask images
                pathTrainingImage = mask(pathTrainingImage, pathTrainingImage, pathFolderFloImages, rescale, channel, 0, floBrainNum, pathTempImFolder, 1, 1);
                % align image to channel 1
                cellPathsNewImages{i,channel} = alignImages...
                    (cellPathsNewImages{i,1}, pathTrainingImage, 1, channel, freeSurferHome, niftyRegHome, recompute, debug);
                % concatenate all the channels into a single image
                pathFolderFloImagesNew = fullfile(fileparts(pathFolderFloImages), 'concatenated_images');
                [~,name,ext] = fileparts(cellPathsNewImages{i,1});
                pathCatRefImage = fullfile(pathFolderFloImagesNew, [name ext]);
                pathCatRefImage = strrep(pathCatRefImage, '.nii.gz', '_cat.nii.gz');
                catImages(cellPathsNewImages(i,:), pathCatRefImage, pathTempImFolder, recompute);
            end
        end
        
    end
    
end

end