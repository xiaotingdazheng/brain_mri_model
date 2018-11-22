function [croppedSegmentation, cropping] = cropHippo(Segmentation, margin)

HippoLabels = [17,53,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106];

SegmentationMask = zeros(size(Segmentation));

for h=1:length(hippoLabels)
    SegmentationMask = SegmentationMask | Segmentation==HippoLabels(h); %logical mask of hippocampus by performing or operation
end

[croppedSegmentation, cropping] = cropLabelVol(maskmri, margin);

end