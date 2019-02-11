function [pathSegmentation, pathHippoSegmentation, cropping] = performLabelFusion...
    (pathRefImage, pathFirstRefLabels, pathDirFloatingImages, pathDirFloatingLabels, labelFusionParameters, freeSurferHome, niftyRegHome, debug)

% hardcoded parameters
labelsList = [0,2,3,4,5,7,8,10,11,12,13,14,15,16,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
cropImage = labelFusionParameters{1};
margin = labelFusionParameters{2};
rho = labelFusionParameters{3};
threshold = labelFusionParameters{4};
sigma = labelFusionParameters{5};
labelPriorType = labelFusionParameters{6};
deleteSubfolder = labelFusionParameters{7};
recompute = labelFusionParameters{8};
registrationOptions = labelFusionParameters{9};

% define paths of real image and corresponding labels
refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'.nii.gz')-1);

% handling paths
structPathsFloatingImages = dir(pathDirFloatingImages);
structPathsFloatingLabels = dir(pathDirFloatingLabels);
tempImageSubfolder = fileparts(structPathsFloatingLabels(1).folder);
mainFolder = fileparts(tempImageSubfolder);
hippoLabelsFolder = fullfile(tempImageSubfolder, 'hippo_labels_delta');
logOddsFolder = fullfile(tempImageSubfolder,'logOdds');
registrationFolder = fullfile(tempImageSubfolder, 'registrations');
preprocessedRefBrainFolder = fullfile(tempImageSubfolder, 'preprocessed_test_brain');
maskedTrainingImagesFolder = fullfile(tempImageSubfolder, 'training_images_masked');
segmentationsFolder = fullfile(mainFolder, 'segmentations', ['test_'  refBrainNum]);

% preparing the reference image for label fusion (masking and cropping)
[pathRefMaskedImage, ~, croppedRefMaskedImage, cropping] = prepareRefImageAndLabels(pathRefImage, pathFirstRefLabels, cropImage, margin, ...
    preprocessedRefBrainFolder, freeSurferHome);

% initialise matrix on which label fusion will be performed
% initialising with zeros to start image with background label
labelMap = zeros([size(croppedRefMaskedImage), length(labelsList)]);
labelMapHippo = zeros([size(croppedRefMaskedImage), 2]);

for i=1:length(structPathsFloatingImages)
    
    % paths of synthetic image and labels
    pathFloatingImage = fullfile(structPathsFloatingImages(i).folder, structPathsFloatingImages(i).name);
    pathFloatingLabels = fullfile(structPathsFloatingLabels(i).folder, structPathsFloatingLabels(i).name);
    floBrainNum = structPathsFloatingLabels(i).name(regexp(structPathsFloatingLabels(i).name,'brain'):regexp(structPathsFloatingLabels(i).name,'_labels')-1);
    disp(['% processing floating ' floBrainNum])
    
    %mask image if specified
    maskedTrainingImagesSubfolder = fullfile(maskedTrainingImagesFolder);
    pathFloatingImage = maskImage(pathFloatingImage, pathFloatingLabels, maskedTrainingImagesSubfolder, freeSurferHome);
    
    % compute logOdds or create hippocampus segmentation map (for delta function)
    logOddsSubfolder = fullfile(logOddsFolder, ['training_' floBrainNum]);
    pathFloatingHippoLabels = calculatePrior...
        (pathFloatingLabels, labelPriorType, hippoLabelsFolder, logOddsSubfolder, labelsList, rho, threshold, recompute, freeSurferHome);
    
    % registration of synthetic image to real image
    registrationSubFolder = fullfile(registrationFolder, ['training_' floBrainNum '_reg_to_test_' refBrainNum]);
    pathRegisteredFloatingImage = registerImage...
        (pathRefMaskedImage, pathFloatingImage, registrationSubFolder, registrationOptions, recompute, refBrainNum, floBrainNum, niftyRegHome, debug);
    
    % registration of loggOdds
    [registeredLogOddsSubFolder, pathRegisteredFloatingLabels, pathRegisteredFloatingHippoLabels] = registerLabels(pathFloatingLabels, pathFloatingHippoLabels,...
        pathRefMaskedImage, labelsList, logOddsSubfolder, registrationSubFolder, recompute, refBrainNum, floBrainNum, labelPriorType, niftyRegHome, debug);
    
    % perform summation of posterior on the fly
    [labelMap, labelMapHippo] = updateLabelMap(labelMap, labelMapHippo, croppedRefMaskedImage, pathRegisteredFloatingImage, pathRegisteredFloatingLabels, ...
        pathRegisteredFloatingHippoLabels, registeredLogOddsSubFolder, labelsList, cropping, sigma, labelPriorType);
    
end

[pathSegmentation, pathHippoSegmentation] = getSegmentation(labelMap, labelMapHippo, labelsList, segmentationsFolder, refBrainNum); % argmax operation

if deleteSubfolder, rmdir(tempImageSubfolder,'s'); end

end