function accuracy = mergeAccuracies(pathDirAccuracies)

% paths
structPathsAccuracies = dir(pathDirAccuracies);
pathSingleAccuracyVariable = fullfile(fileparts(pathDirAccuracies), 'all_accuracies.mat');

% read all files in pathDirAccuracies and regroup them insingle variable
accuracy = cell(length(structPathsAccuracies), 1);
for i=1:length(structPathsAccuracies)
    
    pathAccuracy = fullfile(structPathsAccuracies(i).folder, structPathsAccuracies(i).name);
    varname = 'accuracies';
    temp = load(pathAccuracy, varname);
    accuracy{i} = temp.(varname);
    
end

% formate accuracy in readable file and save it
accuracy = saveAccuracy(accuracy, pathSingleAccuracyVariable);

end