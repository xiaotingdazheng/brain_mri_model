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

for channel=1:nChannel
    
    % compute stats from reference image
    pathStatsMatrix = fullfile(pathStatsMatrixFolder, 'ClassesStats.mat');
    if multiChannel, pathStatsMatrix = strrep(pathStatsMatrix, '.mat', ['_channel' num2str(channel) '.mat']); end
    classesStats = computeIntensityStats(pathRefImage{channel}, pathRefFirstLabels{channel}, labelsList, labelClasses, pathStatsMatrix,...
        channel*multiChannel, pathTempImFolder, recompute);
    
    for i=1:length(structPathsTrainingLabels)
        
        % we now use pathRefFirstLabels{1}, because all channels are now aligned
        pathTrainingLabels = fullfile(structPathsTrainingLabels(i).folder, structPathsTrainingLabels(i).name);
        [cellPathsNewImages{i,channel}, cellPathsNewLabels{i,channel}] = createNewImage(pathTrainingLabels, classesStats, pathTempImFolder, pathRefImage{channel},...
            targetRes, labelsList, labelClasses, channel*multiChannel, refBrainNum, recompute, freeSurferHome, niftyRegHome, debug);
        
        pathDirSyntheticImages = fileparts(cellPathsNewImages{1,1});
        pathDirSyntheticLabels = fileparts(cellPathsNewLabels{1,1});
        
        if channel > 1
            
            % realign the images coming from the same labels (1=align by registration)
            cellPathsNewImages{i,channel} = alignImages...
                (cellPathsNewImages{i,1}, cellPathsNewImages{i,channel}, 1, channel, freeSurferHome, niftyRegHome, recompute, debug);
            
            % concatenate all the channels into a single image
            pathDirSyntheticImages = fullfile(fileparts(fileparts(cellPathsNewImages{1,1})), 'concatenated_images');
            [~,name,ext] = fileparts(cellPathsNewImages{i,1});
            pathCatRefImage = fullfile(pathDirSyntheticImages, [name ext]);
            pathCatRefImage = strrep(pathCatRefImage, '.nii.gz', '_cat.nii.gz');
            catImages(cellPathsNewImages(i,:), pathCatRefImage, pathTempImFolder, recompute);
            
        end
        
    end
    
end

end