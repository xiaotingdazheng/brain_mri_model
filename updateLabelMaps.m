function [labelMap, labelMapHippo, sizeSegmMap] = updateLabelMaps(labelMap, labelMapHippo, pathRefImage, pathRegFloImage, regPriorSubfolder, ...
    labelPriorType, brainVoxels, sigma, labelsList)

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

disp('updating sum of posteriors');

hippoLabelList = [0 1];

% read registered floating image
regFloImage = MRIread(pathRegFloImage);
regFloImage = single(regFloImage.vol);
regFloImage(regFloImage<0) = 0;

% read ref masked image
refImage = MRIread(pathRefImage);
refImage = single(refImage.vol);
refImage(refImage<0) = 0;
sizeSegmMap = size(refImage);

% calculate similarity between test (real) image and training (synthetic) image
likelihood = 1/sqrt(2*pi*sigma)*exp(-(refImage-regFloImage).^2/(2*sigma^2));

switch labelPriorType
    
    case 'delta function'
        
        % upadte labelMap with registered labels
        pathRegFloLabels = fullfile(regPriorSubfolder, 'labels.nii.gz');
        regFloLabels = MRIread(pathRegFloLabels);
        regFloLabels = single(regFloLabels.vol);
        for k=1:length(labelsList)
            labelMap = processDeltaFunction(labelMap, regFloLabels, likelihood, labelsList, brainVoxels, k);
        end
        
        % upadte labelMapHippo with registered hippo labels
        pathRegFloHippoLabels = fullfile(regPriorSubfolder, 'hippo_labels.nii.gz');
        regFloHippoLabels = MRIread(pathRegFloHippoLabels);
        regFloHippoLabels = single(regFloHippoLabels.vol);
        labelMapHippo = processDeltaFunction(labelMapHippo, regFloHippoLabels, likelihood, hippoLabelList, brainVoxels, 1);
        labelMapHippo = processDeltaFunction(labelMapHippo, regFloHippoLabels, likelihood, hippoLabelList, brainVoxels, 2);
        
    case 'logOdds'
        
        % initialisation
        unmargenalisedPosterior = zeros(size(labelMap), 'single');
        partitionFunction = zeros([1, length(brainVoxels)], 'single');
        
        % calculate unmargenalisedPosterior and partition function
        for k=1:length(labelsList)
            temp_pathLogOdds = fullfile(regPriorSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
            [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
                brainVoxels, k);
        end
        %update labelMap with marginalised posterior
        labelMap = labelMap + bsxfun(@rdivide, unmargenalisedPosterior, partitionFunction);
        
        % same mechanism for hipocampus logOdds
        unmargenalisedPosterior = zeros(size(labelMapHippo), 'single');
        partitionFunction = zeros([1, length(brainVoxels)], 'single');
        temp_pathLogOdds = fullfile(regPriorSubfolder, 'logOdds_non_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
            brainVoxels, 1);
        temp_pathLogOdds = fullfile(regPriorSubfolder, 'logOdds_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
            brainVoxels, 2);
        labelMapHippo = labelMapHippo + bsxfun(@rdivide, unmargenalisedPosterior, partitionFunction);
        
end

end

function labelMap = processDeltaFunction(labelMap, labels, likelihood, labelsList, brainVoxels, index)

labelPrior = (labels == labelsList(index)); % binary map of label k
posterior = labelPrior.*likelihood;
labelMap(index,:) = labelMap(index,:) + posterior(brainVoxels);  % update corresponding labelMap

end

function [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds, ...
    brainVoxels, index)

% load logOdds
MRILogOdds = MRIread(temp_pathLogOdds);
labelPrior = single(MRILogOdds.vol);

% update partition function and calculate unmargenalisedPosterior
posterior = labelPrior.*likelihood;
partitionFunction = partitionFunction + labelPrior(brainVoxels);
unmargenalisedPosterior(index,:) = posterior(brainVoxels);

end