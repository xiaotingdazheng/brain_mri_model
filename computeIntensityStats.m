function classesStats = computeIntensityStats(pathImage, pathFirstLabels, pathClassesTable, pathStatsMatrix, recompute)

% This function compute basic intensity statistics for different regions of
% the brain. It takes as inputs the image to derive the stats from, a first
% segmentation map (obtained by Freesurfer).
% For each class, this script computes the mean intensity, the median, the
% std deviation and the median absolute deviation. These parameters are
% then used to model the intensity distribution of each class as Gaussians.
% Here we use two types of parameters to build the Gaussians: either the
% ususal mean and std deviation, or ths median and a std deviation based on
% the MAD, which allows us to be more robust to outliers.

if recompute || ~exist(pathStatsMatrix, 'file')

    %read image
    imageMRI = MRIread(pathImage);
    image = imageMRI.vol;
    image = round(image);

    %read labels
    firstLabelsMRI = MRIread(pathFirstLabels);
    firstLabels = firstLabelsMRI.vol;

    %read classes
    fid = fopen(pathClassesTable, 'r');
    txt = textscan(fid,'%d %d');
    fclose(fid);
    labelsList = txt{1};
    labelClasses = txt{2};
    classesNumber = length(unique(labelClasses));

    %define stat vectors
    % 1st row = mean
    % 2nd row = median
    % 3rd row = standard deviation
    % 4th row = 1.4826*median absolute deviation (ie sigmaMAD)
    classesStats = zeros(4, classesNumber);


    for lC=1:classesNumber

        %find labels belonging to class lC
        labelsBelongingToClass = labelsList(labelClasses == lC);

        % collect intensities of voxels belonging to label l
        intensities = [];
        for l=1:length(labelsBelongingToClass)
            temp_intensities = image(firstLabels==labelsBelongingToClass(l))';
            temp_intensities = temp_intensities(temp_intensities > 0);
            intensities = [intensities temp_intensities];
        end

        % compute basic stats and save it in matrix
        classesStats(:,lC) = [mean(intensities); median(intensities); std(intensities); 1.4826*mad(intensities,1)];

    end

    save(pathStatsMatrix, 'classesStats')

else 
    
   load(pathStatsMatrix, 'classesStats');
    
end

end