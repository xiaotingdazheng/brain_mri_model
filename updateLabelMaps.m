function updateLabelMaps(likelihood, regPriorSubfolder, labelPriorType, brainVoxels, labelsList, pathTempImFolder, labelMapFolder, i)

% This function updates the labelMap matrix on which we will perform the
% argmax operation to obatin the best segmentation possible. The update
% refers to the labels obtained by registrating the current floating image
% to the reference one.
% In order to update labelMap, we have to calculate a kind of posterior
% probability (that will be maximised dduring argmax). The likelihood is a
% voxel-wise gaussian similarity measure. The prior is obtained by applying
% the registration deformation to the floating labels.
% We have two models for the floating labels. Either delta function, or
% logOdds, which is more of a probability cpaturing the uncertainty of
% segmentation around the edges of the structures.

hippoLabelList = [0 53 17];
pathLabelMap = fullfile(labelMapFolder, 'labelMap.mat');
pathLabelMapHippo = fullfile(labelMapFolder, 'labelMapHippo.mat');
if ~exist(labelMapFolder,'dir'), mkdir(labelMapFolder); end
disp('updating sum of posteriors');

% initialising/loading label maps
if ~exist(pathLabelMap,'file') || i==1
    labelMap = zeros(length(labelsList), length(brainVoxels{1}), 'single');
else
    load(pathLabelMap, 'labelMap');
end
if ~exist(pathLabelMapHippo,'file') || i== 1
    labelMapHippo = zeros(3, length(brainVoxels{1}), 'single'); 
else
    load(pathLabelMapHippo, 'labelMapHippo');
end

switch labelPriorType
    
    case 'delta function'
        
        % upadte labelMap with registered labels
        pathRegFloLabels = fullfile(regPriorSubfolder, 'labels.nii.gz');
        regFloLabels = myMRIread(pathRegFloLabels, 0, pathTempImFolder);
        regFloLabels = single(regFloLabels.vol);
        for k=1:length(labelsList)
            labelMap = processDeltaFunction(labelMap, regFloLabels, likelihood, labelsList, brainVoxels{1}, k);
        end
        
        % upadte labelMapHippo with registered hippo labels
        pathRegFloHippoLabels = fullfile(regPriorSubfolder, 'hippo_labels.nii.gz');
        regFloHippoLabels = myMRIread(pathRegFloHippoLabels, 0, pathTempImFolder);
        regFloHippoLabels = single(regFloHippoLabels.vol);
        labelMapHippo = processDeltaFunction(labelMapHippo, regFloHippoLabels, likelihood, hippoLabelList, brainVoxels{1}, 1);
        labelMapHippo = processDeltaFunction(labelMapHippo, regFloHippoLabels, likelihood, hippoLabelList, brainVoxels{1}, 2);
        labelMapHippo = processDeltaFunction(labelMapHippo, regFloHippoLabels, likelihood, hippoLabelList, brainVoxels{1}, 3);
        
    case 'logOdds'
        
        % initialisation
        unmargenalisedPosterior = zeros(size(labelMap), 'single');
        partitionFunction = zeros([1, length(brainVoxels{1})], 'single');
        
        % calculate unmargenalisedPosterior and partition function
        for k=1:length(labelsList)
            temp_pathLogOdds = fullfile(regPriorSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
            [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
                brainVoxels{1}, k, pathTempImFolder);
        end
        %update labelMap with marginalised posterior
        % labelMap = labelMap + bsxfun(@rdivide, unmargenalisedPosterior, partitionFunction);
        for k=1:length(labelsList)
            labelMap(k,:) = labelMap(k,:) + unmargenalisedPosterior(k,:)./partitionFunction;
        end
        
        % same mechanism for hipocampus logOdds
        unmargenalisedPosterior = zeros(size(labelMapHippo), 'single');
        partitionFunction = zeros([1, length(brainVoxels{1})], 'single');
        temp_pathLogOdds = fullfile(regPriorSubfolder, 'logOdds_non_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
            brainVoxels{1}, 1, pathTempImFolder);
        temp_pathLogOdds = fullfile(regPriorSubfolder, 'logOdds_right_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
            brainVoxels{1}, 2, pathTempImFolder);
        temp_pathLogOdds = fullfile(regPriorSubfolder, 'logOdds_left_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
            brainVoxels{1}, 3, pathTempImFolder);
        % labelMapHippo = labelMapHippo + bsxfun(@rdivide, unmargenalisedPosterior, partitionFunction);
        for k=1:3
            labelMapHippo(k,:) = labelMapHippo(k,:) + unmargenalisedPosterior(k,:)./partitionFunction;
        end
        
end

save(pathLabelMap, 'labelMap', '-v7.3');
save(pathLabelMapHippo, 'labelMapHippo', '-v7.3');

end

function labelMap = processDeltaFunction(labelMap, labels, likelihood, labelsList, brainVoxels, index)

labelPrior = (labels == labelsList(index)); % binary map of label k
posterior = labelPrior.*likelihood;
labelMap(index,:) = labelMap(index,:) + posterior(brainVoxels);  % update corresponding labelMap

end

function [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds, ...
    brainVoxels, index, pathTempImFolder)

% load logOdds
MRILogOdds = myMRIread(temp_pathLogOdds, 0, pathTempImFolder);
labelPrior = single(MRILogOdds.vol);

% update partition function and calculate unmargenalisedPosterior
posterior = labelPrior.*likelihood;
partitionFunction = partitionFunction + labelPrior(brainVoxels);
unmargenalisedPosterior(index,:) = posterior(brainVoxels);

end