function [pathDirSyntheticImages, pathDirSyntheticLabels] = generateTrainingImages(pathDirTrainingLabels, labelsList, labelClasses, pathRefImage,...
    pathRefFirstLabels, pathTempImFolder, targetRes, refBrainNum, recompute, freeSurferHome, niftyRegHome, debug)

% files handling
nChannel = length(pathRefFirstLabels);
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
pathStatsMatrixFolder = fullfile(pathTempImFolder, 'ClassesStats');
if ~exist(pathStatsMatrixFolder, 'dir'), mkdir(pathStatsMatrixFolder); end

% initialisation
structPathsTrainingLabels = dir(pathDirTrainingLabels{1});
cellPathsNewImages = cell(length(structPathsTrainingLabels), nChannel);
cellPathsNewLabels = cell(length(structPathsTrainingLabels), nChannel);
classesStats = cell(1,nChannel);


for i=1:length(structPathsTrainingLabels)
    
    % select training labels
    pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
    floBrainNum = findBrainNum(pathTrainingLabels);
    
    for channel=1:nChannel
        
        % compute/load stats from reference image
        if isempty(classesStats{channel})
            pathStatsMatrix = fullfile(pathStatsMatrixFolder, 'ClassesStats.mat');
            if multiChannel, pathStatsMatrix = strrep(pathStatsMatrix, '.mat', ['_channel' num2str(channel) '.mat']); end
            classesStats{channel} = computeIntensityStats(pathRefImage{channel}, pathRefFirstLabels{channel}, labelsList, labelClasses, pathStatsMatrix,...
                channel*multiChannel, pathTempImFolder, recompute);
        end
        
        % generate new image
        [cellPathsNewImages{i,channel}, cellPathsNewLabels{i,channel}, pathTrainingLabels] = createNewImage(pathTrainingLabels, classesStats{channel}, pathTempImFolder, pathRefImage{channel},...
            targetRes, labelsList, labelClasses, channel*multiChannel, refBrainNum, floBrainNum, recompute, freeSurferHome, niftyRegHome, debug);
        
        % create dir names
        pathDirSyntheticImages = fileparts(cellPathsNewImages{1,1});
        pathDirSyntheticLabels = fileparts(cellPathsNewLabels{1,1});
        
        % concatenate all the channels into a single image
        if channel > 1
            % realign all channels (2=mri_convert)
            cellPathsNewImages{i,channel} = alignImages(cellPathsNewImages{i,1}, cellPathsNewImages{i,channel}, 2, channel, freeSurferHome, niftyRegHome, recompute, debug);
            % concatenate channels
            pathDirSyntheticImages = fullfile(fileparts(fileparts(cellPathsNewImages{1,1})), 'concatenated_images');
            [~,name,ext] = fileparts(cellPathsNewImages{i,1});
            pathCatRefImage = fullfile(pathDirSyntheticImages, [name ext]);
            pathCatRefImage = strrep(pathCatRefImage, '.nii.gz', '_cat.nii.gz');
            catImages(cellPathsNewImages(i,:), pathCatRefImage, pathTempImFolder, recompute);
        end
        
    end
    
end

end