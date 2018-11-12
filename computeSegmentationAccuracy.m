function accuracy = computeSegmentationAccuracy(labelMap, registeredGTSegmentation, listLabels)

accuracy = NaN(length(listLabels),1);

for i=1:length(listLabels)

    temp_labelMask = (labelMap == listLabels(i));
    temp_GT_Mask = (registeredGTSegmentation == listLabels(i));
    
    if unique(temp_labelMask) ~= 0 && unique(temp_GT_Mask) ~= 0
        accuracy(i) = dice(temp_labelMask, temp_GT_Mask);
    end
    
end

end

function accuracy = dice(a, b)

% compute dice coefficient between 3d binary masks
    
    accuracy = 2*sum(a.*b, 'all')/sum(a+b, 'all');
    
end