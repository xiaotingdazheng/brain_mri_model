clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic

% cellPathsSyntheticImages = {'~/data/synthetic_brains_t1/brain1.synthetic.t1.0.6.nii.gz';
%     '~/data/synthetic_brains_t1/brain2.synthetic.t1.0.6.nii.gz';
%     '~/data/synthetic_brains_t1/brain3.synthetic.t1.0.6.nii.gz';
%     '~/data/synthetic_brains_t1/brain4.synthetic.t1.0.6.nii.gz';
%     '~/data/synthetic_brains_t1/brain5.synthetic.t1.0.6.nii.gz'};
cellPathsFloatingImages = {'~/subjects/brain1_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '~/subjects/brain2_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '~/subjects/brain3_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '~/subjects/brain4_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '~/subjects/brain5_t1_to_t2.0.6/mri/norm.384.nii.gz'};
cellPathsLabels = {'~/data/synthetic_brains_t1/brain1.synthetic.t1.0.6.labels.nii.gz';
    '~/data/synthetic_brains_t1/brain2.synthetic.t1.0.6.labels.nii.gz';
    '~/data/synthetic_brains_t1/brain3.synthetic.t1.0.6.labels.nii.gz';
    '~/data/synthetic_brains_t1/brain4.synthetic.t1.0.6.labels.nii.gz';
    '~/data/synthetic_brains_t1/brain5.synthetic.t1.0.6.labels.nii.gz'};
cellPathsRefImages = {'~/subjects/brain1_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '~/subjects/brain2_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '~/subjects/brain3_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '~/subjects/brain4_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '~/subjects/brain5_t1_to_t2.0.6/mri/norm.384.nii.gz'};

% set recompute to 1 if you wish to recompute all the masks and
% registrations. The results will be saved in an automatically generated
% folder '~/data/registrations_date_time'. If recompute = 0, specify where
% is the data to be used.
recompute = 0;
dataFolder = '~/data/label_fusion_29_11_12_52';

% set recomputeLogOdds to 1 if you wish to recompute the logOdds
% probability maps. The new ones will be stored to cellLogOddsFolder. If
% recomputeLogOdds is set to 0, data stored in the specified folder will be
% reused directly.
recomputeLogOdds = 1;
logOddsFolder = '~/data/logOdds';

% set to 1 if you wish to apply masking to floating images. Resulting mask
% image will be saved in resultsFolder.
maskFloatingImages = 1;

% label fusion parameter
sigma = 1;                         % std dev of gaussian similarity meaure
margin = 30;                       % margin introduced when hippocampus are cropped
labelPriorType = 'delta function'; %'delta function' or 'loggOdds'
rho = 0.2;                        % exponential decay for prob logOdds
threshold = 0.5;                   % threshold for prob logOdds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% procedure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
namesList = {'left cerebral WM';'left cerebral cortex';'left lateral ventricule';'left inf lat vent';...
    'left cerebellum WM';'left cerebellum cortex';'left thalamus proper';'left caudate';'left putamen';...
    'left pallidum';'3rd ventricule';'4th ventricule';'brain stem';'left hippocampus';'left amygdala';...
    'CSF';'left accubens area';'left ventralDC';'left vessel';'left-choroid plexus';'right cerebral WM';...
    'right cerebral cortex';'right lateral ventricule';'right inf lat vent';'right cerebellum WM';...
    'right cerebellum cortex';'right thalamus proper';'right caudate';'right putamen';'right pallidum';...
    'right amygdala';'right accumbens area';'right ventral DC';'right vessel';'right choroid plexus';...
    'optic chiasm';'CC posterior';'CC mid posterior';'CC central';'CC Mid anterior';'CC anterior';'R_CA1';...
    'R _subiculum';'R_CA4DG';'R_CA3';'R_molecular layer';'L_CA1';'L_subiculum';'L_CA4DG';'L_CA3';...
    'L_molecular_layer';'all hippocampus'};
labelsList = [2,3,4,5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106,NaN];

accuracies = NaN(n_training_data, length(labelsList));

