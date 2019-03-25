function calculatePrior(pathFloLabels, labelPriorType, priorSubfolder, labelsList, rho, threshold, pathTempImFolder, recompute, freeSurferHome)

floBrainNum = findBrainNum(pathFloLabels);
nLabels = length(labelsList);

switch labelPriorType
    
    case 'logOdds'
        
        if ~exist(priorSubfolder, 'dir'), mkdir(priorSubfolder); end
        structLogOddsFile = dir(fullfile(priorSubfolder,'*.nii.gz'));
        if length(structLogOddsFile) < nLabels + 3 || recompute
            disp(['computing logOdds of training ' floBrainNum])
        end
        
        % produce a mask of the brain with margin of 5 voxels
        LabelsMRI = myMRIread(pathFloLabels, 0, pathTempImFolder);
        Labels = LabelsMRI.vol;
        brainMask = Labels > 1;
        brainMask = imfill(bwdist(brainMask)< 5, 'holes');
        
        % loop over all the labels
        for l=1:nLabels
            temp_path = fullfile(priorSubfolder, ['logOdds_' num2str(labelsList(l)) '.nii.gz']);
            if ~exist(temp_path, 'file') || recompute
                mask = (Labels == labelsList(l)); % find mask of current label
                computeLogOdds(mask, brainMask, temp_path, LabelsMRI, rho, threshold, pathTempImFolder)
            end
        end
        % calculate logOdds for left hippocampus
        temp_path = fullfile(priorSubfolder, 'logOdds_left_hippo.nii.gz');
        if ~exist(temp_path, 'file') || recompute
            maskHippo = Labels > 20100;
            computeLogOdds(maskHippo, brainMask, temp_path, LabelsMRI, rho, threshold, pathTempImFolder)
        end
        % calculate logOdds for right hippocampus
        temp_path = fullfile(priorSubfolder, 'logOdds_right_hippo.nii.gz');
        if ~exist(temp_path, 'file') || recompute
            maskHippo = Labels > 20000 & Labels < 20100;
            computeLogOdds(maskHippo, brainMask, temp_path, LabelsMRI, rho, threshold, pathTempImFolder)
        end
        % calculate logOdds for non-hippocampus structures
        temp_path = fullfile(priorSubfolder, 'logOdds_non_hippo.nii.gz');
        if ~exist(temp_path, 'file') || recompute
            maskNonHippo = Labels < 20000;
            computeLogOdds(maskNonHippo, brainMask, temp_path, LabelsMRI, rho, threshold, pathTempImFolder)
        end
        
    case 'delta function'
        
        % builds name of hippo label file that will be saved
        pathFloHippoLabels = fullfile(priorSubfolder, 'hippo_labels.nii.gz');
        if ~exist(priorSubfolder, 'dir'), mkdir(priorSubfolder); end
        
        % compute whole hippo mask and save it
        if ~exist(pathFloHippoLabels, 'file') || recompute
            
            disp(['computing delta function of training ' floBrainNum])
            
            setFreeSurfer(freeSurferHome);
            floLabels = myMRIread(pathFloLabels, 0, pathTempImFolder); % read labels
            hippoMap((floLabels.vol > 20000 & floLabels.vol < 20100) | floLabels.vol == 53) = 53; % right hippo
            hippoMap(floLabels.vol > 20100 | floLabels.vol == 17) = 17; % left hippo
            floLabels.vol = hippoMap;
            myMRIwrite(floLabels, pathFloHippoLabels, 'float', pathTempImFolder); % write new file
            
        end
        
end

end

function computeLogOdds(mask, brainMask, path, LabelsMRI, rho, threshold, pathTempImFolder)

distInt = bwdist(~mask);
distOut = -bwdist(mask);

distInt(mask) = distInt(mask) - 0.5;
distOut(~mask) = distOut(~mask) + 0.5;

distMap = distInt + distOut;
probMap = exp(rho*distMap); % calculate prob of voxel belonging to label l

probMap = probMap.*brainMask;

thresholdMap = probMap > threshold;
probMap = probMap.*thresholdMap; % threshold prob map
probMap(probMap > 200) = 200; % set upper value to 200

% write new prob map in mgz file
LabelsMRI.vol = probMap;

% save label probability in separate file
myMRIwrite(LabelsMRI, path, 'float', pathTempImFolder);

end