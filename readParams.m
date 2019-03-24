function [leaveOneOut, useSynthethicImages, recompute, debug, deleteSubfolder, targetResolution, rescale, alignTestImages, margin, rho, threshold, sigma, ...
    labelPriorType, regOptions, freeSurferHome, niftyRegHome, labelsList, labelClasses, labelsNames] = readParams(params, nChannel)

%read params
leaveOneOut = params{1};
useSynthethicImages = params{2};
recompute = params{3};
debug = params{4};
deleteSubfolder = params{5};
targetResolution = params{6};
rescale = params{7};
alignTestImages = params{8};
margin = params{9};
rho = params{10};
threshold = params{11};
sigma = params{12};
labelPriorType = params{13};
regOptions = params{14};
freeSurferHome = params{15};
niftyRegHome = params{16};
pathClassesTable = params{17};

%check them
if ~(leaveOneOut==0 || leaveOneOut==1), error('leaveOneOut should be 0 or 1'); end
if ~(useSynthethicImages==0 || useSynthethicImages==1), error('useSynthethicImages should be 0 or 1'); end
if ~(recompute==0 || recompute==1), error('recompute should be 0 or 1'); end
if ~(debug==0 || debug==1), error('debug should be 0 or 1'); end
if ~(deleteSubfolder==0 || deleteSubfolder==1), error('deleteSubfolder should be 0 or 1'); end
if length(targetResolution)==1
    if targetResolution == 0 && nChannel > 1
        error('please provide a non zero target resolution in the multi channel case');
    else
        targetResolution = repmat(targetResolution, 1, 3); 
    end
elseif length(targetResolution)==3 && ~all(targetResolution)
    error('targetResolution should not contain zeros when it has 3 elements')
elseif ~(length(targetResolution)==3)
    error('targetResolution should be of length 1 (isotropic) or 3 (anisotropic)'); 
end
if ~(rescale==0 || rescale==1), error('rescale should be 0 or 1'); end
if ~(alignTestImages == 0 || alignTestImages == 1 || alignTestImages == 2), error('alignImages should be 0, 1 or 2'); end
if rho<=0, error('rho should be a strictly positive number'); end
if threshold<0, error('threshold should be a positive or null number'); end

if length(sigma) == 1
    sigma = repmat(sigma, 1, nChannel);
elseif length(sigma) ~= nChannel
    error(['sigma should be of length 1 (same value for all channels), or length ' num2str(nChannel) ' (number of channels)']);
end

for i=1:nChannel, if sigma(i)<=0, error('sigma should only contain strictly positive numbers'); end; end

if ~isequal(labelPriorType,'logOdds') && ~isequal(labelPriorType,'delta function'), error('labelPriorType should be "delta_function" or "logOdds"'); end
if ~isequal(class(regOptions), 'char'), error('registrationOptions should be a string'); end
regOptions=strrep(regOptions,'_',' ');
setFreeSurfer(freeSurferHome); [a,~]=system('mri_convert --help'); if a, error('freeSurferHome not recognised'); end
[a,~]=system([niftyRegHome '/reg_f3d --help']); if a, error('niftyRegHome not recognised'); end
if isequal(class(pathClassesTable),'cell'), pathClassesTable=pathClassesTable{1}; end
if ~isequal(class(pathClassesTable), 'char'), error('registrationOptions should be a string or a cell containing the path'); end

%read classes
fid = fopen(pathClassesTable, 'r');
if fid == -1, error([pathClassesTable ' does not exist']); end
txt = textscan(fid,'%f %f %q');
fclose(fid);
labelsList = txt{1};
labelClasses = txt{2};
labelsNames = txt{3};

end