function labelMap = updateLabelMap(labelMap, pathRegisteredFloatingLabels, croppedRefMaskedImage, croppedRegisteredFloatingImage, ...
    labelsList, cropping, sigma, labelPriorType, pathRegisteredLogOddsSubfolder, refBrainNum, floBrainNum)

% calculate similarity between test (real) image and training (synthetic) image
likelihood = 1/sqrt(2*pi*sigma)*exp(-(croppedRefMaskedImage-croppedRegisteredFloatingImage).^2/(2*sigma^2));

switch labelPriorType
    
    case 'delta function'
        
        % read registered floating labels and extract ROI
        registeredFloatingLabels = MRIread(pathRegisteredFloatingLabels);
        croppedRegisteredFloatingLabels = registeredFloatingLabels.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6));
        
        for k=1:length(labelsList)
            labelPrior = (croppedRegisteredFloatingLabels == labelsList(k)); % binary map of label k
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + labelPrior.*likelihood;  % update corresponding submatrix of labelMap
        end
        
    case 'logOdds'
        
        % initialisation
        unmargenalisedPosterior = zeros(size(labelMap));
        marginalisation = zeros(size(croppedRefMaskedImage));
        registrationName = [floBrainNum '_registered_to_' refBrainNum];
        
        for k=1:length(labelsList)
            
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