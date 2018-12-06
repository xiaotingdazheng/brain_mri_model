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
% folder '~/data/label_fusion_date_time'. If recompute = 0, specify where
% is the data to be used.
recompute = 0;
dataFolder = '~/data/label_fusion_5_12_17_51';

% set recomputeLogOdds to 1 if you wish to recompute the logOdds
% probability maps. The new ones will be stored to cellLogOddsFolder. If
% recomputeLogOdds is set to 0, data stored in the specified folder will be
% reused directly.
recomputeLogOdds = 0;
logOddsFolder = '~/data/logOdds_without_erosion';

% set to 1 if you wish to apply masking to floating images. Resulting mask
% image will be saved in resultsFolder.
computeMaskFloatingImages = 1;

% label fusion parameter
sigmaList = [10, 15, 20];
margin = 30;                  % margin introduced when hippocampus are cropped
labelPriorType = 'delta function';   %'delta function' or 'logOdds'
rho = 0.4;                    % exponential decay for prob logOdds
threshold = 0.5;              % threshold for prob logOdds

means = zeros(length(sigmaList),1);
for i=1:length(sigmaList)
    [accuracy, labelMap, croppedRefSegmentation] = performLabelFusion(cellPathsFloatingImages, cellPathsLabels, cellPathsRefImages, recompute, dataFolder,...
        recomputeLogOdds, logOddsFolder, computeMaskFloatingImages, sigmaList(i), margin, labelPriorType, rho, threshold);
    means(i) = mean(cell2mat(accuracy(end,2:end)),'omitnan');
end

figure;
bar(sigmaList,means);

toc