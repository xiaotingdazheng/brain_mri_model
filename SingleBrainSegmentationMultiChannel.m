function SingleBrainSegmentationMultiChannel(pathRefImaget1, pathRefImaget2, pathRefLabels, pathRefFirstLabelst1, pathRefFirstLabelst2,  ...
    pathDirTrainingLabels, pathDirTrainingImages, pathClassesTable, ...
    leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder,...
    targetResolution, alignTestImages, rescale,...
    margin, rho, threshold, sigma, labelPriorType, ...
    registrationOptions, ...
    freeSurferHome, niftyRegHome)

now = clock;
fprintf('Started on %d/%d at %dh%02d\n', now(3), now(2), now(4), now(5)); disp(' ');
tic

%%%%%%% general parameters
% leaveOneOut                 % evaluate one image with the rest of the datatset (0-1)
% useSynthethicImages         % use real or synthetic images (0-1)
% recompute                   % recompute files, even if they exist (0-1)
% debug                       % display debug information from registrations (0-1)
% deleteSubfolder             % delete subfolder after having segmented an image (0-1)
%%%%%%% preprocessing parameters
% targetResolution            % resolution of synthetic images
% alignTestImages             % align multi-channel test images, (0=no, 1=rigid reg, 2=rl)
% rescale = 1;                % rescale intensities between 0 and 255 (0-1)
%%%%%%% label fusion parameters
% margin = 10;                % margin for brain voxels selection
% rho = 0.5;                  % exponential decay for logOdds maps
% threshold = 0.1;            % lower bound for logOdds maps
% sigma = 15;                 % var for Gaussian likelihood
% labelPriorType = 'logOdds'; % type of prior ('logOdds' or 'delta function')
% registrationOptions         % label fusion registrations options (weights are automated)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% adds function paths
if ~isdeployed
    addpath(fullfile(freeSurferHome, 'matlab/'));
    addpath(genpath(pwd));
else
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
end

% read paths
pathRefImage = {pathRefImaget1 pathRefImaget2};
pathRefFirstLabels = {pathRefFirstLabelst1 pathRefFirstLabelst2};
if ~exist('pathDirTrainingImages','var'), pathDirTrainingImages=''; end
[pathRefImage, pathRefFirstLabels, pathRefLabels, pathDirTrainingLabels, pathDirTrainingImages] = readPaths...
    (pathRefImage, pathRefFirstLabels, pathRefLabels, pathDirTrainingLabels, pathDirTrainingImages, useSynthethicImages);

% regroup parameters
params = {leaveOneOut useSynthethicImages recompute debug deleteSubfolder targetResolution rescale alignTestImages...
    margin rho threshold sigma labelPriorType registrationOptions freeSurferHome niftyRegHome, pathClassesTable};

%------------------------- equivalent of segment -------------------------%

% display processed test brain
refBrainNum = findBrainNum(pathRefImage{1});
disp(['%%% Processing test ' refBrainNum]);

% initialisation
nChannel = length(pathRefImage);
if nChannel > 1, multiChannel = 1; else, multiChannel = 0; end
[leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, alignTestImages, margin, rho, threshold,...
    sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome, labelsList, labelClasses, labelsNames] = readParams(params, nChannel);
% build path resulting accuracies
pathRefLabels = pathRefLabels{1};
pathMainFolder = fileparts(fileparts(pathRefImage{1}));
pathAccuracies = fullfile(pathMainFolder, 'accuracies', ['accuracy_' refBrainNum '.mat']);
if ~exist(fileparts(pathAccuracies), 'dir'), mkdir(fileparts(pathAccuracies)); end
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder multiChannel recompute registrationOptions};

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
    [pathRefImage, pathRefLabels, brainVoxels] = upsampleToTargetRes(pathRefImage, pathRefLabels, targetResolution, multiChannel, margin);
end

% remove old hippocampus labels and add background
[updatedLabelsList, ~] = updateLabelsList(labelsList, labelsNames);

% labelFusion
disp(' '); disp(['%% segmenting ' refBrainNum]);
[pathSegmentation, pathHippoSegmentation] = labelFusion...
    (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, updatedLabelsList, ...
    freeSurferHome, niftyRegHome, debug);

% evaluation
disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' ');
accuracies = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels, updatedLabelsList);
save(pathAccuracies, 'accuracies');

%-------------------------------------------------------------------------%

tEnd = toc; fprintf('Elapsed time is %dh %dmin\n', floor(tEnd/3600), floor(rem(tEnd,3600)/60));

if isdeployed, exit; end

end