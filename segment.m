function accuracy = segment(pathDirTestImages, pathDirRefFirstLabels, pathDirTestLabels, pathDirTrainingLabels, pathDirTrainingImages, pathClassesTable, params)

% read and check parameters
nChannel = length(pathDirTestImages);
if nChannel > 1, multi_channel = 1; else, multi_channel = 0; end
[leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, margin, rho,...
    threshold, sigma, labelPriorType, registrationOptions, freeSurferHome, niftyRegHome] = readParams(params, nChannel);
% build paths structures
structPathsTestImages = cell(size(pathDirTestImages)); 
structPathsFirstRefLabels = cell(size(pathDirRefFirstLabels)); 
for i=1:length(pathDirTestImages), structPathsTestImages{i} = dir(pathDirTestImages{i}); end
for i=1:length(pathDirRefFirstLabels), structPathsFirstRefLabels{i} = dir(pathDirRefFirstLabels{i}); end
structPathsRefLabels = dir(pathDirTestLabels);
% parameters initialisation
nImages = length(structPathsTestImages{1});
accuracies = cell(nImages,1);
labelFusionParams = {rho threshold sigma labelPriorType deleteSubfolder recompute registrationOptions};
brainVoxels = cell(nChannel, 1);

for i=1:nImages
    
    for channel=1:nChannel
        
        % paths of reference image and corresponding FS labels
        pathRefImage = fullfile(structPathsTestImages{channel}(i).folder, structPathsTestImages{channel}(i).name);
        pathRefFirstLabels = fullfile(structPathsFirstRefLabels{channel}(i).folder, structPathsFirstRefLabels{channel}(i).name);
        pathRefLabels = fullfile(structPathsRefLabels(i).folder, structPathsRefLabels(i).name);
        
        % display processed test brain
        refBrainNum = findBrainNum(pathRefImage);
        disp(['%%% Processing test ' refBrainNum]);
        
        % copies training labels to temp folder and erase labels corresponding to test image
        if leaveOneOut && ~useSynthethicImages
            temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum, 0);
            temp_pathDirTrainingImages = copyTrainingData(pathDirTrainingImages{channel}, refBrainNum, channel*multi_channel);
        elseif leaveOneOut && useSynthethicImages
            temp_pathDirTrainingLabels = copyTrainingData(pathDirTrainingLabels, refBrainNum, 0);
            temp_pathDirTrainingImages = pathDirTrainingImages{channel};
        else
            temp_pathDirTrainingLabels = pathDirTrainingLabels;
            temp_pathDirTrainingImages = pathDirTrainingImages{channel};
        end
    
        % preprocessing test image
        disp(' '); disp(['%% preprocessing test ' refBrainNum]);
        [pathRefImage, brainVoxels{channel}] = preprocessRefImage(pathRefImage, pathRefFirstLabels, rescale, recompute, margin, freeSurferHome);
        
        % floating images generation or preprocessing of real training images
        if useSynthethicImages
            disp(['%% synthetising images for ' refBrainNum]);
            [pathDirFloatingImages, pathDirFloatingLabels] = generateTrainingImages(temp_pathDirTrainingLabels, pathClassesTable, pathRefImage, ...
                pathRefFirstLabels, recompute, freeSurferHome, niftyRegHome, debug);
        else
            disp('%% preprocessing real training images');
            [pathDirFloatingImages, pathDirFloatingLabels] = preprocessRealTrainingImages(temp_pathDirTrainingImages, temp_pathDirTrainingLabels, ...
                pathRefImage, rescale, recompute, freeSurferHome);
        end
        
    end
    
    % labelFusion
    disp(' '); disp(['%% segmenting ' refBrainNum])
    [pathSegmentation, pathHippoSegmentation] = labelFusion...
        (pathRefImage, pathDirFloatingImages, pathDirFloatingLabels, brainVoxels, labelFusionParams, freeSurferHome, niftyRegHome, debug);
    
    % evaluation
    disp(' '); disp(['%% evaluating segmentation for test ' refBrainNum]); disp(' '); disp(' ');
    accuracies{i} = computeAccuracy(pathSegmentation, pathHippoSegmentation, pathRefLabels);
    
end

pathAccuracies = fullfile(fileparts(structPathsTestImages(i).folder), 'accuracy.mat');
accuracy = saveAccuracy(accuracies, pathAccuracies);

end