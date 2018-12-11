function accuracy = saveAccuracy(accuracies, namesList, labelsList, pathAccuracies)

labelsList = [labelsList , NaN];

accuracy = cell(size(accuracies,1)+3,size(accuracies,2)+2); % initialisation

% row names
accuracy{1,1} = 'brain regions'; 
accuracy{2,1} = 'associated label';
accuracy{3,1} = 'leave one out accuracies'; 
accuracy{end,1} = 'region mean accuracy';

accuracy(1,2:end-1) = namesList'; % insert brain regions' names
accuracy(2,2:end-1) = num2cell(labelsList); % insert corresponding labels
accuracy{1,end} = 'brain mean accuracy';

accuracy(3:end-1,2:end-1) = num2cell(accuracies); % results of label fusion

accuracy(end,2:end-1) = num2cell(mean(accuracies,'omitnan')); % mean Dice coef for each structure
accuracy(3:end,end) = num2cell(mean(cell2mat(accuracy(3:end,2:end-1)),2,'omitnan')); % mean Dice coef for each brain

% save created file, bottom right cell being the mean dice coefficient for
% the whole label fusion
save(pathAccuracies, 'accuracy')

end