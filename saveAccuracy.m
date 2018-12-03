function saveAccuracy(accuracies, namesList, labelsList, pathAccuracies)

accuracy = cell(size(accuracies,1)+3,size(accuracies,2)+1);
accuracy{1,1} = 'brain regions'; accuracy{2,1} = 'associated label';
accuracy{3,1} = 'leave one out accuracies'; accuracy{end,1} = 'mean accuracy';
accuracy(1,2:end) = namesList';
accuracy(2,2:end) = num2cell(labelsList);
accuracy(3:end-1,2:end) = num2cell(accuracies);
accuracy(end,2:end) = num2cell(mean(accuracies,'omitnan'));
save(pathAccuracies, 'accuracy')

end