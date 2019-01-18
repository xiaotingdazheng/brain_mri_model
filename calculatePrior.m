function pathFloatingHippoLabels = calculatePrior(pathFloatingLabels, labelPriorType, hippoLabelsFolder, logOddsSubfolder, labelsList, rho, threshold, recompute)

switch labelPriorType
    
    case 'logOdds'
        
        if (~exist(logOddsSubfolder, 'dir') || recompute)
            
            disp(['computing logOdds of ' pathFloatingLabels])
            
            % create sufolder if it doesn't exist
            if ~exist(logOddsSubfolder, 'dir'), mkdir(logOddsSubfolder), end
            
            % produce a mask of the brain with margin of 5 voxels
            LabelsMRI = MRIread(pathFloatingLabels);
            Labels = LabelsMRI.vol;
            brainMask = Labels > 1;
            brainMask = imfill(bwdist(brainMask)< 5, 'holes');
            
            % loop over all the labels
            for l=1:length(labelsList)
                temp_path = fullfile(logOddsSubfolder, ['logOdds_' num2str(labelsList(l)) '.nii.gz']);
                mask = (Labels == labelsList(l)); % find mask of current label
                computeLogOdds(mask, brainMask, temp_path, LabelsMRI, rho, threshold)
            end
            
            % calculate logOdds for whole hippocampus
            temp_path = fullfile(logOddsSubfolder, 'logOdds_hippo.nii.gz');
            maskHippo = Labels > 20000;
            computeLogOdds(maskHippo, brainMask, temp_path, LabelsMRI, rho, threshold)
            
            % calculate logOdds for non-hippocampus structures
            temp_path = fullfile(logOddsSubfolder, 'logOdds_non_hippo.nii.gz');
            maskNonHippo = ~maskHippo;
            computeLogOdds(maskNonHippo, brainMask, temp_path, LabelsMRI, rho, threshold)
            
        end
        
        pathFloatingHippoLabels = '';
        
        
    case 'delta function'
        
        % builds name of hippo label file that will be saved
        temp_lab = strrep(pathFloatingLabels,'.nii.gz','');
        [~,name,~] = fileparts(temp_lab);
        strrep(name, 'labels', 'hippo_labels');
        pathFloatingHippoLabels = fullfile(hippoLabelsFolder, [name, '.nii.gz']);
        
        % if file doesn't exist or must be recomputed
        if ~exist(pathFloatingHippoLabels, 'file') || recompute
            
            setFreeSurfer();
            
            FloatingLabels = MRIread(pathFloatingLabels); % read labels
            hippoMap = FloatingLabels.vol > 20000 | FloatingLabels.vol == 17 | FloatingLabels.vol == 53; % hippo mask
            FloatingLabels.vol = hippoMap;
            
            MRIwrite(FloatingLabels, pathFloatingHippoLabels); % write new file
            
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