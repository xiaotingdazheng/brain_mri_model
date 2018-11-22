clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% procedure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialisation
n_training_data = length(cellPathsLabels);
leaveOneOutIndices = nchoosek(1:n_training_data,n_training_data-1);
refIndex = n_training_data:-1:1;
labelsList = [2,3,4,5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,...
    52,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
accuracies = NaN(n_training_data, length(labelsList));

% test label fusion on each real image 
for i=1:size(leaveOneOutIndices,1)
    
    % open reference image (real)
    pathRealRefImage = cellPathsRealImages{refIndex(i)}; %path of real image
    realRefImage = MRIread(pathRealRefImage); %read real image
    % open correpsonding segmentation
    GTSegmentation = MRIread(cellPathsLabels{refIndex(i)});
    GTSegmentation = GTSegmentation.vol;
    [croppedGTSegmentation, cropping] = cropHippo(GTSegmentation, margin);
    labelMap = zeros([size(croppedGTSegmentation), length(labelsList)]); %initialise matrix
    
    %compute binary mask of ROI within real image
    temp_ref = strrep(pathRealRefImage,'.nii.gz','.mgz');
    [dir,name,~] = fileparts(temp_ref);
    stripped = fullfile(dir,[name,'.stripped','.nii.gz']); %path of stripped real image
    fmask = fullfile(dir,[name,'.mask','.nii.gz']); %path of binary mask
    cmd = ['~/Software/ROBEX/runROBEX.sh ' pathRealRefImage ' ' stripped ' ' fmask]; 
    system(cmd); %compute fmask
    
    % registration and similarity between ref image and each synthetic image in turn
    for j=1:size(leaveOneOutIndices,2)

        % registration of synthetic image and labels to real image
        pathSyntheticImage = cellPathsSyntheticImages{leaveOneOutIndices(i,j)};
        pathLabels = cellPathsLabels{leaveOneOutIndices(i,j)};
        [pathResultSynthetic, pathResultLabels] = register(pathRealRefImage, fmask, pathSyntheticImage, pathLabels, refIndex(i));
        
        % read registered real,synthetic and segmentation images
        registeredSyntheticImage = MRIread(pathResultSynthetic);
        registeredLabels = MRIread(pathResultLabels);
        
        % cropp registered synthetic images and corresponding segmentation
        croppedRealRefImage = realRefImage.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        croppedRegisteredSyntheticImage = registeredSyntheticImage.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        croppedRegisteredLabels = registeredLabels.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
       
        if ~isequal(croppedRealRefImage, croppedRegisteredSyntheticImage) || ~isequal(croppedRealRefImage, croppedRegisteredLabels)
            error('registered image doesn t have the same size as synthetic image')
        end
        
        % calculate similarity between test (real) image and training (synthetic) image
        likelihood = 1/sqrt(2*pi*sigma)*exp(-(croppedRealRefImage-croppedRegisteredSyntheticImage).^2/(2*sigma^2));
         
        for k=1:length(labelsList)
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + (croppedRegisteredLabels == labelsList(k)).*likelihood;
        end
       
    end
    
    [~,index] = max(labelMap,4);
    labelMap = arrayfun(@(x) labelsList(x), index);

    accuracies(i,:) = computeSegmentationAccuracy(labelMap, croppedGTSegmentation, listLabels);
   
end

accuracy = mean(accuracies, 'omitnan');