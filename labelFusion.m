clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
% path to main datafolder
pathDataFolder = '/home/benjamin/data/CobraLab/';
%pathDataFolder = '/home/benjamin/data/OASIS-TRT-20/';

%pathDirFloatingImages = '~/data/CobraLab/synthetic_images_and_labels/*smoothed_twice.nii.gz';
pathDirFloatingImages = '~/data/CobraLab/original_images/*.nii.gz';
pathDirLabels = '~/data/CobraLab/synthetic_images_and_labels/*smoothed_twice.labels.nii.gz';
pathDirRefImages = '~/data/CobraLab/original_images/*.nii.gz';

%pathDirFloatingImages = '~/data/OASIS-TRT-20/synthetic_images_and_labels/*smoothed_once.nii.gz';
% pathDirFloatingImages = '~/data/OASIS-TRT-20/original_images/*.nii.gz';
% pathDirLabels = '~/data/OASIS-TRT-20/synthetic_images_and_labels/*labels.nii.gz';
% pathDirRefImages = '~/data/OASIS-TRT-20/original_images/*.nii.gz';

% set recompute to 1 to recompute all the masks and registrations (saved in
% automatically generated folder '~/data/label_fusion_date_time'. If
% recompute = 0, specify where is the data to be used.
recompute = 1;

% apply masking to images
cropAll = 1;                     % apply cropping to all images and labels (0 or 1)

% label fusion parameter
sigma = 15;                    % std dev of gaussian similarity meaure
margin = 30;                   % margin introduced when hippocampus are cropped
labelPriorType = 'logOdds';    % 'delta function' or 'logOdds'
rho = 0.5;                     % exponential decay for prob logOdds
threshold = 0.3;               % threshold for prob logOdds


%%%%%%%%%%%%%%%%%%%%%%%%%%%% initialisation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% folders handling
now = clock;
if contains(pathDirFloatingImages,'original'), realOrSynthetic = 'real'; else, realOrSynthetic = 'synthetic'; end
if contains(pathDirLabels,'smoothed')
    smoothingName = ['_', pathDirLabels(regexp(pathDirLabels,'smoothed'):regexp(pathDirLabels,'.labels.nii.gz')-1)];
else
    smoothingName = '';
end
resultsFolder = fullfile(pathDataFolder,['label_fusion_' num2str(now(3)) '_' num2str(now(2)) '_' num2str(now(4)) '_' num2str(now(5))]);
if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder), end % create result folder
pathAccuracies = fullfile(resultsFolder, 'LabelFusionAccuracy.mat'); % accuracies will be saved here
if isequal(smoothingName,'')
    logOddsFolder = fullfile(pathDataFolder,'logOdds',['logOdds_', realOrSynthetic]);
else
    logOddsFolder = fullfile(pathDataFolder,'logOdds',['logOdds_', realOrSynthetic, smoothingName]);
end
registrationFolder = fullfile(pathDataFolder,'registrations',['registrations_', realOrSynthetic, smoothingName]);
maskedImageFolder = fullfile(pathDataFolder, 'masked_images');
croppedFolder = fullfile(pathDataFolder,'cropped_images_and_labels',['croppings_', realOrSynthetic, smoothingName]);
if ~exist(croppedFolder, 'dir') && cropAll, mkdir(croppedFolder), end

% listing images and labels
structPathsFloatingImages = dir(pathDirFloatingImages);
structPathsLabels = dir(pathDirLabels);
structPathsRefImages = dir(pathDirRefImages);

% region names and associated labels
namesList = {'background';'left cerebral WM';'left cerebral cortex';'left lateral ventricule';'left inferior lateral ventricule';...
    'left cerebellum WM';'left cerebellum cortex';'left thalamus proper';'left caudate';'left putamen';...
    'left pallidum';'3rd ventricule';'4th ventricule';'brain stem';'left amygdala';...
    'CSF';'left accumbens area';'left ventral DC';'left vessel';'left choroid plexus';'right cerebral WM';...
    'right cerebral cortex';'right lateral ventricule';'right inferior lateral ventricule';'right cerebellum WM';...
    'right cerebellum cortex';'right thalamus proper';'right caudate';'right putamen';'right pallidum';...
    'right amygdala';'right accumbens area';'right ventral DC';'right vessel';'right choroid plexus';...
    'optic chiasm';'CC posterior';'CC mid posterior';'CC central';'CC mid anterior';'CC anterior';'R CA1';...
    'R  subiculum';'R CA4DG';'R CA3';'R molecular layer';'L CA1';'L subiculum';'L CA4DG';'L CA3';...
    'L molecular layer';'hippocampus'};
