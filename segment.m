function accuracy = segment(pathDirTestImages, pathDirRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages, params)

% read and check parameters
nChannel = length(pathDirTestImages);
[evaluate, cropHippo, leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, alignTestImages, margin, rho, threshold,...
    sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome, labelsList, labelClasses, labelsNames] = readParams(params, nChannel, 1);
% build paths structures
structPathsTestImages = cell(size(pathDirTestImages));
structPathsFirstRefLabels = cell(size(pathDirRefFirstLabels));
for i=1:length(pathDirTestImages), structPathsTestImages{i} = dir(pathDirTestImages{i}); end
for i=1:length(pathDirRefFirstLabels), structPathsFirstRefLabels{i} = dir(pathDirRefFirstLabels{i}); end
structPathsRefLabels = dir(pathDirTestLabels{1});
% build path resulting accuracies
pathMainFolder = fileparts(structPathsRefLabels(1).folder);
% parameters initialisation
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
nImages = length(structPathsTestImages{1});
accuracies = cell(nImages,1);
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder  multiChannel recompute registrationOptions};

for i=1:nImages
    
    % paths of reference image and corresponding FS labels
    [pathRefImage, pathRefFirstLabels, pathRefLabels, refBrainNum] = buildRefPaths(structPathsTestImages,...
        structPathsFirstRefLabels, structPathsRefLabels, i);
    pathTempImFolder = fullfile(pathMainFolder, ['temp_' refBrainNum]);
    if ~exist(pathTempImFolder,'dir'), mkdir(pathTempImFolder); end
    pathResultPrefix = fullfile(pathMainFolder, 'results', refBrainNum, refBrainNum);
    
    % display processed test brain
    disp(' '); disp(['%%% Processing test ' refBrainNum]);
    
    % copies training labels to temp folder and erase labels corresponding to test image
    disp(' '); disp('%% copying training data');
    if ~useSynthethicImages
        temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, pathTempImFolder, refBrainNum, 1, 'labels', freeSurferHome, recompute, leaveOneOut);
        temp_pathDirTrainingImages = copyTrainingData(pathDirTrainingImages, pathTempImFolder, refBrainNum, nChannel, 'images', freeSurferHome, recompute, leaveOneOut);
    else
        temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, pathTempImFolder, refBrainNum, 1, 'labels', freeSurferHome, recompute, leaveOneOut);
        temp_pathDirTrainingImages = pathDirTrainingImages;
    end
    
    % preprocessing test image
    disp(' '); if multiChannel, disp(['%% preprocessing test ' refBrainNum ' images ']); else, disp(['%% preprocessing test ' refBrainNum]); end
    [pathRefImage, pathRefFirstLabels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, pathTempImFolder, rescale, ...
        alignTestImages, refBrainNum, freeSurferHome, niftyRegHome, recompute, debug);
    
    % floating images generation or preprocessing of real training images
    if useSynthethicImages
        disp(' '); disp(['%% synthetising images for ' refBrainNum]);
        [pathDirFloatingImages, pathDirFloatingLabels] = generateTrainingImages(temp_pathDirTrainingLabels, labelsList, labelClasses,...
            pathRefImage, pathRefFirstLabels, pathTempImFolder, targetResolution, refBrainNum, recompute, freeSurferHome, niftyRegHome, debug);
    else
        disp(' '); disp(['%% preprocessing real training images for ' refBrainNum]);
        [pathDirFloatingImages, pathDirFloatingLabels] = preprocessRealTrainingImages(temp_pathDirTrainingImages,...
            temp_pathDirTrainingLabels, pathRefImage, pathTempImFolder, targetResolution, nChannel, rescale, freeSurferHome, niftyRegHome, recompute, debug);
    end
    
    % upsample ref data to targetRes
    disp(' '); disp('%% resampling test image to target resolution');
    [pathRefImage, pathRefLabels, brainVoxels, cropping] = upsampleToTargetRes(pathRefImage, pathRefLabels, pathRefFirstLabels, pathTempImFolder, ...
        targetResolution, multiChannel, margin, recompute, evaluate, cropHippo);
    
    % remove old hippocampus labels and add background
    [updatedLabelsList, updatedLabelsNames] = updateLabelsList(labelsList, labelsNames);
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' refBrainNum]);
    [pathSegmentation, pathHippoSegmentation] = labelFusion...
        (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, updatedLabelsList, updatedLabelsNames, ...
        pathTempImFolder, pathResultPrefix, refBrainNum, cropping, freeSurferHome, niftyRegHome, debug);
    
    % evaluation
    if evaluate
        disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' ');
        accuracies{i} = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, updatedLabelsList, pathTempImFolder, cropping);
        % save regions accuracies of current brain in text file
        brainAccuracies = mat2str(accuracies{i});
        pathBrainAccuracies = [pathResultPrefix '.regions_accuracies.txt'];
        if ~exist(fileparts(pathBrainAccuracies), 'dir'), mkdir(fileparts(pathBrainAccuracies)); end
        save(pathBrainAccuracies, 'brainAccuracies');
    end
end

if evaluate
    % save results
    pathAccuracies = fullfile(pathMainFolder, 'accuracy.mat');
    accuracy = saveAccuracy(accuracies, pathAccuracies, updatedLabelsList, updatedLabelsNames);
end

end