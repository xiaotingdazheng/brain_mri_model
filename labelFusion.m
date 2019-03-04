function [pathSegm, pathHippoSegm] = labelFusion(pathRefImage, pathDirFloImages, pathDirFloLabels, brainVoxels, labelFusionParameters, ...
    freeSurferHome, niftyRegHome, debug)

% read parameters
labelsList = [0,2,3,4,5,7,8,10,11,12,13,14,15,16,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
rho = labelFusionParameters{1};
threshold = labelFusionParameters{2};
sigma = labelFusionParameters{3};
labelPriorType = labelFusionParameters{4};
deleteSubfolder = labelFusionParameters{5};
recompute = labelFusionParameters{6};
registrationOptions = labelFusionParameters{7};

% define paths of real image and corresponding labels
refBrainNum = findBrainNum(pathRefImage);

% handling paths floating data
if ~contains(pathDirFloImages, '*'), pathDirFloImages = fullfile(pathDirFloImages, '*nii.gz'); end
if ~contains(pathDirFloLabels, '*'), pathDirFloLabels = fullfile(pathDirFloLabels, '*nii.gz'); end
structPathsFloImages = dir(pathDirFloImages);
structPathsFloLabels = dir(pathDirFloLabels);
% define subfolders
tempImageSubfolder = fileparts(fileparts(pathRefImage));
mainFolder = fileparts(tempImageSubfolder);
registrationFolder = fullfile(tempImageSubfolder, 'registrations');
segmentationsFolder = fullfile(mainFolder, 'segmentations', ['test_'  refBrainNum]);
if isequal(labelPriorType, 'delta function')
    priorFolder = fullfile(tempImageSubfolder, 'hippo_labels_delta');
else
    priorFolder = fullfile(tempImageSubfolder,'logOdds');
end

% initialise label maps fusion with zeros (background label)
labelMap = zeros(length(labelsList), length(brainVoxels), 'single');
labelMapHippo = zeros(2, length(brainVoxels), 'single');

for i=1:length(structPathsFloImages)
    
    % paths of synthetic image and labels
    pathFloImage = fullfile(structPathsFloImages(i).folder, structPathsFloImages(i).name);
    pathFloLabels = fullfile(structPathsFloLabels(i).folder, structPathsFloLabels(i).name);
    
    floBrainNum = findBrainNum(pathFloLabels);
    disp(['% processing floating ' floBrainNum])
    
    % compute logOdds or create hippocampus segmentation map (for delta function)
    priorSubfolder = fullfile(priorFolder, ['training_' floBrainNum]);
    calculatePrior(pathFloLabels, labelPriorType, priorSubfolder, labelsList, rho, threshold, recompute, freeSurferHome);
    
    % registration of synthetic image to real image
    registrationSubfolder = fullfile(registrationFolder, ['training_' floBrainNum '_reg_to_test_' refBrainNum]);
    pathRegFloImage = registerImage(pathRefImage, pathFloImage, registrationSubfolder, registrationOptions, recompute, niftyRegHome, debug);
    
    % registration of priors
    regPriorSubfolder = registerLabels(pathFloLabels, priorSubfolder, pathRefImage, registrationSubfolder, labelPriorType, labelsList,...
        niftyRegHome, recompute, debug);
    
    % perform summation of posterior on the fly
    [labelMap, labelMapHippo, sizeSegmMap] = updateLabelMaps(labelMap, labelMapHippo, pathRefImage, pathRegFloImage, regPriorSubfolder, ...
        labelPriorType, brainVoxels, sigma, labelsList);

end

% get most likely segmentation
[pathSegm, pathHippoSegm] = getSegmentations(labelMap, labelMapHippo, segmentationsFolder, pathRefImage, brainVoxels, labelsList, sizeSegmMap);

% delete temp subfolder if specified
if deleteSubfolder, rmdir(tempImageSubfolder,'s'); end

end