labelsList = [0,2,3,4,5,7,8,10,11,12,13,14,15,16,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];

% leave one out indices
n_training_data = length(structPathsLabels);
leaveOneOutIndices = nchoosek(1:n_training_data,n_training_data-1);
refIndex = n_training_data:-1:1;

% result matrix
accuracies = NaN(n_training_data, length(labelsList) + 1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% procedure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% test label fusion on each real image
for i=1:size(leaveOneOutIndices,1)
    
    % define paths of real image and corresponding labels
    pathRefImage = fullfile(structPathsRefImages(refIndex(i)).folder, structPathsRefImages(refIndex(i)).name); %path of real image
    pathRefLabels = fullfile(structPathsLabels(refIndex(i)).folder, structPathsLabels(refIndex(i)).name);
    refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'.nii.gz')-1);
    disp(['%%%%% testing label fusion on ',refBrainNum, ' %%%%%']); disp(' ');
    
    % preparing the reference image for label fusion (masking and cropping)
    [pathRefMaskedImage, croppedRefLabels, croppedRefMaskedImage, cropping] = prepareRefImageAndLabels(pathRefImage, pathRefLabels, margin, croppedFolder);
    
    % initialise matrix on which label fusion will be performed
    % initialising with zeros to start image with background label
    labelMap = zeros([size(croppedRefLabels), length(labelsList)]);
    labelMapHippo = zeros([size(croppedRefLabels), 2]);
    
    % registration and similarity between ref image and each synthetic image in turn
    for j=1:size(leaveOneOutIndices,2)
        
        % paths of synthetic image and labels
        leftOutIdx = leaveOneOutIndices(i,j);
        pathFloatingImage = fullfile(structPathsFloatingImages(leftOutIdx).folder, structPathsFloatingImages(leftOutIdx).name);
        pathFloatingLabels = fullfile(structPathsLabels(leftOutIdx).folder, structPathsLabels(leftOutIdx).name);
        floBrainNum = pathFloatingLabels(regexp(pathFloatingLabels,'brain'):regexp(pathFloatingLabels,'.')-1);
        disp(['%% processing floating image ',floBrainNum, ' %%'])
        
        %mask image if specified
        pathFloatingImage = maskImage(pathFloatingImage, pathFloatingLabels, maskedImageFolder);
        
        % compute logOdds or create hippocampus segmentation map (for delta function)
        logOddsSubfolder = fullfile(logOddsFolder, floBrainNum);
        pathFloatingHippoLabels = calculatePrior(pathFloatingLabels, labelPriorType, resultsFolder, logOddsSubfolder, labelsList, rho, threshold, recompute);
        
        % registration of synthetic image to real image
        registrationSubFolder = fullfile(registrationFolder, [floBrainNum, 'registered_to_', refBrainNum]);
        [pathRegisteredFloatingImage, pathTransformation] = registerImage(pathRefMaskedImage, pathFloatingImage, registrationSubFolder,...
            recompute, refBrainNum, floBrainNum);
        
        % registration of loggOdds
        [registeredLogOddsSubFolder, pathRegisteredFloatingLabels, pathRegisteredFloatingHippoLabels] = registerLabels(pathFloatingLabels, pathFloatingHippoLabels,...
            pathTransformation, pathRefMaskedImage, labelsList, pathlogOddsSubfolder, registrationSubFolder, recompute, refBrainNum, floBrainNum);
        
        % perform summation of posterior on the fly
        disp('cropping registered floating labels and updating sum of posteriors'); disp(' ');
        [labelMap, labelMapHippo] = updateLabelMap(labelMap, labelMapHippo, croppedRefMaskedImage, pathRegisteredFloatingImage, pathRegisteredFloatingLabels, ...
            pathRegisteredFloatingHippoLabels, registeredLogOddsSubFolder, labelsList, cropping, sigma, labelPriorType);
        
    end
    
    disp('finding most likely segmentation and calculating corresponding accuracy'); disp(' '); disp(' ');
    [labelMap, labelMapHippo] = getSegmentation(labelMap, labelMapHippo, labelsList, resultsFolder, refBrainNum); % argmax operation
    accuracies(i,:) = computeSegmentationAccuracy(labelMap, labelMapHippo, croppedRefLabels); % compute Dice coef for all structures
    
end

% formating and saving result matrix
disp(['%%%% summarising all accuracies in ' pathAccuracies ' %%%%']); disp(' '); disp(' ');
accuracy = saveAccuracy(accuracies, pathAccuracies);

toc