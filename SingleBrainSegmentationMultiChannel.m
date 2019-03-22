function SingleBrainSegmentationMultiChannel(pathRefImageChannel1, pathRefImageChannel2, ...
    pathRefFirstLabelstChannel1, pathRefFirstLabelsChannel2,  ...
    pathResultPrefix, ...
    pathRefLabels, ...
    pathDirTrainingLabels, ...
    pathDirTrainingImagesChannel1, pathDirTrainingImagesChannel2, ...
    pathClassesTable, ...
    leaveOneOut, useSynthethicImages, recompute, id, debug, deleteSubfolder,...
    targetResolution, alignTestImages, rescale,...
    margin, rho, threshold, sigma, labelPriorType, ...
    registrationOptions, ...
    freeSurferHome, niftyRegHome,...
    evaluate)

now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% adds function paths
if isdeployed
    leaveOneOut = str2double(leaveOneOut);
    useSynthethicImages = str2double(useSynthethicImages);
    recompute = str2double(recompute);
    debug = str2double(debug);
    deleteSubfolder = str2double(deleteSubfolder);
    targetResolution = str2double(targetResolution);
    alignTestImages = str2double(alignTestImages);
    rescale = str2double(rescale);
    margin = str2double(margin);
    rho = str2double(rho);
    threshold = str2double(threshold);
    sigma = str2double(sigma);
else
    addpath(fullfile(freeSurferHome, 'matlab/'));
    addpath(genpath(pwd));
end

% read paths
pathRefImage = {pathRefImageChannel1 pathRefImageChannel2};
pathDirTrainingImages = {pathDirTrainingImagesChannel1 pathDirTrainingImagesChannel2};
pathRefFirstLabels = {pathRefFirstLabelstChannel1 pathRefFirstLabelsChannel2};
if ~exist('pathDirTrainingImages','var'), pathDirTrainingImages=''; end
[pathRefImage, pathRefFirstLabels, pathRefLabels, pathDirTrainingLabels, pathDirTrainingImages] = readPaths...
    (pathRefImage, pathRefFirstLabels, pathRefLabels, pathDirTrainingLabels, pathDirTrainingImages, useSynthethicImages, 1, evaluate);

% regroup parameters
params = {leaveOneOut useSynthethicImages recompute debug deleteSubfolder targetResolution rescale alignTestImages...
    margin rho threshold sigma labelPriorType registrationOptions freeSurferHome niftyRegHome, pathClassesTable};

%------------------------- equivalent of segment -------------------------%

% initialisation
nChannel = length(pathRefImage);
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
[leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, alignTestImages, margin, rho, threshold,...
    sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome, labelsList, labelClasses, labelsNames] = readParams(params, nChannel);

% display processed test brain
[refBrainNum, ~, pathTempImFolder] = createTempFolder(pathRefImage, id, recompute);
disp(['%%% Processing test ' refBrainNum]);

% build path resulting accuracies
pathRefLabels = pathRefLabels{1};
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder multiChannel recompute registrationOptions};

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
[pathRefImage, pathRefFirstLabels] = preprocessRefImage(pathRefImage, pathRefFirstLabels, pathTempImFolder, rescale, alignTestImages, ...
    refBrainNum, freeSurferHome, niftyRegHome, recompute, debug);

% floating images generation or preprocessing of real training images
if useSynthethicImages
    disp(' '); disp(['%% synthetising images for ' refBrainNum]);
    [pathDirFloatingImages, pathDirFloatingLabels] = generateTrainingImages(temp_pathDirTrainingLabels, labelsList, labelClasses,...
        pathRefImage, pathRefFirstLabels, pathTempImFolder, targetResolution, refBrainNum, recompute, freeSurferHome, niftyRegHome, debug);
else
    disp(' '); disp(['%% preprocessing real training images for ' refBrainNum]);
    [pathDirFloatingImages, pathDirFloatingLabels] = preprocessRealTrainingImages(temp_pathDirTrainingImages,...
        temp_pathDirTrainingLabels, pathRefImage, pathTempImFolder, targetResolution, nChannel, rescale, ...
        freeSurferHome, niftyRegHome, recompute, debug);
end

% upsample ref data to targetRes
[pathRefImage, pathRefLabels, brainVoxels] = upsampleToTargetRes(pathRefImage, pathRefLabels, pathTempImFolder, ...
    targetResolution, multiChannel, margin, refBrainNum, recompute, evaluate);

% remove old hippocampus labels and add background
[updatedLabelsList, ~] = updateLabelsList(labelsList, labelsNames);

% labelFusion
disp(' '); disp(['%% segmenting ' refBrainNum]);
[pathSegmentation, pathHippoSegmentation] = labelFusion...
    (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, updatedLabelsList, ...
    pathTempImFolder, pathResultPrefix, refBrainNum, freeSurferHome, niftyRegHome, debug);

% evaluation
if evaluate
    disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' ');
    pathAccuracies = [pathResultPrefix '.regions_accuracies.mat'];
    accuracies = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, updatedLabelsList);
    if ~exist(fileparts(pathAccuracies), 'dir'), mkdir(fileparts(pathAccuracies)); end
    save(pathAccuracies, 'accuracies');
end

%-------------------------------------------------------------------------%

tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));

if isdeployed, exit; end

end