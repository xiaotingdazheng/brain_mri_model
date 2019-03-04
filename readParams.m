function [leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, margin, rho, threshold, sigma, ...
    labelPriorType, registrationOptions, freeSurferHome, niftyRegHome] = readParams(params)
leaveOneOut = params{1};
useSynthethicImages = params{2};
recompute = params{3};
debug = params{4};
deleteSubfolder = params{5};
targetResolution = params{6};
rescale = params{7};
margin = params{8};
rho = params{9};
threshold = params{10};
sigma = params{11};
labelPriorType = params{12};
registrationOptions = params{13};
freeSurferHome = params{14};
niftyRegHome = params{15};
end