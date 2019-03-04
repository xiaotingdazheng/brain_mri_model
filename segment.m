function accuracy = segment(pathDirTestImages, pathDirRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages, pathClassesTable, params)

% initialisation
structPathsTestImages = dir(pathDirTestImages);
structPathsFirstRefLabels = dir(pathDirRefFirstLabels);
structPathsRefLabels = dir(pathDirTestLabels);
accuracies = cell(length(structPathsTestImages),1);
[leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, margin, rho,...
   threshold, sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome] = readParams(params);
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};


for i=1:length(structPathsTestImages)
    
    % paths of reference image and corresponding FS labels
    pathRefImage = fullfile(structPathsTestImages(i).folder, structPathsTestImages(i).name);
    pathRefFirstLabels = fullfile(structPathsFirstRefLabels(i).folder, structPathsFirstRefLabels(i).name);
    pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
    
    % display processed test brain
    refBrainNum = findBrainNum(pathRefImage);
    disp(['%%% Processing test ' refBrainNum]);
    
    % copies training labels to temp folder and erase labels corresponding to test image
    if leaveOneOut && ~useSynthethicImages
        temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum);
        temp_pathDirTrainingImages = copyTrainingData(pathDirTrainingImages, refBrainNum);
    elseif leaveOneOut && useSynthethicImages
        temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum);
        temp_pathDirTrainingImages = pathDirTrainingImages;
    else
        temp_pathDirTrainingLabels = pathDirTrainingLabels;
        temp_pathDirTrainingImages = pathDirTrainingImages;
    end

    % preprocessing test image
    disp(' '); disp(['%% preprocessing test ' refBrainNum]);
    [pathRefImage, brainVoxels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, rescale, recompute, margin, freeSurferHome);
    
    % floating images generation or preprocessing of real training images
    if useSynthethicImages
        disp(['%% synthetising images for ' refBrainNum]);
        [pathDirFloatingImages, pathDirFloatingLabels] = generateTrainingImages(temp_pathDirTrainingLabels, pathClassesTable, pathRefImage, ...
            pathRefFirstLabels, targetResolution, recompute, freeSurferHome, niftyRegHome, debug);
    else 
        disp('%% preprocessing real training images');
        [pathDirFloatingImages, pathDirFloatingLabels] = preprocessRealTrainingImages(temp_pathDirTrainingImages, temp_pathDirTrainingLabels, ...
            pathRefImage, targetResolution, rescale, recompute, freeSurferHome);
    end
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' refBrainNum])
    [pathSegmentation, pathHippoSegmentation] = labelFusion...
        (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, freeSurferHome, niftyRegHome, debug);
    
    % evaluation
    disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' '); disp(' ');
    accuracies{i} = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels);
    
end

pathAccuracies = fullfile(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);

end