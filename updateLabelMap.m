function labelMap = updateLabelMap(labelMap, croppedRefMaskedImage, pathRegisteredFloatingImage, pathRegisteredFloatingLabels, pathRegisteredLogOddsSubfolder, ...
    labelsList, cropping, sigma, labelPriorType, refBrainNum, floBrainNum, croppedRefSegmentation)

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

% read registered floating image and crop it around hippocampus
registeredFloatingImage = MRIread(pathRegisteredFloatingImage);
croppedRegisteredFloatingImage = registeredFloatingImage.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));

% calculate similarity between test (real) image and training (synthetic) image
likelihood = 1/sqrt(2*pi*sigma)*exp(-(croppedRefMaskedImage-croppedRegisteredFloatingImage).^2/(2*sigma^2));

switch labelPriorType
    
    case 'delta function'
        
        % read registered floating labels and extract ROI
        registeredFloatingLabels = MRIread(pathRegisteredFloatingLabels);
        croppedRegisteredFloatingLabels = registeredFloatingLabels.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        
        for k=1:length(labelsList)-1
            labelPrior = (croppedRegisteredFloatingLabels == labelsList(k)); % binary map of label k
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + labelPrior.*likelihood;  % update corresponding submatrix of labelMap
        end
        
    case 'logOdds'
        
        % initialisation
        unmargenalisedPosterior = zeros(size(labelMap));
        marginalisation = zeros(size(croppedRefMaskedImage));
        registrationName = [floBrainNum '_registered_to_' refBrainNum];
        
        for k=1:length(labelsList)-1
            
            % load logOdds and crop it around ROI
            temp_pathLogOdds = fullfile(pathRegisteredLogOddsSubfolder, ['logOdds_' num2str(labelsList(k)) '.' registrationName '.nii.gz']);
            MRILogOdds = MRIread(temp_pathLogOdds);
            labelPrior = MRILogOdds.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
            
            % update marginalisation over all labels and compute posterior
            marginalisation = marginalisation + labelPrior;
            unmargenalisedPosterior(:,:,:,k) = labelPrior.*likelihood;
            
        end
        
        %update labelMap with marginalised posterior
        labelMap = labelMap + bsxfun(@rdivide, unmargenalisedPosterior, marginalisation);
        
end

end