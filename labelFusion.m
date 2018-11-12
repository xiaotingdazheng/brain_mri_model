clear
addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

% we assume here labels and synthetic are aligned.
% labels, synthetic and real images must all have the same resolution

cellPathsLabels = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/aseg+subfields.mgz'; 
    '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/aseg+subfields.mgz'};
    
cellPathsSyntheticImages = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/aseg+subfields.mgz'; 
    '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/aseg+subfields.mgz'};

cellPathsRealImages = {'/home/benjamin/subjects/brain1_t1_to_t2.0.6/mri/aseg+subfields.mgz'; 
    '/home/benjamin/subjects/brain2_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain3_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain4_t1_to_t2.0.6/mri/aseg+subfields.mgz';
    '/home/benjamin/subjects/brain5_t1_to_t2.0.6/mri/aseg+subfields.mgz'};

n_training_data = length(cellPathsLabels);
leaveOneOutIndices = nchoosek(1:n_training_data,n_training_data-1);
leftOutIndex = n_training_data:-1:1;

labelsList = [  2,3, 4, 5,7,8,10,11,12,13,14,15,16,17,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];
labelHippo = [20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];

sigma = 1;

accuracy = NaN(n_training_data,  length(labelsList));

for i=1:size(leaveOneOutIndices,1)
    
    labelMap = zeros([size(syntheticImage.vol), length(labelsList)]);
    
    for j=1:size(leaveOneOutIndices,2)
      
        ref = cellPathsSyntheticImages{leaveOneOutIndices(j)};
        flo = cellPathsRealImages{leftOutIndex(j)};
        res = ''; %modify name of the registered real image
        rmask = ''; %compute mask of real image or take nu
        fmask = ''; %compute mask of fake image even if its not really necessary
        aff = ''; %modify name of the saved aff file
       
        cmd = ['reg_aladin -ref ',ref,' -flo ',flo',' -res ',res,' -rmask ',rmask,' -fmask ',fmask,' -aff ',aff,'-rigOnly -nac -pad 0 -voff'];
        system(cmd)
       
        registeredRealImage = MRIread(res);
        syntheticImage = MRIread(ref);
        segmentationMap = MRIread(cellPathsLabels{leaveOneOutIndices(j)});
       
        if registeredRealImage.volsize ~= syntheticImage.volsize || registeredRealImage.volsize ~= segmentationMap.volsize
            error('registered image doesn t have the same size as synthetic image')
        end
       
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
    
    accuracy(i,:), presentIndices = computeSegmentationAccuracy(labelMap, registeredGTSegmentation, listLabels);
   
end

accuracy = mean(accuracy, 'omitnan');