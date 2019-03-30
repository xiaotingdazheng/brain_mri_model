function [pathSegm, pathHippoSegm] = labelFusion(cellPathsRefImage, pathDirFloImages, pathDirFloLabels, brainVoxels, ...
    labelFusionParameters, labelsList, labelsNames, pathTempImFolder, pathResultPrefix, refBrainNum, cropping, freeSurferHome, niftyRegHome, debug)

% read parameters
rho = labelFusionParameters{1};
threshold = labelFusionParameters{2};
sigma = labelFusionParameters{3};
labelPriorType = labelFusionParameters{4};
deleteSubfolder = labelFusionParameters{5};
multiChannel = labelFusionParameters{6};
recompute = labelFusionParameters{7};
registrationOptions = labelFusionParameters{8};

% handling paths floating data
if ~contains(pathDirFloImages, '*'), pathDirFloImages = fullfile(pathDirFloImages, '*nii.gz'); end
if ~contains(pathDirFloLabels, '*'), pathDirFloLabels = fullfile(pathDirFloLabels, '*nii.gz'); end
structPathsFloImages = dir(pathDirFloImages);
structPathsFloLabels = dir(pathDirFloLabels);
% define subfolders
registrationFolder = fullfile(pathTempImFolder, 'registrations');
labelMapFolder = fullfile(pathTempImFolder, 'labelMaps');
if isequal(labelPriorType, 'delta function'), priorFolder = fullfile(pathTempImFolder, 'hippo_labels_delta');
else, priorFolder = fullfile(pathTempImFolder,'logOdds'); end


for i=1:length(structPathsFloImages)
    
    % paths of synthetic image and labels
    pathRefImage = cellPathsRefImage{end};
    pathFloImage = fullfile(structPathsFloImages(i).folder, structPathsFloImages(i).name);
    pathFloLabels = fullfile(structPathsFloLabels(i).folder, structPathsFloLabels(i).name);
    
    floBrainNum = findBrainNum(pathFloLabels);
    disp(['% processing floating ' floBrainNum])
    
    % compute logOdds or create hippocampus segmentation map (for delta function)
    priorSubfolder = fullfile(priorFolder, ['training_' floBrainNum]);
    calculatePrior(pathFloLabels, labelPriorType, priorSubfolder, labelsList, rho, threshold, pathTempImFolder, recompute, freeSurferHome);
    
    % registration of synthetic image to real image
    registrationSubfolder = fullfile(registrationFolder, ['training_' floBrainNum '_reg_to_test_' refBrainNum]);
    [pathRegFloImage, priorSubfolder, pathRefImage, brainVoxels] = registerImage(pathRefImage, pathFloImage, registrationSubfolder, registrationOptions,...
        multiChannel, brainVoxels, recompute, refBrainNum, cropping, priorSubfolder, niftyRegHome, debug);

    % registration of priors
    regPriorSubfolder = registerLabels(pathFloLabels, priorSubfolder, pathRefImage, registrationSubfolder, labelPriorType, labelsList,...
        refBrainNum, niftyRegHome, recompute, debug);
    
    % compute likelihood
    [likelihood, sizeSegmMap] = calculateLikelihood(pathRefImage, pathRegFloImage, pathTempImFolder, sigma);
    
    % perform summation of posterior on the fly
    updateLabelMaps(likelihood, regPriorSubfolder, labelPriorType, brainVoxels, labelsList, pathTempImFolder, labelMapFolder, i);

end

% pathSegm ='';
% pathHippoSegm='';
% get most likely segmentation
[pathSegm, pathHippoSegm] = getSegmentations(pathResultPrefix, pathRefImage, brainVoxels, labelsList, labelsNames, sizeSegmMap, pathTempImFolder, labelMapFolder);

% delete temp subfolder if specified
if deleteSubfolder, rmdir(pathTempImFolder,'s'); end

end