function [labelMap, labelMapHippo] = updateLabelMap(labelMap, labelMapHippo, croppedRefMaskedImage, pathRegisteredFloatingImage, pathRegisteredFloatingLabels,...
    pathRegisteredFloatingHippoLabels, pathRegisteredLogOddsSubfolder, labelsList, voxelSelection, sigma, labelPriorType)

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

% read registered floating image and crop it around hippocampus
registeredFloatingImage = MRIread(pathRegisteredFloatingImage);
croppedRegisteredFloatingImage = single(registeredFloatingImage.vol);
if length(voxelSelection) == 6
    croppedRegisteredFloatingImage = ...
        croppedRegisteredFloatingImage(voxelSelection(1):voxelSelection(2), voxelSelection(3):voxelSelection(4), voxelSelection(5):voxelSelection(6));
end
croppedRegisteredFloatingImage(croppedRegisteredFloatingImage<0) = 0;

% calculate similarity between test (real) image and training (synthetic) image
likelihood = 1/sqrt(2*pi*sigma)*exp(-(croppedRefMaskedImage-croppedRegisteredFloatingImage).^2/(2*sigma^2));

switch labelPriorType
    
    case 'delta function'
        
        % crop registered floating labels and upadte labelMap
        registeredFloatingLabels = MRIread(pathRegisteredFloatingLabels);
        croppedRegisteredFloatingLabels = registeredFloatingLabels.vol;
        if length(voxelSelection) == 6
            croppedRegisteredFloatingLabels = ...
                single(croppedRegisteredFloatingLabels(voxelSelection(1):voxelSelection(2), voxelSelection(3):voxelSelection(4), voxelSelection(5):voxelSelection(6)));
        end
        for k=1:length(labelsList)
            labelPrior = (croppedRegisteredFloatingLabels == labelsList(k)); % binary map of label k
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + labelPrior.*likelihood;  % update corresponding submatrix of labelMap
        end
        
        % same mechanism for hippocampus map
        registeredFloatingHippoLabels = MRIread(pathRegisteredFloatingHippoLabels);
        croppedRegisteredFloatingHippoLabels = single(registeredFloatingHippoLabels.vol);
        if length(voxelSelection) == 6
            croppedRegisteredFloatingHippoLabels = ...
                croppedRegisteredFloatingHippoLabels(voxelSelection(1):voxelSelection(2), voxelSelection(3):voxelSelection(4), voxelSelection(5):voxelSelection(6));
        end
        labelPrior = (croppedRegisteredFloatingHippoLabels == 0); 
        labelMapHippo(:,:,:,1) = labelMapHippo(:,:,:,1) + labelPrior.*likelihood;
        labelPrior = (croppedRegisteredFloatingHippoLabels == 1);
        labelMapHippo(:,:,:,2) = labelMapHippo(:,:,:,2) + labelPrior.*likelihood;
        
    case 'logOdds'
        
        % initialisation
        if length(voxelSelection) == 6, sizePartitionFunction = size(croppedRefMaskedImage); else, sizePartitionFunction = [1, length(voxelSelection)]; end
        unmargenalisedPosterior = zeros(size(labelMap), 'single');
        partitionFunction = zeros(sizePartitionFunction, 'single');
        
        % calculate unmargenalisedPosterior and partition function
        for k=1:length(labelsList)
            temp_pathLogOdds = fullfile(pathRegisteredLogOddsSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
            [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
                voxelSelection, k);
        end
        %update labelMap with marginalised posterior
        labelMap = labelMap + bsxfun(@rdivide, unmargenalisedPosterior, partitionFunction);
        
        % same mechanism for hipocampus logOdds
        unmargenalisedPosterior = zeros(size(labelMapHippo), 'single');
        partitionFunction = zeros(sizePartitionFunction, 'single');
        temp_pathLogOdds = fullfile(pathRegisteredLogOddsSubfolder, 'logOdds_non_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
            voxelSelection, 1);
        temp_pathLogOdds = fullfile(pathRegisteredLogOddsSubfolder, 'logOdds_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds,...
            voxelSelection, 2);
        labelMapHippo = labelMapHippo + bsxfun(@rdivide, unmargenalisedPosterior, partitionFunction);
        
end

end

function [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds, ...
    voxelSelection, index)

% load logOdds and crop it around ROI
MRILogOdds = MRIread(temp_pathLogOdds);
labelPrior = single(MRILogOdds.vol);

if length(voxelSelection) == 6
    labelPrior = labelPrior(voxelSelection(1):voxelSelection(2), voxelSelection(3):voxelSelection(4), voxelSelection(5):voxelSelection(6));
    % update marginalisation over all labels and compute posterior
    partitionFunction = partitionFunction + labelPrior;
    unmargenalisedPosterior(:,:,:,index) = labelPrior.*likelihood;
else
    posterior = labelPrior.*likelihood;
    partitionFunction = partitionFunction + labelPrior(voxelSelection);
    unmargenalisedPosterior(index,:) = posterior(voxelSelection);
end

end