function [leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, margin, rho, threshold, sigma, ...
    labelPriorType, regOptions, freeSurferHome, niftyRegHome] = readParams(params, nChannel)

%read params
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
regOptions = params{13};
freeSurferHome = params{14};
niftyRegHome = params{15};

%check them
if ~(leaveOneOut==0 || leaveOneOut==1), error('leaveOneOut should be 0 or 1'); end
if ~(useSynthethicImages==0 || useSynthethicImages==1), error('useSynthethicImages should be 0 or 1'); end
if ~(recompute==0 || recompute==1), error('recompute should be 0 or 1'); end
if ~(debug==0 || debug==1), error('debug should be 0 or 1'); end
if ~(deleteSubfolder==0 || deleteSubfolder==1), error('deleteSubfolder should be 0 or 1'); end
if length(targetResolution)==1, targetResolution = repmat(targetResolution, 1, 3); 
elseif ~(length(targetResolution)==3), error('targetResolution should be of length 1 (isotropic) or 3 (anisotropic)'); end
if ~(rescale==0 || rescale==1), error('rescale should be 0 or 1'); end
if rho<=0, error('rho should be a strictly positive number'); end
if threshold<0, error('threshold should be a positive or null number'); end
if sigma<=0, error('sigma should be a strictly positive number'); end
if ~isequal(labelPriorType,'logOdds') && ~isequal(labelPriorType,'delta function'), error('labelPriorType should be "delta_function" or "logOdds"'); end
if length(regOptions)==1, regOptions=repmat(regOptions,1,nChannel); 
elseif length(regOptions)~=nChannel, error('registrationOptions should be of length 1 (same for all channels) or of same length as channel number'); end
setFreeSurfer(freeSurferHome); [a,~]=system('mri_convert --help'); if a, error('freeSurferHome not recognised'); end
[a,~]=system([niftyRegHome '/reg_f3d --help']); if a, error('niftyRegHome not recognised'); end

end