function [classesStats]=computeIntensityStats(pathImage, mergedLabels, labelsList, labelClasses, ClassNames, pathStatsMatrix)

% This function compute basic intensity statistics for different regions of
% the brain. It takes as inputs the image to derive the stats from, its
% corresponding segmentation map, and the list of label classes.
% For each class, this script computes the mean intensity, the median, the
% std deviation and the median absolute deviation. These parameters are
% then used to model the intensity distribution of each class as Gaussians.
% Here we use two types of parameters to build the Gaussians: either the
% ususal mean and std deviation, or ths median and a std deviation based on
% the MAD, which allows us to be more robust to outliers.
% A graph is built along tses calculations to visually compare the real 
% ditribution to the "mean" and "median" gaussian models.
% The output is simply the matrix gathering all the computed information.

%read image
disp('loading image');
imageMRI = MRIread(pathImage);
image = imageMRI.vol;

number_of_classes = length(ClassNames);

%define stat vectors
classesStats = zeros(4, number_of_classes);
% 1st row = mean
% 2nd row = median
% 3rd row = standard deviation
% 4th row = 1.4826*median absolute deviation (ie sigmaMAD)

figure;
for lC=1:number_of_classes
    
    disp(['processing class ', num2str(lC)]);
    intensities = [];
    
    labelsBelongingToClass = labelsList(labelClasses == lC); %labels belonging to class lC
    for l=1:length(labelsBelongingToClass)
        temp_intensities = image(mergedLabels==labelsBelongingToClass(l))'; %find values of voxels with label l
        intensities = [intensities temp_intensities]; %concatenate intensities of voxels belonging to class lC
    end
    
    classesStats(:,lC) = [mean(intensities); median(intensities); std(intensities); 1.4826*mad(intensities,1)];

    [counts,centers] = ksdensity(intensities,min(intensities):max(intensities),'bandwidth',2); %smoothed density distribution function
    prob = counts/sum(counts); %normalise counts 
    
    x=min(intensities):0.5:max(intensities);
    g_mean = 1/sqrt(2*pi*classesStats(3,lC)^2)*exp(-(x-classesStats(1,lC)).^2/(2*classesStats(3,lC)^2)); %compute N(mean,sigma)
    g_median = 1/sqrt(2*pi*classesStats(4,lC)^2)*exp(-(x-classesStats(2,lC)).^2/(2*classesStats(4,lC)^2)); %compute N(median, sigmaMAD)
    
    % Add subplot to the whole plot
    % legends commented out because take too much space on graphs but:
    % g_mean should be in blue
    % g_median sould be in orange
    % smoothed real distribution should be in yellow
    subplot(4,5,lC);
    plot(x,g_mean,'LineWidth',2); hold on; plot(x,g_median,'LineWidth',2); hold on; plot(centers,prob,'LineWidth',2); hold off; %legend('mean','median','real');
    title(['prob distrib for ',ClassNames(lC)]);

end

save(pathStatsMatrix, 'classesStats')

end