function means = comparisonGraph(varargin)

% This function can plot several segmentation results obtained by label Fusion.
%
% inputs: - cells containing {accuracy cell, 'corresponding legend'}
%         - last input must be title of the graph
%
% output: vector with mean accuracy of all inputs

% create simplified list of brain region names
regions_names = varargin{1}{1}(1,2:end-1);
regions_names = strip(regions_names);
regions_names = strrep(regions_names,'L_','');
regions_names = strrep(regions_names,'L ','');
regions_names = strrep(regions_names,'R_','');
regions_names = strrep(regions_names,'R ','');
regions_names = strrep(regions_names,'left','');
regions_names = strrep(regions_names,'right','');
regions_names = strrep(regions_names,'mid','');
regions_names = strrep(regions_names,'anterior','');
regions_names = strrep(regions_names,'central','');
regions_names = strrep(regions_names,'posterior','');
regions_names = strip(regions_names);
new_names = unique(regions_names,'stable');

names_to_remove = {'background';'CC';'optic chiasm';'vessel';'choroid plexus';...
    'optic chiasm';'CC';'HATA';'fornix';'CSF';'accumbens area';...
    'inferior lateral ventricule';'ventral DC';'3rd ventricule';'4th ventricule'};

idx=[];
for i=1:length(names_to_remove)
   tidx = find(ismember(new_names, names_to_remove(i)));
   idx = [idx tidx];
end
new_names(idx) = [];

categories = categorical(new_names);

means = zeros(1, nargin-2);
new_accuracies = zeros(nargin-2, size(new_names,2));
legendTags = cell(1,2*length(means)); 

% average right/left means DC together and compute total means
for arg=1:nargin-2
    regions_DCs = cell2mat(varargin{arg}{1}(end,2:end-1));
    for i=1:length(new_names)
        temp_mean_DC = 0;
        count = 1;
        for j=1:length(regions_names)
            if isequal(new_names{i}, regions_names{j})
                temp_mean_DC = (1-1/count)*temp_mean_DC + regions_DCs(j)/count;
                count = count + 1;
            end
        end
        new_accuracies(arg, i) = temp_mean_DC;
    end
    if strcmp(varargin{end},'selection')
        means(arg) = mean(new_accuracies(arg, :),'omitnan');
    else
        means(arg) = varargin{arg}{1}{end,end};
    end
    
end

% create legend
for arg=1:nargin-2
    legendTags{arg} = varargin{arg}{2};
    legendTags{nargin-2+arg} = [varargin{arg}{2}, ' mean DC = ' num2str(means(arg),'%.3f')];
end

% bar plot and mean DC
figure;
bar(categories,new_accuracies');
hold on;
for arg=1:nargin-2
    plot(means(arg)*ones(size(categories)));
    hold on;
end
hold off;
ylabel('Dice coefficient')
legend(legendTags)
title(varargin{end-1})
grid on
grid minor

end