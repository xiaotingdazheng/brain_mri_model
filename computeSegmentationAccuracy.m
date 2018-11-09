function accuracy = computeSegmentationAccuracy(labelMap, registeredGTSegmentation, listLabels)

accuracy = zeros(length(listLabels),1);

for i=1:length(listLabels)

    temp_labelMap = (labelMap == listLabels(i));
    temp_GT = (registeredGTSegmentation == listLabels(i));
    
    accuracy(i) = dice(temp_labelMap, temp_GT);
    
end

end

function accuracy = dice(a, b)
    
    accuracy = 2*sum(sum((a.*b)))/sum(sum((a+b)));
    
end