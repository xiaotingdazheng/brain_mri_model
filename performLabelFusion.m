function [accuracy, labelMap, croppedRefSegmentation] = performLabelFusion(cellPathsFloatingImages, cellPathsLabels, cellPathsRefImages, recompute, dataFolder,...
    recomputeLogOdds, logOddsFolder, computeMaskFloatingImages, sigma, margin, labelPriorType, rho, threshold)

% initialisation
now = clock;
resultsFolder = ['~/data/label_fusion_' num2str(now(3)) '_' num2str(now(2)) '_' num2str(now(4)) '_' num2str(now(5))];
if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder), end
pathAccuracies = fullfile(resultsFolder, 'LabelFusionAccuracy.mat');
if ~recompute, resultsFolder = dataFolder; end

if ~exist(logOddsFolder, 'dir'), mkdir(logOddsFolder), end

n_training_data = length(cellPathsLabels);
leaveOneOutIndices = nchoosek(1:n_training_data,n_training_data-1);
refIndex = n_training_data:-1:1;
namesList = {'background';'left cerebral WM';'left cerebral cortex';'left lateral ventricule';'left inf lat vent';...
    'left cerebellum WM';'left cerebellum cortex';'left thalamus proper';'left caudate';'left putamen';...
    'left pallidum';'3rd ventricule';'4th ventricule';'brain stem';'left amygdala';...
    'CSF';'left accubens area';'left ventralDC';'left vessel';'left-choroid plexus';'right cerebral WM';...
    'right cerebral cortex';'right lateral ventricule';'right inf lat vent';'right cerebellum WM';...
    'right cerebellum cortex';'right thalamus proper';'right caudate';'right putamen';'right pallidum';...
    'right amygdala';'right accumbens area';'right ventral DC';'right vessel';'right choroid plexus';...
    'optic chiasm';'CC posterior';'CC mid posterior';'CC central';'CC Mid anterior';'CC anterior';'R CA1';...
    'R  subiculum';'R CA4DG';'R CA3';'R molecular layer';'L CA1';'L subiculum';'L CA4DG';'L CA3';...
    'L molecular layer';'all hippocampus'};
labelsList = [0,2,3,4,5,7,8,10,11,12,13,14,15,16,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106,NaN];

accuracies = NaN(n_training_data, length(labelsList));

% test label fusion on each real image
for i=1:size(leaveOneOutIndices,1)
    
    disp(['%%%%% testing label fusion on ',cellPathsRefImages{refIndex(i)} ' %%%%%']); disp(' ');
    
    % define paths of real image and corresponding labels
    pathRefImage = cellPathsRefImages{refIndex(i)}; %path of real image
    pathRefLabels = cellPathsLabels{refIndex(i)};
    
    % mask real image
    refBrainNum = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'brain')+5);
    temp_ref = strrep(pathRefImage,'.nii.gz','.mgz');
    [~,name,~] = fileparts(temp_ref);
    pathRefMaskedImage = fullfile(resultsFolder, [refBrainNum '_' name '.masked.nii.gz']); %path of binary mask
    if ~exist(pathRefMaskedImage, 'file') || recompute == 1
        setFreeSurfer();
        disp(['masking reference image ' pathRefImage])
        cmd = ['mri_mask ' pathRefImage ' ' pathRefLabels ' ' pathRefMaskedImage];
        system(cmd); %mask real ref image
    end
    
    % open reference labels
    refSegmentation = MRIread(pathRefLabels);
    refMaskedImage = MRIread(pathRefMaskedImage);
    
    % open corresponding segmentation and crop ref image/labels around hippocampus
    refSegmentation = refSegmentation.vol;
    [croppedRefSegmentation, cropping] = cropHippo(refSegmentation, margin);
    croppedRefMaskedImage = refMaskedImage.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
    
    %initialise matrix on which label fusion will be performed
    labelMap = zeros([size(croppedRefSegmentation), length(labelsList)]);
    
    % registration and similarity between ref image and each synthetic image in turn
    for j=1:size(leaveOneOutIndices,2)
        
        disp(['%% processing floating image ',cellPathsFloatingImages{leaveOneOutIndices(i,j)} ' %%'])
        
        % paths of synthetic image and labels
        pathFloatingImage = cellPathsFloatingImages{leaveOneOutIndices(i,j)};
        pathFloatingLabels = cellPathsLabels{leaveOneOutIndices(i,j)};
        
        % extracting name of Floating image's brain number from label path
        [~,name,~] = fileparts(strrep(pathFloatingLabels,'.nii.gz','.mgz'));
        floBrainNum = name(regexp(name,'brain'):regexp(name,'brain')+5);
        
        % compute logOdds
        temp_lab = strrep(pathFloatingLabels,'.nii.gz','');
        [~,name,~] = fileparts(temp_lab);
        pathLogOddsSubfolder = fullfile(logOddsFolder, name);
        if (~exist(pathLogOddsSubfolder, 'dir') || recomputeLogOdds) && isequal(labelPriorType,'logOdds')
            disp(['computing logOdds of ' pathFloatingLabels])
            labels2prob(pathFloatingLabels, pathLogOddsSubfolder, rho, threshold, labelsList);
        end
        
        %mask image if specified
        if computeMaskFloatingImages
            pathFloatingImage = maskFloatingImage(pathFloatingImage, pathFloatingLabels, resultsFolder, floBrainNum);
        end
        
        % registration of synthetic image and labels to real image
        [pathRegisteredFloatingImage, pathRegisteredFloatingLabels, pathTransformation] = register(pathRefMaskedImage, pathFloatingImage,...
            pathFloatingLabels, labelPriorType, resultsFolder, refIndex(i), recompute, floBrainNum);
        
        % registration of loggOdds
        pathRegisteredLogOddsSubfolder = '';
        if isequal(labelPriorType, 'logOdds')
            disp('applying registration warping to logOdds')
            pathRegisteredLogOddsSubfolder = registerLogOdds(pathTransformation, pathRefMaskedImage, labelsList, pathLogOddsSubfolder, logOddsFolder,...
                resultsFolder, recompute, refBrainNum, floBrainNum);
        end
        
        % perform summation of posterior on the fly
        disp('cropping registered floating labels and updating sum of posteriors'); disp(' ');
        if isequal(labelPriorType, 'delat function'), pathRegisteredLogOddsSubfolder = ''; end
        labelMap = updateLabelMap(labelMap, croppedRefMaskedImage, pathRegisteredFloatingImage, pathRegisteredFloatingLabels, pathRegisteredLogOddsSubfolder, ...
            labelsList, cropping, sigma, labelPriorType, refBrainNum, floBrainNum, croppedRefSegmentation);
        
    end
    
    disp('finding most likely segmentation and calculating corresponding accuracy'); disp(' '); disp(' ');
    [~,index] = max(labelMap, [], 4);
    labelMap = arrayfun(@(x) labelsList(x), index);
    accuracies(i,:) = computeSegmentationAccuracy(labelMap, croppedRefSegmentation, labelsList);
    
end

% formating and saving result matrix
accuracy = saveAccuracy(accuracies, namesList, labelsList, pathAccuracies);

end