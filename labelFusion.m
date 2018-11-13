clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

% we assume here labels and synthetic are aligned.
% labels, synthetic and real images must all have the same resolution

cellPathsLabels = {'/home/benjamin/data/synthetic_brains_t1/brain1.synthetic.t1.0.6.labels.mgz'; 
    '/home/benjamin/data/synthetic_brains_t1/brain2.synthetic.t1.0.6.labels.mgz';
    '/home/benjamin/data/synthetic_brains_t1/brain3.synthetic.t1.0.6.labels.mgz';
    '/home/benjamin/data/synthetic_brains_t1/brain4.synthetic.t1.0.6.labels.mgz';
    '/home/benjamin/data/synthetic_brains_t1/brain5.synthetic.t1.0.6.labels.mgz'};
 
cellPathsSyntheticImages = {'/home/benjamin/data/synthetic_brains_t1/brain1.synthetic.t1.0.6.mgz'; 
    '/home/benjamin/data/synthetic_brains_t1/brain2.synthetic.t1.0.6.mgz';
    '/home/benjamin/data/synthetic_brains_t1/brain3.synthetic.t1.0.6.mgz';
    '/home/benjamin/data/synthetic_brains_t1/brain4.synthetic.t1.0.6.mgz';
    '/home/benjamin/data/synthetic_brains_t1/brain5.synthetic.t1.0.6.mgz'};

cellPathsRealImages = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/nu.mgz'; 
    '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/nu.mgz';
    '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/nu.mgz';
    '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/nu.mgz';
    '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/nu.mgz'};

n_training_data = length(cellPathsLabels);
leaveOneOutIndices = nchoosek(1:n_training_data,n_training_data-1);
leftOutIndex = n_training_data:-1:1;

labelsList = [2,3,4,5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,...
    52,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];

sigma = 1;

accuracy = NaN(n_training_data, length(labelsList));

for i=1:size(leaveOneOutIndices,1)
    
    realImage = MRIread(cellPathsRealImages{i}); %read real image
    labelMap = zeros([size(realImage.vol), length(labelsList)]); %initialise matrix
    
    %compute binary mask of ROI within real image
    flo = cellPathsRealImages{leftOutIndex(j)}; %path of real image
    [dir,name,ext] = fileparts(flo);
    stripped = fullfile(dir,[name,'.stripped',ext]); %path of stripped real image
    fmask = fullfile(dir,[name,'.mask',ext]); %path of binary mask
    cmd = ['~/Software/ROBEX/runROBEX.sh ' flo ' ' stripped ' ' fmask]; 
    [~,~] = system(cmd); %compute fmask
    
    for j=1:size(leaveOneOutIndices,2)
        
        ref = cellPathsSyntheticImages{leaveOneOutIndices(i,j)}; %path of synthetic image
        [dir,name,ext] = fileparts(ref);
        stripped = fullfile(dir,[name,'.stripped',ext]); %path of stripped synthetic image
        rmask = fullfile(dir,[name,'.mask',ext]); %path of binary mask
        res = fullfile(dir,[name,'.registered_to_image',num2str(i),ext]); %path of registered real image
        aff = ''; %modify name of the saved aff file
        
        if ~exist(res, 'file')
            %compute binary mask of ROI synthetic image
            cmd = ['~/Software/ROBEX/runROBEX.sh ' ref ' ' stripped ' ' rmask];
            [~,~] = system(cmd);
        end
        
        %compute registration
        cmd = ['reg_aladin -ref ',ref,' -flo ',flo',' -res ',res,' -rmask ',rmask,' -fmask ',fmask,' -aff ',aff,'-rigOnly -nac -pad 0 -voff'];
        system(cmd)
       
        registeredRealImage = MRIread(res);
        syntheticImage = MRIread(ref);
        segmentationMap = MRIread(cellPathsLabels{leaveOneOutIndices(i,j)});
       
        if registeredRealImage.volsize ~= syntheticImage.volsize || registeredRealImage.volsize ~= segmentationMap.volsize
            error('registered image doesn t have the same size as synthetic image')
        end
       
        % calculate similarity between test (real) image and training (synthetic) image
        likelihood = 1/sqrt(2*pi*sigma)*exp(-(registeredRealImage.vol-syntheticImage.vol)^2/(2*sigma^2));
        
        for k=1:length(labelsList)
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + (segmentationMap.vol == labelsList(k)).*likelihood;
        end
       
    end
    
    [~,index] = max(labelMap,4);
    labelMap = arrayfun(@(x) labelsList(x), index);

    % need to registrate real segmentation
    GTSegmentation = MRIread(cellPathsLabels{leftOutIndex(i)});
    registeredGTSegmentation = GTSegmentation.vol;

    accuracy(i,:) = computeSegmentationAccuracy(labelMap, registeredGTSegmentation, listLabels);
   
end

accuracy = mean(accuracy, 'omitnan');