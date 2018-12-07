function [labelMap, labelMapHippo] = getSegmentation(labelMap, labelMapHippo, labelsList, resultsFolder, refBrainNum)

hippoLabelList= [0, 1];

pathSegmentationWithSubfields = fullfile(resultsFolder, [refBrainNum '_segmentation_map.nii.gz']);
[~,index] = max(labelMap, [], 4);
labelMap = arrayfun(@(x) labelsList(x), index);
save(pathSegmentationWithSubfields, 'labelMap');

pathHippoSegmentation = fullfile(resultsFolder, [refBrainNum '_hippo_segmentation_map.nii.gz']);
[~,index] = max(labelMapHippo, [], 4);
labelMapHippo = arrayfun(@(x) hippoLabelList(x), index);
save(pathHippoSegmentation, 'labelMapHippo');

end