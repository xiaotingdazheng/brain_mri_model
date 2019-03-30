function accuracy = saveAccuracy(accuracies, pathAccuracies, labelsList, labelsNames)

accuracies = cell2mat(accuracies);

labelsList = [labelsList 53 17];

accuracy = cell(size(accuracies,1)+3,size(accuracies,2)+2); % initialisation

% rows and columns names
accuracy{1,1} = 'brain regions';
accuracy{2,1} = 'associated label';
accuracy{end,1} = 'region mean accuracy';
accuracy{3,1} = 'structure accuracies';
accuracy{1,end} = 'test brain mean accuracy';

accuracy(1,2:end-1) = labelsNames'; % insert brain regions' names
accuracy(2,2:end-1) = num2cell(labelsList); % insert corresponding labels
accuracy(3:end-1,2:end-1) = num2cell(accuracies); % results of label fusion

accuracy(3:end-1,end) = num2cell(mean(accuracies,2,'omitnan')); % mean Dice coef for each brain
accuracy(end,2:end) = num2cell(mean(cell2mat(accuracy(3:end-1,2:end)),'omitnan')); % mean Dice coef for each structure

% save created file, bottom right cell being the mean dice coefficient for
% the whole label fusion
save(pathAccuracies, 'accuracy')

end