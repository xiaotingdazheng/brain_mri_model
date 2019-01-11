function labels2prob(pathFloatingLabels, LogOddsSubfolder, rho, threshold, labelsList, recomputeLogOdds)

if (~exist(LogOddsSubfolder, 'dir') || recomputeLogOdds)
    
    disp(['computing logOdds of ' pathFloatingLabels])
    
    % create sufolder if it doesn't exist
    if ~exist(LogOddsSubfolder, 'dir'), mkdir(LogOddsSubfolder), end
    
    LabelsMRI = MRIread(pathFloatingLabels);
    Labels = LabelsMRI.vol;
    brainMask = Labels > 1;
    brainMask = imfill(bwdist(brainMask)< 5, 'holes'); % produce a mask of the brain with margin of 5 voxels
    
    % loop over all the labels
    for l=1:length(labelsList)
        temp_path = fullfile(LogOddsSubfolder, ['logOdds_' num2str(labelsList(l)) '.nii.gz']);
        mask = (Labels == labelsList(l)); % find mask of current label
        computeLogOdds(mask, brainMask, temp_path, LabelsMRI, rho, threshold)
    end
    
    % calculate logOdds for whole hippocampus
    temp_path = fullfile(LogOddsSubfolder, 'logOdds_hippo.nii.gz');
    maskHippo = Labels > 20000;
    computeLogOdds(maskHippo, brainMask, temp_path, LabelsMRI, rho, threshold)
    
    % calculate logOdds for non-hippocampus structures
    temp_path = fullfile(LogOddsSubfolder, 'logOdds_non_hippo.nii.gz');
    maskNonHippo = ~maskHippo;
    computeLogOdds(maskNonHippo, brainMask, temp_path, LabelsMRI, rho, threshold)
    
end

end

function computeLogOdds(mask, brainMask, path, LabelsMRI, rho, threshold)

distInt = bwdist(~mask);
distOut = -bwdist(mask);

distInt(mask) = distInt(mask) - 0.5;
distOut(~mask) = distOut(~mask) + 0.5;

distMap = distInt + distOut;
probMap = exp(rho*distMap); % calculate prob of voxel belonging to label l

probMap = probMap.*brainMask;

thresholdMap = probMap > threshold;
probMap = probMap.*thresholdMap; % threshold prob map


% write new prob map in mgz file
LabelsMRI.vol = probMap;

% save label probability in separate file
MRIwrite(LabelsMRI, path);

end