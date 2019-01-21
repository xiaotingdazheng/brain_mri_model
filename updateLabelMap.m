function [labelMap, labelMapHippo] = updateLabelMap(labelMap, labelMapHippo, croppedRefMaskedImage, pathRegisteredFloatingImage, pathRegisteredFloatingLabels,...
    pathRegisteredFloatingHippoLabels, pathRegisteredLogOddsSubfolder, labelsList, cropping, sigma, labelPriorType)

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

disp('cropping registered floating labels and updating sum of posteriors');

% read registered floating image and crop it around hippocampus
registeredFloatingImage = MRIread(pathRegisteredFloatingImage);
croppedRegisteredFloatingImage = registeredFloatingImage.vol;
if cropping
    croppedRegisteredFloatingImage = croppedRegisteredFloatingImage(cropping(1):cropping(2), cropping(3):cropping(4), cropping(5):cropping(6));
end

% calculate similarity between test (real) image and training (synthetic) image
likelihood = 1/sqrt(2*pi*sigma)*exp(-(croppedRefMaskedImage-croppedRegisteredFloatingImage).^2/(2*sigma^2));

switch labelPriorType
    
    case 'delta function'
        
        % crop registered floating labels and upadte labelMap
        registeredFloatingLabels = MRIread(pathRegisteredFloatingLabels);
        croppedRegisteredFloatingLabels = registeredFloatingLabels.vol;
        if cropping
            croppedRegisteredFloatingLabels = croppedRegisteredFloatingLabels(cropping(1):cropping(2), cropping(3):cropping(4), cropping(5):cropping(6));
        end
        for k=1:length(labelsList)
            labelPrior = (croppedRegisteredFloatingLabels == labelsList(k)); % binary map of label k
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + labelPrior.*likelihood;  % update corresponding submatrix of labelMap
        end
        
        % same mechanism for hippocampus map
        registeredFloatingHippoLabels = MRIread(pathRegisteredFloatingHippoLabels);
        croppedRegisteredFloatingHippoLabels = registeredFloatingHippoLabels.vol;
        if cropping
            croppedRegisteredFloatingHippoLabels = croppedRegisteredFloatingHippoLabels(cropping(1):cropping(2), cropping(3):cropping(4), cropping(5):cropping(6));
        end
        labelPrior = (croppedRegisteredFloatingHippoLabels == 0); 
        labelMapHippo(:,:,:,1) = labelMapHippo(:,:,:,1) + labelPrior.*likelihood;
        labelPrior = (croppedRegisteredFloatingHippoLabels == 1);
        labelMapHippo(:,:,:,2) = labelMapHippo(:,:,:,2) + labelPrior.*likelihood;
        
        
    case 'logOdds'
        
        % calculate unmargenalisedPosterior and partitionFunction
        unmargenalisedPosterior = zeros(size(labelMap));
        partitionFunction = zeros(size(croppedRefMaskedImage));
        for k=1:length(labelsList)
            temp_pathLogOdds = fullfile(pathRegisteredLogOddsSubfolder, ['logOdds_' num2str(labelsList(k)) '.nii.gz']);
            [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds, cropping, k);
        end
        %update labelMap with marginalised posterior
        labelMap = labelMap + bsxfun(@rdivide, unmargenalisedPosterior, partitionFunction);
        
        % same mechanism for hipocampus logOdds
        unmargenalisedPosterior = zeros(size(labelMapHippo));
        partitionFunction = zeros(size(croppedRefMaskedImage));
        temp_pathLogOdds = fullfile(pathRegisteredLogOddsSubfolder, 'logOdds_non_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds, cropping, 1);
        temp_pathLogOdds = fullfile(pathRegisteredLogOddsSubfolder, 'logOdds_hippo.nii.gz');
        [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds, cropping, 2);
        labelMapHippo = labelMapHippo + bsxfun(@rdivide, unmargenalisedPosterior, partitionFunction);
        
end

end

function [unmargenalisedPosterior, partitionFunction] = processLogOdds(unmargenalisedPosterior, partitionFunction, likelihood, temp_pathLogOdds, cropping, index)

% load logOdds and crop it around ROI
MRILogOdds = MRIread(temp_pathLogOdds);
labelPrior = MRILogOdds.vol;
if cropping
    labelPrior = labelPrior(cropping(1):cropping(2), cropping(3):cropping(4), cropping(5):cropping(6));
end

% update marginalisation over all labels and compute posterior
partitionFunction = partitionFunction + labelPrior;
unmargenalisedPosterior(:,:,:,index) = labelPrior.*likelihood;
        
end