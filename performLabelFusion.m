function [labelMap, labelMapHippo] = performLabelFusion(pathRefImage, pathFirstRefLabels, pathDirFloatingImages, pathDirFloatingLabels, cropImage)

% hardcoded parameters
labelsList = [0,2,3,4,5,7,8,10,11,12,13,14,15,16,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
margin = 30;
rho = 0.5;
threshold = 0.3;
sigma = 15;
labelPriorType = 'logOdds';

% handling paths
structPathsFloatingImages = dir(pathDirFloatingImages);
structPathsFloatingLabels = dir(pathDirFloatingLabels);
pathTempImageSubfolder = fileparts(structPathsFloatingLabels(1).folder);
logOddsFolder = fullfile(pathTempImageSubfolder,'logOdds');
registrationFolder = fullfile(pathTempImageSubfolder, 'registrations');
preprocessedRefBrainFolder = fullfile(pathTempImageSubfolder, 'preprocessed_test_brain');
maskedTrainingImagesFolder = fullfile(pathTempImageSubfolder, 'training_images_masked');

% define paths of real image and corresponding labels
refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'.nii.gz')-1);

% preparing the reference image for label fusion (masking and cropping)
[pathRefMaskedImage, ~, croppedRefMaskedImage, cropping] = prepareRefImageAndLabels(pathRefImage, pathFirstRefLabels, cropImage, margin, preprocessedRefBrainFolder);

% initialise matrix on which label fusion will be performed
% initialising with zeros to start image with background label
labelMap = zeros([size(croppedRefMaskedImage), length(labelsList)]);
labelMapHippo = zeros([size(croppedRefMaskedImage), 2]);

for i=1:length(structPathsFloatingImages)
    
    % paths of synthetic image and labels
    pathFloatingImage = fullfile(structPathsFloatingImages(i).folder, structPathsFloatingImages(i).name);
    pathFloatingLabels = fullfile(structPathsFloatingLabels(i).folder, structPathsFloatingLabels(i).name);
    floBrainNum = pathFloatingLabels(regexp(pathFloatingLabels,'brain'):regexp(pathFloatingLabels,'.')-1);
    disp(['%% processing floating image ',floBrainNum, ' %%'])
    
    %mask image if specified
    maskedTrainingImagesSubfolder = fullfile(maskedTrainingImagesFolder);
    pathFloatingImage = maskImage(pathFloatingImage, pathFloatingLabels, maskedTrainingImagesSubfolder, recomputeMaskFloatingImages);
    
    % compute logOdds or create hippocampus segmentation map (for delta function)
    logOddsSubfolder = fullfile(logOddsFolder, ['training_' floBrainNum]);
    pathFloatingHippoLabels = calculatePrior(labelPriorType, pathFloatingLabels, logOddsSubfolder, rho, threshold, labelsList, resultsFolder, recompute);
    
    % registration of synthetic image to real image
    registrationSubFolder = fullfile(registrationFolder, ['training_' floBrainNum 'reg_to_test_' refBrainNum]);
    pathRegisteredFloatingImage = registerImage(pathRefMaskedImage, pathFloatingImage, registrationSubFolder, recompute, refBrainNum, floBrainNum);
    
    % registration of loggOdds
    [registeredLogOddsSubFolder, pathRegisteredFloatingLabels, pathRegisteredFloatingHippoLabels] = registerLabels(pathFloatingLabels, pathFloatingHippoLabels,...
        pathRefMaskedImage, labelsList, pathlogOddsSubfolder, registrationSubFolder, recompute, refBrainNum, floBrainNum);
    
    % perform summation of posterior on the fly
    disp('cropping registered floating labels and updating sum of posteriors'); disp(' ');
    [labelMap, labelMapHippo] = updateLabelMap(labelMap, labelMapHippo, croppedRefMaskedImage, pathRegisteredFloatingImage, pathRegisteredFloatingLabels, ...
        pathRegisteredFloatingHippoLabels, registeredLogOddsSubFolder, labelsList, cropping, sigma, labelPriorType, refBrainNum, floBrainNum, croppedRefLabels);
    
end

disp('finding most likely segmentation and calculating corresponding accuracy'); disp(' '); disp(' ');
[labelMap, labelMapHippo] = getSegmentation(labelMap, labelMapHippo, labelsList, resultsFolder, refBrainNum); % argmax operation

end