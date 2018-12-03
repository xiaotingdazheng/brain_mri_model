function labelMap = updateLabelMap(labelMap, croppedRefMaskedImage, croppedRegisteredFloatingImage, croppedRegisteredFloatingLabels, ...
    labelsList, cropping, sigma, labelPriorType, pathlogOddsSubfolder)

% calculate similarity between test (real) image and training (synthetic) image
likelihood = 1/sqrt(2*pi*sigma)*exp(-(croppedRefMaskedImage-croppedRegisteredFloatingImage).^2/(2*sigma^2));

switch labelPriorType
    
    case 'delta function'
        
        for k=1:length(labelsList)
            labelPrior = (croppedRegisteredFloatingLabels == labelsList(k)); % binary map of label k
            labelMap(:,:,:,k) = labelMap(:,:,:,k) + labelPrior.*likelihood;  % update corresponding submatrix of labelMap
        end
        
    case 'logOdds'
        
        unmargenalisedPosterior = zeros(size(labelMap));
        marginalisation = zeros(size(croppedRefMaskedImage));
        
        for k=1:length(labelsList)
            temp_pathLogOdds = fullfile(pathlogOddsSubfolder, ['logOdds_' num2str(labelsList(l)) '.nii.gz']); % path to logOdds file
            MRILogOdds = MRIread(temp_pathLogOdds); % load logOdds
            labelPrior = MRILogOdds.vol(cropping(1):cropping(2),cropping(3):cropping(4),cropping(5):cropping(6)); % crop LogOdds around ROI
            marginalisation = marginalisation + labelPrior; % update marginalisation over all labels
            unmargenalisedPosterior(:,:,:,k) = labelPrior.*likelihood;
        end
        
        labelMap = labelMap + bsxfun(@rdivide, unmargenalisedPosterior, marginalisation); %update labelMap with marginalised posterior
        
end

end