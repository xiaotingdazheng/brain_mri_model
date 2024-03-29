function SingleBrainSegmentation(pathRefImage, ...
    pathRefFirstLabels, ...
    pathResultPrefix, ...
    pathRefLabels, ...
    pathDirTrainingLabels, ...
    pathDirTrainingImages, ...
    pathClassesTable, ...
    evaluate, cropHippo, ...
    leaveOneOut, useSynthethicImages, debug, deleteSubfolder,...
    targetResolution, alignTestImages, rescale,...
    margin, rho, threshold, sigma, labelPriorType, ...
    registrationOptions, ...
    freeSurferHome, niftyRegHome)

now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% adds function paths
if isdeployed
    evaluate = str2double(evaluate);
    cropHippo = str2double(cropHippo);
    leaveOneOut = str2double(leaveOneOut);
    useSynthethicImages = str2double(useSynthethicImages);   
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
if ~exist('pathDirTrainingImages','var'), pathDirTrainingImages=''; end
if ~exist('pathRefLabels','var'), pathRefLabels=''; end
[pathRefImage, pathRefFirstLabels, pathRefLabels, pathDirTrainingLabels, pathDirTrainingImages] = readPaths...
    (pathRefImage, pathRefFirstLabels, pathRefLabels, pathDirTrainingLabels, pathDirTrainingImages, useSynthethicImages, 1, evaluate);

% regroup parameters
recompute = 1;
params = {evaluate cropHippo leaveOneOut useSynthethicImages recompute debug deleteSubfolder targetResolution rescale alignTestImages...
    margin rho threshold sigma labelPriorType registrationOptions freeSurferHome niftyRegHome pathClassesTable};

%------------------------- equivalent of segment -------------------------%

% initialisation
nChannel = length(pathRefImage);
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
[evaluate, cropHippo, leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, ...
    alignTestImages, margin, rho, threshold, sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome, ...
    labelsList, labelClasses, labelsNames] = readParams(params, nChannel, 1);

% display processed test brain
[refBrainNum, pathTempImFolder] = createTempFolder(pathResultPrefix);
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
disp(' '); if multiChannel, disp(['%% preprocessing test ' refBrainNum ' images ']);
else, disp(['%% preprocessing test ' refBrainNum]); end
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
        temp_pathDirTrainingLabels, pathRefImage, pathTempImFolder, targetResolution, nChannel, rescale, freeSurferHome, ...
        niftyRegHome, recompute, debug);
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
    pathAccuracies = [pathResultPrefix '.regions_accuracies.mat'];
    accuracies = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, updatedLabelsList, pathTempImFolder, cropping);
    if ~exist(fileparts(pathAccuracies), 'dir'), mkdir(fileparts(pathAccuracies)); end
    save(pathAccuracies, 'accuracies');
end

%-------------------------------------------------------------------------%

tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));

if isdeployed, exit; end

end
