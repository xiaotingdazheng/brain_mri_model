function labels2prob(pathLabels, pathLogOddsSubfolder, rho, threshold, labelsList)

addpath /usr/local/freesurfer/matlab
addpath /home/benjamin/matlab/toolbox

% create sufolder if it doesn't exist
if ~exist(pathLogOddsSubfolder, 'dir'), mkdir(pathLogOddsSubfolder), end

LabelsMRI = MRIread(pathLabels);
Labels = LabelsMRI.vol;
LabelsMask = Labels > 1;
LabelsMask = imfill(bwdist(LabelsMask)< 5, 'holes');

% loop over all the labels
for l=1:length(labelsList)
    
    maskHippo = (Labels == labelsList(l)); % find mask of current label
    %mask = imerode(mask,ones(2,2,2)); % erode mask
    prob = exp(-rho*bwdist(maskHippo)); % calculate prob of voxel belonging to label l
    thresholdMap = prob > threshold; 
    prob = prob.*thresholdMap; % threshold prob map
    prob = prob.*LabelsMask;
    LabelsMRI.vol = prob; % write new prob map in mgz file
    
    % save label probability in separate file
    temp_path = fullfile(pathLogOddsSubfolder, ['logOdds_' num2str(labelsList(l)) '.nii.gz']);
    MRIwrite(LabelsMRI, temp_path);
    
end

% calculate logOdds for whole hippocampus
maskHippo = Labels > 20000;
%mask = imerode(mask,ones(2,2,2)); % erode mask
prob = exp(-rho*bwdist(maskHippo)); % calculate prob of voxel belonging to label l
thresholdMap = prob > threshold;
prob = prob.*thresholdMap; % threshold prob map
prob = prob.*LabelsMask;
LabelsMRI.vol = prob;

% save label probability for hippocampus in separate file
temp_path = fullfile(pathLogOddsSubfolder, 'logOdds_hippo.nii.gz');
MRIwrite(LabelsMRI, temp_path);

% calculate logOdds for non-hippocampus structures
maskNonHippo = ~maskHippo;
%mask = imerode(mask,ones(2,2,2)); % erode mask
prob = exp(-rho*bwdist(maskNonHippo)); 
thresholdMap = prob > threshold;
prob = prob.*thresholdMap;
prob = prob.*LabelsMask;
LabelsMRI.vol = prob;

% save label probability for non-hippocampus in separate file
temp_path = fullfile(pathLogOddsSubfolder, 'logOdds_non_hippo.nii.gz');
MRIwrite(LabelsMRI, temp_path);

end