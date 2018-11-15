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

% cellPathsSyntheticImages = {'/home/benjamin/data/synthetic_brains_t1/brain1.synthetic.t1.0.6.hippo.cropped.nii.gz'; 
%     '/home/benjamin/data/synthetic_brains_t1/brain2.synthetic.t1.0.6.hippo.cropped.nii.gz';
%     '/home/benjamin/data/synthetic_brains_t1/brain3.synthetic.t1.0.6.hippo.cropped.nii.gz';
%     '/home/benjamin/data/synthetic_brains_t1/brain4.synthetic.t1.0.6.hippo.cropped.nii.gz';
%     '/home/benjamin/data/synthetic_brains_t1/brain5.synthetic.t1.0.6.hippo.cropped.nii.gz'};
% cellPathsLabels = {'/home/benjamin/data/synthetic_brains_t1/brain1.synthetic.t1.0.6.labels.hippo.cropped.nii.gz'; 
%     '/home/benjamin/data/synthetic_brains_t1/brain2.synthetic.t1.0.6.labels.hippo.cropped.nii.gz';
%     '/home/benjamin/data/synthetic_brains_t1/brain3.synthetic.t1.0.6.labels.hippo.cropped.nii.gz';
%     '/home/benjamin/data/synthetic_brains_t1/brain4.synthetic.t1.0.6.labels.hippo.cropped.nii.gz';
%     '/home/benjamin/data/synthetic_brains_t1/brain5.synthetic.t1.0.6.labels.hippo.cropped.nii.gz'};
% cellPathsRealImages = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/nu.hippo.cropped.nii.gz'; 
%     '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/norm.hippo.cropped.nii.gz';
%     '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/norm.hippo.cropped.nii.gz';
%     '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/norm.hippo.cropped.nii.gz';
%     '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/norm.hippo.cropped.nii.gz'};

% crop Hippocampus if set to 1. Set to 0 if you don't wish to crop images
% or if you've already entered cropped images
cropHippo = 1;
% path of max hippocampus bounding box (only used if cropHippo=1)
pathMaxCropping = '/home/benjamin/matlab/brain_mri_model/maxHippoCropping.mat';
cropBeforeRegister = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% procedure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if cropHippo == 1
    load(pathMaxCropping,'maxCropping');
    [cellPathsSyntheticImages, cellPathsLabels, cellPathsRealImages] = cropHippocampus(cellPathsSyntheticImages, cellPathsLabels, cellPathsRealImages, maxCropping);
end

n_training_data = length(cellPathsLabels);
leaveOneOutIndices = nchoosek(1:n_training_data,n_training_data-1);
leftOutIndex = n_training_data:-1:1;

labelsList = [2,3,4,5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,...
    52,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];

sigma = 1;

accuracies = NaN(n_training_data, length(labelsList));

for i=1:size(leaveOneOutIndices,1)
    
    realImage = MRIread(cellPathsRealImages{i}); %read real image
    labelMap = zeros([size(realImage.vol), length(labelsList)]); %initialise matrix
    
    pathRealImage = cellPathsRealImages{leftOutIndex(i)}; %path of real image
    
    %compute binary mask of ROI within real image
    if cropBeforeRegister == 0
        temp_ref = strrep(pathRealImage,'.nii.gz','.mgz');
        [dir,name,~] = fileparts(temp_ref);
        stripped = fullfile(dir,[name,'.stripped','.nii.mgz']); %path of stripped real image
        fmask = fullfile(dir,[name,'.mask','.nii.gz']); %path of binary mask
        cmd = ['~/Software/ROBEX/runROBEX.sh ' pathRealImage ' ' stripped ' ' fmask]; 
        system(cmd); %compute fmask
    end
    
    for j=1:size(leaveOneOutIndices,2)

        % registration of synthetic image and labels to real image
        pathSyntheticImage = cellPathsSyntheticImages{leaveOneOutIndices(i,j)};
        pathLabels = cellPathsLabels{leaveOneOutIndices(i,j)};
        [pathResultSynthetic, pathResultLabels] = register(pathRealImage, pathSyntheticImage, pathLabels, leftOutIndex(i), cropBeforeRegister);
        
        % read registered real,synthetic and segmentation images
        realImage = MRIread(pathRealImage);
        registeredSyntheticImage = MRIread(pathResultSynthetic);
        registeredLabels = MRIread(pathResultLabels);
        
        if ~isequal(realImage.volsize, registeredSyntheticImage.volsize) || ~isequal(realImage.volsize, registeredLabels.volsize)
            error('registered image doesn t have the same size as synthetic image')
        end
        
        % calculate similarity between test (real) image and training (synthetic) image
        likelihood = 1/sqrt(2*pi*sigma)*exp(-(realImage.vol-registeredSyntheticImage.vol).^2/(2*sigma^2));
        
        for k=1:length(labelsList)
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + (registeredLabels.vol == labelsList(k)).*likelihood;
        end
       
    end
    
    [~,index] = max(labelMap,4);
    labelMap = arrayfun(@(x) labelsList(x), index);

    % need to registrate real segmentation
    GTSegmentation = MRIread(cellPathsLabels{leftOutIndex(i)});
    registeredGTSegmentation = GTSegmentation.vol;

    accuracies(i,:) = computeSegmentationAccuracy(labelMap, registeredGTSegmentation, listLabels);
   
end

accuracy = mean(accuracies, 'omitnan');