% test label fusion on each real image
for i=1:size(leaveOneOutIndices,1)
    
    disp(['%%% testing label fusion on ',cellPathsRefImages{refIndex(i)}])
    
    % define paths of real image and corresponding labels
    pathRefImage = cellPathsRefImages{refIndex(i)}; %path of real image
    pathRefLabels = cellPathsLabels{refIndex(i)};
    
    % mask real image
    brain_num = pathRefImage(regexp(pathRefImage,'brain'):regexp(pathRefImage,'brain')+5);
    temp_ref = strrep(pathRefImage,'.nii.gz','.mgz');
    [~,name,~] = fileparts(temp_ref);
    pathRefMaskedImage = fullfile(resultsFolder, [brain_num '_' name '.masked.nii.gz']); %path of binary mask
    if ~exist(pathRefMaskedImage, 'file') || recompute == 1
        setFreeSurfer();
        disp(['masking real image ' pathRefImage])
        cmd = ['mri_mask ' pathRefImage ' ' pathRefLabels ' ' pathRefMaskedImage];
        system(cmd); %mask real ref image
    end
    
    % open real masked image and corresponding labels
    realRefMaskedImage = MRIread(pathRefMaskedImage);
    GTSegmentation = MRIread(pathRefLabels);
    
    % open corresponding segmentation and find cropping of hippocampus
    GTSegmentation = GTSegmentation.vol;
    [croppedGTSegmentation, cropping] = cropHippo(GTSegmentation, margin);
    labelMap = zeros([size(croppedGTSegmentation), length(labelsList)]); %initialise matrix
    
    % registration and similarity between ref image and each synthetic image in turn
    for j=1:size(leaveOneOutIndices,2)
        
        disp(['processing synthtetic data ',cellPathsFloatingImages{leaveOneOutIndices(i,j)}])
        
        % paths of synthetic image and labels
        pathFloatingImage = cellPathsFloatingImages{leaveOneOutIndices(i,j)};
        pathFloatingLabels = cellPathsLabels{leaveOneOutIndices(i,j)};
        
        % compute logOdds
        temp_lab = strrep(pathFloatingLabels,'.nii.gz','');
        [~,name,~] = fileparts(temp_lab);
        pathlogOddsSubfolder = fullfile(logOddsFolder, name);
        if ~exist(pathlogOddsSubfolder, 'dir') || recomputeLogOdds
            labels2prob(pathFloatingLabels, pathlogOddsSubfolder, rho, threshold, labelsList);
        end
        
        %mask image if needed
        if maskFloatingImages
            temp_flo = strrep(pathFloatingImage,'.nii.gz','.mgz');
            [~,name,~] = fileparts(temp_flo);
            if contains(pathFloatingImage, 'brain') && ~contains(name, 'brain')
                brain_num = [pathFloatingImage(regexp(pathFloatingImage,'brain'):regexp(pathFloatingImage,'brain')+5) '_'];
            else
                brain_num = '';
            end
            pathMaskedFloatingImage = fullfile(resultsFolder, [brain_num  name '.masked.nii.gz']); %path of mask
            if ~exist(pathMaskedFloatingImage, 'file')
                setFreeSurfer();
                disp(['masking real image ' pathRefImage])
                cmd = ['mri_mask ' pathFloatingImage ' ' pathFloatingLabels ' ' pathMaskedFloatingImage];
                system(cmd);
            end
            pathFloatingImage = pathMaskedFloatingImage;
        end
        
        % registration of synthetic image and labels to real image
        [pathRegisteredFloatingImage, pathRegisteredFloatingLabels] = register(pathRefMaskedImage, pathFloatingImage, pathFloatingLabels, resultsFolder, refIndex(i), recompute);
        
        % read registered real,synthetic and segmentation images
        %to change !!! realRefImage = MRIread(pathRealRefImage); %read real image
        registeredFloatingImage = MRIread(pathRegisteredFloatingImage);
        registeredFloatingLabels = MRIread(pathRegisteredFloatingLabels);
        
        % cropp registered synthetic images and corresponding segmentation
        croppedRealRefMaskedImage = realRefMaskedImage.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        croppedRegisteredFloatingImage = registeredFloatingImage.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        croppedRegisteredFloatingLabels = registeredFloatingLabels.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        
        if ~isequal(size(croppedRealRefMaskedImage), size(croppedRegisteredFloatingImage)) || ~isequal(size(croppedRealRefMaskedImage), size(croppedRegisteredFloatingLabels))
            error('registered image doesn t have the same size as synthetic image')
        end
        
        % calculate similarity between test (real) image and training (synthetic) image
        likelihood = 1/sqrt(2*pi*sigma)*exp(-(croppedRealRefMaskedImage-croppedRegisteredFloatingImage).^2/(2*sigma^2));
        
        disp('updating segmentation likelihood')
        for k=1:length(labelsList)
            if isequal(labelPriorType, 'delta function')
                labelPrior = (croppedRegisteredFloatingLabels == labelsList(k));
            elseif  isequal(labelPriorType, 'logOdds')
                labelPrior = (croppedRegisteredFloatingLabels == labelsList(k));
            else
                error('wrong type of label Prior, must be delta function or logOdds')
            end
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + labelPrior.*likelihood;
        end
        
    end
    
    disp('finding most likely segmentation and calculating corresponding accuracy')
    [~,index] = max(labelMap, [], 4);
    labelMap = arrayfun(@(x) labelsList(x), index);
    accuracies(i,:) = computeSegmentationAccuracy(labelMap, croppedGTSegmentation, labelsList);
    
end

% formating and saving result matrix
accuracy = cell(size(accuracies,1)+3,size(accuracies,2)+1);
accuracy{1,1} = 'brain regions'; accuracy{2,1} = 'associated label';
accuracy{3,1} = 'leave one out accuracies'; accuracy{end,1} = 'mean accuracy';
accuracy(1,2:end) = namesList';
accuracy(2,2:end) = num2cell(labelsList);
accuracy(3:end-1,2:end) = num2cell(accuracies);
accuracy(end,2:end) = num2cell(mean(accuracies,'omitnan'));
save(pathAccuracies, 'accuracy')

toc