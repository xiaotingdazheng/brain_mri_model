function calculatePrior(pathFloLabels, labelPriorType, priorSubfolder, labelsList, rho, threshold, recompute, freeSurferHome)

floBrainNum = findBrainNum(pathFloLabels);
% create sufolder if it doesn't exist
if ~exist(priorSubfolder, 'dir'), mkdir(priorSubfolder), end

switch labelPriorType
    
    case 'logOdds'
        
        if (~exist(priorSubfolder, 'dir') || recompute)
            
            disp(['computing logOdds of training' floBrainNum])
            
            % produce a mask of the brain with margin of 5 voxels
            LabelsMRI = MRIread(pathFloLabels);
            Labels = LabelsMRI.vol;
            brainMask = Labels > 1;
            brainMask = imfill(bwdist(brainMask)< 5, 'holes');
            
            % loop over all the labels
            for l=1:length(labelsList)
                temp_path = fullfile(priorSubfolder, ['logOdds_' num2str(labelsList(l)) '.nii.gz']);
                mask = (Labels == labelsList(l)); % find mask of current label
                computeLogOdds(mask, brainMask, temp_path, LabelsMRI, rho, threshold)
            end
            % calculate logOdds for whole hippocampus
            temp_path = fullfile(priorSubfolder, 'logOdds_hippo.nii.gz');
            maskHippo = Labels > 20000;
            computeLogOdds(maskHippo, brainMask, temp_path, LabelsMRI, rho, threshold)
            % calculate logOdds for non-hippocampus structures
            temp_path = fullfile(priorSubfolder, 'logOdds_non_hippo.nii.gz');
            maskNonHippo = ~maskHippo;
            computeLogOdds(maskNonHippo, brainMask, temp_path, LabelsMRI, rho, threshold)
            
        end
        
        
    case 'delta function'
        
        disp(['computing delta function of training ' floBrainNum])
        
        % builds name of hippo label file that will be saved
        pathFloHippoLabels = fullfile(priorSubfolder, 'hippo_labels.nii.gz');
        % compute whole hippo mask and save it
        if ~exist(pathFloHippoLabels, 'file') || recompute
            setFreeSurfer(freeSurferHome);
            floLabels = MRIread(pathFloLabels); % read labels
            hippoMap = floLabels.vol > 20000 | floLabels.vol == 17 | floLabels.vol == 53; % hippo mask
            floLabels.vol = hippoMap;
            MRIwrite(floLabels, pathFloHippoLabels); % write new file
        end
        
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
probMap(probMap > 200) = 200; % set upper value to 200

% write new prob map in mgz file
LabelsMRI.vol = probMap;

% save label probability in separate file
MRIwrite(LabelsMRI, path);

end