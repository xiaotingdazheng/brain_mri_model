function accuracy = saveAccuracy(accuracies, pathAccuracies)

accuracies = cell2mat(accuracies);

namesList = {'background';'left cerebral WM';'left cerebral cortex';'left lateral ventricule';'left inferior lateral ventricule';...
    'left cerebellum WM';'left cerebellum cortex';'left thalamus proper';'left caudate';'left putamen';...
    'left pallidum';'3rd ventricule';'4th ventricule';'brain stem';'left amygdala';...
    'CSF';'left accumbens area';'left ventral DC';'left vessel';'left choroid plexus';'right cerebral WM';...
    'right cerebral cortex';'right lateral ventricule';'right inferior lateral ventricule';'right cerebellum WM';...
    'right cerebellum cortex';'right thalamus proper';'right caudate';'right putamen';'right pallidum';...
    'right amygdala';'right accumbens area';'right ventral DC';'right vessel';'right choroid plexus';...
    'optic chiasm';'CC posterior';'CC mid posterior';'CC central';'CC mid anterior';'CC anterior';'R CA1';...
    'R  subiculum';'R CA4DG';'R CA3';'R molecular layer';'L CA1';'L subiculum';'L CA4DG';'L CA3';...
    'L molecular layer';'hippocampus'};

labelsList = [0,2,3,4,5,7,8,10,11,12,13,14,15,16,18,24,26,28,30,31,41,42,43,44,46,47,49,50,51,52,54,...
    58,60,62,63,85,251,252,253,254,255,20001,20002,20004,20005,20006,20101,20102,20104,20105,20106, NaN];

accuracy = cell(size(accuracies,1)+3,size(accuracies,2)+2); % initialisation

% rows and columns names
accuracy{1,1} = 'brain regions';
accuracy{2,1} = 'associated label';
accuracy{end,1} = 'region mean accuracy';
accuracy{3,1} = 'structure accuracies';
accuracy{1,end} = 'test brain mean accuracy';

accuracy(1,2:end-1) = namesList'; % insert brain regions' names
accuracy(2,2:end-1) = num2cell(labelsList); % insert corresponding labels
accuracy(3:end-1,2:end-1) = num2cell(accuracies); % results of label fusion

accuracy(3:end-1,end) = num2cell(mean(accuracies,2,'omitnan')); % mean Dice coef for each brain
accuracy(end,2:end) = num2cell(mean(cell2mat(accuracy(3:end-1,2:end)),'omitnan')); % mean Dice coef for each structure

% save created file, bottom right cell being the mean dice coefficient for
% the whole label fusion
save(pathAccuracies, 'accuracy')

end