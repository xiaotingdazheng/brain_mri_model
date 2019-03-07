function accuracy = segment(pathDirTestImages, pathDirRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages, pathClassesTable, params)

% read and check parameters
nChannel = length(pathDirTestImages);
[leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, margin, rho,...
    threshold, sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome] = readParams(params, nChannel);
% build paths structures
structPathsTestImages = cell(size(pathDirTestImages)); 
structPathsFirstRefLabels = cell(size(pathDirRefFirstLabels)); 
for i=1:length(pathDirTestImages), structPathsTestImages{i} = dir(pathDirTestImages{i}); end
for i=1:length(pathDirRefFirstLabels), structPathsFirstRefLabels{i} = dir(pathDirRefFirstLabels{i}); end
structPathsRefLabels = dir(pathDirTestLabels);
% parameters initialisation
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
nImages = length(structPathsTestImages{1});
accuracies = cell(nImages,1);
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};
brainVoxels = cell(nChannel, 1);
pathDirFloatingImages = cell(nChannel, 1);
pathDirFloatingLabels = cell(nChannel, 1);

for i=1:nImages
    
    for channel=1:nChannel
        
        % paths of reference image and corresponding FS labels
        pathRefImage = fullfile(structPathsTestImages{channel}(i).folder, structPathsTestImages{channel}(i).name);
        pathRefFirstLabels = fullfile(structPathsFirstRefLabels{channel}(i).folder, structPathsFirstRefLabels{channel}(i).name);
        pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
        
        % display processed test brain
        refBrainNum = findBrainNum(pathRefImage);
        if channel==1, disp(' '); disp(['%%% Processing test ' refBrainNum]); end
        
        % copies training labels to temp folder and erase labels corresponding to test image
        if leaveOneOut && ~useSynthethicImages
            temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum, 0);
            temp_pathDirTrainingImages = copyTrainingData(pathDirTrainingImages{channel}, refBrainNum, channel*multiChannel);
        elseif leaveOneOut && useSynthethicImages
            temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum, 0);
            temp_pathDirTrainingImages = pathDirTrainingImages{channel};
        else
            temp_pathDirTrainingLabels = pathDirTrainingLabels;
            temp_pathDirTrainingImages = pathDirTrainingImages{channel};
        end
    
        % preprocessing test image
        if multiChannel, disp(' '); disp(['%% preprocessing test ' refBrainNum ' channel ' num2str(channel)]);
        else, disp(' '); disp(['%% preprocessing test ' refBrainNum ]); end
        [pathRefImage, brainVoxels{channel}] = preprocessRefImage(pathRefImage, pathRefFirstLabels, margin, channel*multiChannel,rescale, ...
            recompute,  freeSurferHome);
        
        % floating images generation or preprocessing of real training images
        if useSynthethicImages
            if multiChannel, disp(' '); disp(['%% synthetising images for ' refBrainNum ' channel ' num2str(channel)]);
            else, disp(' '); disp(['%% synthetising images for ' refBrainNum]); end
            [pathDirFloatingImages{channel}, pathDirFloatingLabels{channel}] = generateTrainingImages(temp_pathDirTrainingLabels, pathClassesTable,...
                pathRefImage, pathRefFirstLabels, channel*multiChannel, recompute, freeSurferHome, niftyRegHome, debug);
        else
            if multiChannel, disp(' '); disp(['%% preprocessing real training images for ' refBrainNum ' channel ' num2str(channel)]);
            else, disp(' '); disp(['%% preprocessing real training images for ' refBrainNum]); end
            [pathDirFloatingImages{channel}, pathDirFloatingLabels{channel}] = preprocessRealTrainingImages(temp_pathDirTrainingImages,...
                temp_pathDirTrainingLabels, pathRefImage, channel*multiChannel, rescale, recompute, freeSurferHome);
        end
        
    end
    
    if multiChannel
        alignFloatingImages(pathDirFloatingImages, debug, niftyRegHome)
    end
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' refBrainNum])
    [pathSegmentation, pathHippoSegmentation] = labelFusion...
        (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, freeSurferHome, niftyRegHome, debug);
    
    % evaluation
    disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' ');
    accuracies{i} = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels);
    
end

pathAccuracies = fullfile(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);

end