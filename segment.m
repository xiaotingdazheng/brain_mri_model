function accuracy = segment(pathDirTestImages, pathDirRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages, params)

% read and check parameters
nChannel = length(pathDirTestImages);
[leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, alignTestImages, margin, rho, threshold,...
    sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome, labelsList, labelClasses, labelsNames] = readParams(params, nChannel);
% build paths structures
structPathsTestImages = cell(size(pathDirTestImages));
structPathsFirstRefLabels = cell(size(pathDirRefFirstLabels));
for i=1:length(pathDirTestImages), structPathsTestImages{i} = dir(pathDirTestImages{i}); end
for i=1:length(pathDirRefFirstLabels), structPathsFirstRefLabels{i} = dir(pathDirRefFirstLabels{i}); end
structPathsRefLabels = dir(pathDirTestLabels{1});
% build path resulting accuracies
pathMainFolder = fileparts(structPathsRefLabels(1).folder);
pathAccuracies = fullfile(pathMainFolder, 'accuracy.mat');
% parameters initialisation
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
nImages = length(structPathsTestImages{1});
accuracies = cell(nImages,1);
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder  multiChannel recompute registrationOptions};

for i=1:nImages
    
    % paths of reference image and corresponding FS labels
    [pathRefImage, pathRefFirstLabels, pathRefLabels, refBrainNum] = buildRefPaths(structPathsTestImages,...
        structPathsFirstRefLabels, structPathsRefLabels, i);
    
    % display processed test brain
    disp(' '); disp(['%%% Processing test ' refBrainNum]);
    
    % copies training labels to temp folder and erase labels corresponding to test image
    if leaveOneOut && ~useSynthethicImages
        temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum, length(pathDirTrainingLabels));
        temp_pathDirTrainingImages = copyTrainingData(pathDirTrainingImages, refBrainNum, nChannel);
    elseif leaveOneOut && useSynthethicImages
        temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum, 1);
        temp_pathDirTrainingImages = pathDirTrainingImages;
    else
        temp_pathDirTrainingLabels = pathDirTrainingLabels;
        temp_pathDirTrainingImages = pathDirTrainingImages;
    end
    
    % preprocessing test image
    disp(' '); if multiChannel, disp(['%% preprocessing test ' refBrainNum ' images ']); else, disp(['%% preprocessing test ' refBrainNum]); end
    [pathRefImage, brainVoxels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, margin, rescale, alignTestImages, ...
        freeSurferHome, niftyRegHome, recompute, debug);
    
    % floating images generation or preprocessing of real training images
    if useSynthethicImages
        disp(' '); disp(['%% synthetising images for ' refBrainNum]);
        [pathDirFloatingImages, pathDirFloatingLabels] = generateTrainingImages(temp_pathDirTrainingLabels, labelsList, labelClasses,...
            pathRefImage, pathRefFirstLabels, targetResolution, recompute, freeSurferHome, niftyRegHome, debug);
    else
        disp(' '); disp(['%% preprocessing real training images for ' refBrainNum]);
        [pathDirFloatingImages, pathDirFloatingLabels] = preprocessRealTrainingImages(temp_pathDirTrainingImages,...
            temp_pathDirTrainingLabels, pathRefImage, targetResolution, rescale, freeSurferHome, niftyRegHome, recompute, debug);
    end
    
    % upsample ref data to targetRes
    if targetResolution
        [pathRefImage, pathRefLabels, brainVoxels] = upsampleToTargetRes(pathRefImage, pathRefLabels,...
            targetResolution, multiChannel, margin, recompute);
    end
    
    % remove old hippocampus labels and add background
    [updatedLabelsList, updatedLabelsNames] = updateLabelsList(labelsList, labelsNames);
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' refBrainNum]);
    [pathSegmentation, pathHippoSegmentation] = labelFusion...
        (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, updatedLabelsList, ...
        freeSurferHome, niftyRegHome, debug);
    
    % evaluation
    disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' ');
    accuracies{i} = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, updatedLabelsList);
    
end

% save results
accuracy = saveAccuracy(accuracies, pathAccuracies, updatedLabelsList, updatedLabelsNames);

end