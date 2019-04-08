function [pathRefImage, pathRefFirstLabels, pathRefLabels, refBrainNum] = buildRefPaths(structPathsTestImages, structPathsFirstRefLabels, structPathsRefLabels, index)

nChannel = length(structPathsTestImages);

pathRefImage = cell(1, nChannel);
pathRefFirstLabels = cell(1, nChannel);

for channel=1:nChannel
    pathRefImage{channel} = fullfile(structPathsTestImages{channel}(index).folder, structPathsTestImages{channel}(index).name);
    pathRefFirstLabels{channel} = fullfile(structPathsFirstRefLabels{channel}(index).folder, structPathsFirstRefLabels{channel}(index).name);
end
pathRefLabels = fullfile(structPathsRefLabels(index).folder, structPathsRefLabels(index).name);

refBrainNum = findBrainNum(pathRefImage{1});

end