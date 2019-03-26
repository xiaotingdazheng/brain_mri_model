clear
close all;

% paths
pathHippoProbAtlas = '~/data/hippo_prob_atlas.nii.gz';
pathLabels = '~/data/CobraLab/labels/smoothed_trans';
pathResultFolder = '~/data/CobraLab/labels/nellie_labels_reg_to_prob_atlas';
% path freesurfer and niftyreg
freeSurferHome = '/usr/local/freesurfer/';
niftyRegHome = '/home/benjamin/Software/nifty-reg-mod/niftyreg/build/reg-apps/';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialisation
addpath(fullfile(freeSurferHome, 'matlab/'));
if ~exist(pathResultFolder, 'dir'), mkdir(pathResultFolder); end
if ~contains(pathLabels,'*nii.gz')
    pathLabels = fullfile(pathLabels, '*nii.gz');
end
structLabels = dir(pathLabels);
rightLabels = [41,42,43,44,46,47,49,50,51,52,54,58,60,62,63];
leftLabels =  [2 ,3 ,4 ,5 ,7 ,8 ,10,11,12,13,18,26,28,30,31];

for brain=1:length(structLabels)
    
    disp(' '); disp(['%% Processing image ' num2str(brain) '/' num2str(length(structLabels))])
    
    % read labels and write masked hippocampus
    disp('reading labels');
    pathCurrentLabels = fullfile(structLabels(brain).folder, structLabels(brain).name);
    [~,name,ext] = fileparts(pathCurrentLabels);
    labelsMRI = MRIread(pathCurrentLabels);
    labels = labelsMRI.vol;
    hippoMask = zeros(size(labels),'single');
    
    if contains(pathCurrentLabels, 'left')
        side = 'left';
        hippoMask = (labels>20100)*255;
        pathRegLabels = fullfile(pathResultFolder, [name ext]);
    else
        side = 'right';
        idx = find(labels>20000 & labels<20100);
        hippoMask(idx) = 255;
        pathRegLabels = fullfile(pathResultFolder, [name ext]);
    end
    
    % write mask
    disp('writting mask');
    labelsMRI.vol = hippoMask;
    pathHippoMask = '/tmp/hippo_mask.nii.gz';
    MRIwrite(labelsMRI,pathHippoMask);
    clear labelsMRI hippoMask
    
    % register mask onto prob atlas
    disp('registering mask to probability atlas')
    aff = '/tmp/aff.aff';
    res = '/tmp/reg_hippo_mask.nii.gz';
    pathRegAladin = fullfile(niftyRegHome, 'reg_aladin');
    cmd = [pathRegAladin ' -ref ' pathHippoProbAtlas ' -flo ' pathHippoMask ' -aff ' aff ' -res ' res ' -comi -ln 4 -pad 0'];
    [~,~]=system(cmd);
    
    % apply transformation to labels
    disp('applying transformation to labels')
    pathRegResample = fullfile(niftyRegHome, 'reg_resample');
    cmd = [pathRegResample ' -ref ' pathHippoProbAtlas ' -flo ' pathCurrentLabels ' -trans ' aff ' -res ' pathRegLabels ' -pad 0 -inter 0'];
    [~,~]=system(cmd);
    
    % read register labels
    disp('reading registered labels');
    regLabelsMRI = MRIread(pathRegLabels);
    regLabels = regLabelsMRI.vol;
    
    % change labels from left to right
    if strcmp(side, 'right')
        disp('turning right labels to left ones')
        for l=1:length(rightLabels)
           regLabels(regLabels == rightLabels(l)) = leftLabels(l);
        end
        idx = find(regLabels>20000 & regLabels<20100); regLabels(idx) = regLabels(idx)+100;
    end
    
    % smoothing labels
    disp('smoothing and writing final image')
    regLabels = smoothLabels(regLabels, 1);
    regLabelsMRI.vol = regLabels;
    MRIwrite(regLabelsMRI, pathRegLabels);
    
end
