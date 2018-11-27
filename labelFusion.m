clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic

cellPathsSyntheticImages = {'/home/benjamin/data/synthetic_brains_t1/brain1.synthetic.t1.0.6.nii.gz';
    '/home/benjamin/data/synthetic_brains_t1/brain2.synthetic.t1.0.6.nii.gz';
    '/home/benjamin/data/synthetic_brains_t1/brain3.synthetic.t1.0.6.nii.gz';
    '/home/benjamin/data/synthetic_brains_t1/brain4.synthetic.t1.0.6.nii.gz';
    '/home/benjamin/data/synthetic_brains_t1/brain5.synthetic.t1.0.6.nii.gz'};
cellPathsLabels = {'/home/benjamin/data/synthetic_brains_t1/brain1.synthetic.t1.0.6.labels.nii.gz';
    '/home/benjamin/data/synthetic_brains_t1/brain2.synthetic.t1.0.6.labels.nii.gz';
    '/home/benjamin/data/synthetic_brains_t1/brain3.synthetic.t1.0.6.labels.nii.gz';
    '/home/benjamin/data/synthetic_brains_t1/brain4.synthetic.t1.0.6.labels.nii.gz';
    '/home/benjamin/data/synthetic_brains_t1/brain5.synthetic.t1.0.6.labels.nii.gz'};
cellPathsRealImages = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/norm.384.nii.gz';
    '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/norm.384.nii.gz'};

sigma = 1;
margin = 30;
recompute = 1;
labelPriorType = 'delta function'; %'delta function' or 'loggOdds'

pathAccuracies = '/home/benjamin/matlab/brain_mri_model/LabelFusionAccuracy.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% procedure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialisation
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
    'R _subiculum';'R_CA4DG';'R_CA3';'R_molecular layer';'L_CA1';'L_subiculum';'L_CA4DG';'L_CA3';'L_molecular_layer'};
labelsList = [2,3,4,5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,...
    52,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];

accuracies = NaN(n_training_data, length(labelsList));

% test label fusion on each real image 
for i=1:size(leaveOneOutIndices,1)
    
    disp(['%%% testing label fusion on ',cellPathsRealImages{refIndex(i)}])
    
    % define paths of real image and corresponding labels
    pathRealRefImage = cellPathsRealImages{refIndex(i)}; %path of real image
    pathRealRefLabels = cellPathsLabels{refIndex(i)};
    
    % mask real image and open it
    temp_ref = strrep(pathRealRefImage,'.nii.gz','.mgz');
    [dir,name,~] = fileparts(temp_ref);
    pathRealRefMaskedImage = fullfile(dir,[name,'.masked','.nii.gz']); %path of binary mask
    if ~exist(pathRealRefMaskedImage, 'file') || recompute == 1
        disp(['masking real image ' pathRealRefImage])
        cmd = ['mask_mri ' pathRealRefImage ' ' pathRealRefLabels ' ' pathRealRefMaskedImage]; 
        system(cmd); %mask real ref image
    end
    
    % open real masked image and corresponding labels
    realRefMaskedImage = MRIread(pathRealRefMaskedImage);
    GTSegmentation = MRIread(pathRealRefLabels);
    
    % open corresponding segmentation and find cropping of hippocampus
    GTSegmentation = GTSegmentation.vol;
    [croppedGTSegmentation, cropping] = cropHippo(GTSegmentation, margin);
    labelMap = zeros([size(croppedGTSegmentation), length(labelsList)]); %initialise matrix
    
    % registration and similarity between ref image and each synthetic image in turn
    for j=1:size(leaveOneOutIndices,2)
        
        disp(['processing synthtetic data ',cellPathsSyntheticImages{leaveOneOutIndices(i,j)}])

        % registration of synthetic image and labels to real image
        pathSyntheticImage = cellPathsSyntheticImages{leaveOneOutIndices(i,j)};
        pathSyntheticLabels = cellPathsLabels{leaveOneOutIndices(i,j)};
        [pathRegisteredSyntheticImage, pathRegisteredSyntheticLabels] = register(realRefMaskedImage, pathSyntheticImage, pathSyntheticLabels, refIndex(i), recompute);
        
        % read registered real,synthetic and segmentation images
        %to change !!! realRefImage = MRIread(pathRealRefImage); %read real image
        registeredSyntheticImage = MRIread(pathRegisteredSyntheticImage);
        registeredSyntheticLabels = MRIread(pathRegisteredSyntheticLabels);
        
        % cropp registered synthetic images and corresponding segmentation
        croppedRealRefMaskedImage = realRefMaskedImage.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        croppedRegisteredSyntheticImage = registeredSyntheticImage.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        croppedRegisteredSyntheticLabels = registeredSyntheticLabels.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
       
        if ~isequal(size(croppedRealRefMaskedImage), size(croppedRegisteredSyntheticImage)) || ~isequal(size(croppedRealRefMaskedImage), size(croppedRegisteredSyntheticLabels))
            error('registered image doesn t have the same size as synthetic image')
        end
        
        % calculate similarity between test (real) image and training (synthetic) image
        likelihood = 1/sqrt(2*pi*sigma)*exp(-(croppedRealRefMaskedImage-croppedRegisteredSyntheticImage).^2/(2*sigma^2));
        
        disp('updating segmentation likelihood')
        for k=1:length(labelsList)
            if isequal(labelPriorType, 'delta function')
                labelPrior = (croppedRegisteredSyntheticLabels == labelsList(k));
            elseif  isequal(labelPriorType, 'logOdds')
                labelPrior = (croppedRegisteredSyntheticLabels == labelsList(k));
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