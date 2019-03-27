function [pathSegm, pathHippoSegm] = labelFusion(pathRefImage, pathDirFloImages, pathDirFloLabels, brainVoxels, ...
    labelFusionParameters, labelsList, labelsNames, pathTempImFolder, pathResultPrefix, refBrainNum, freeSurferHome, niftyRegHome, debug)

% read parameters
rho = labelFusionParameters{1};
threshold = labelFusionParameters{2};
sigma = labelFusionParameters{3};
labelPriorType = labelFusionParameters{4};
deleteSubfolder = labelFusionParameters{5};
multiChannel = labelFusionParameters{6};
recompute = labelFusionParameters{7};
registrationOptions = labelFusionParameters{8};

% define paths of real image and corresponding labels
pathRefImage = pathRefImage{end};

% handling paths floating data
if ~contains(pathDirFloImages, '*'), pathDirFloImages = fullfile(pathDirFloImages, '*nii.gz'); end
if ~contains(pathDirFloLabels, '*'), pathDirFloLabels = fullfile(pathDirFloLabels, '*nii.gz'); end
structPathsFloImages = dir(pathDirFloImages);
structPathsFloLabels = dir(pathDirFloLabels);
% define subfolders
registrationFolder = fullfile(pathTempImFolder, 'registrations');
if isequal(labelPriorType, 'delta function'), priorFolder = fullfile(pathTempImFolder, 'hippo_labels_delta');
else, priorFolder = fullfile(pathTempImFolder,'logOdds'); end

% initialise label maps fusion with zeros (background label)
labelMap = zeros(length(labelsList), length(brainVoxels{1}), 'single');
labelMapHippo = zeros(3, length(brainVoxels{1}), 'single');

for i=1:length(structPathsFloImages)
    
    % paths of synthetic image and labels
    pathFloImage = fullfile(structPathsFloImages(i).folder, structPathsFloImages(i).name);
    pathFloLabels = fullfile(structPathsFloLabels(i).folder, structPathsFloLabels(i).name);
    
    floBrainNum = findBrainNum(pathFloLabels);
    disp(['% processing floating ' floBrainNum])
    
    % compute logOdds or create hippocampus segmentation map (for delta function)
    priorSubfolder = fullfile(priorFolder, ['training_' floBrainNum]);
    calculatePrior(pathFloLabels, labelPriorType, priorSubfolder, labelsList, rho, threshold, pathTempImFolder, recompute, freeSurferHome);
    
    % registration of synthetic image to real image
    registrationSubfolder = fullfile(registrationFolder, ['training_' floBrainNum '_reg_to_test_' refBrainNum]);
    pathRegFloImage = registerImage(pathRefImage, pathFloImage, registrationSubfolder, registrationOptions, multiChannel, brainVoxels,...
        recompute, refBrainNum, niftyRegHome, debug);

    % registration of priors
    regPriorSubfolder = registerLabels(pathFloLabels, priorSubfolder, pathRefImage, registrationSubfolder, labelPriorType, labelsList,...
        refBrainNum, niftyRegHome, recompute, debug);
    
    % compute likelihood
    calculateLikelihood
    
    % perform summation of posterior on the fly
    [likelihood, sizeSegmMap] = calculateLikelihood(pathRefImage, pathRegFloImage, pathTempImFolder, sigma);
    [labelMap, labelMapHippo] = updateLabelMaps(labelMap, labelMapHippo, likelihood, regPriorSubfolder, labelPriorType, ...
        brainVoxels, labelsList, pathTempImFolder);

end

% get most likely segmentation
[pathSegm, pathHippoSegm] = getSegmentations(labelMap, labelMapHippo, pathResultPrefix, pathRefImage, brainVoxels, labelsList, ...
    labelsNames, sizeSegmMap, pathTempImFolder);

% delete temp subfolder if specified
if deleteSubfolder, rmdir(pathTempImFolder,'s'); end

end