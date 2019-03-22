function varargout = readPaths(varargin)

% input 1: pathRefImage
% input 2: pathRefFirstLabels
% input 3: pathRefLabels
% input 4: pathDirTrainingLabels
% input 5: pathDirTrainingImages

nChannel = length(varargin{1});
useSynthethicImages = varargin{end-1};
singleBrain = varargin{end};
if isequal(varargin{5}, '') && ~useSynthethicImages, error(['please provide ' inputname(5)]); end

for input=1:nargin-2
    
    % check if input is a cell or a string. Transfrom string into cell
    if ~isequal(class(varargin{input}),'cell')
        if ~isequal(class(varargin{input}),'char')
            error([inputname(input) ' must be a string (one path) or a cell of strings (several paths)']);
        else
            varargin{input} = {varargin{input}};
        end
    end
    % check that only one set of test labels is given
    if input == 3 && length(varargin{input}) > 1
        error([inputname(1) ' should only contain one path. Please provide test labels corresponding to the first channel.']);
    end
    % check that length of input doesn't exceed channel number
    if length(varargin{input}) > nChannel
        error([inputname(input) ' contains too many paths']);
    end
    for i=1:length(varargin{input})
        % add *gz to folder names
        if ~contains(varargin{input}{i}, '.nii.gz') && ~contains(varargin{input}{i}, '.mgz')
            % check if ref files are nii.gz or mgz for singleBrainSegmentation(MultiChannel) only case with files instead of folders
            if singleBrain && input < 4
                error([inputname(input) ' channel ' num2str(i) ' is not nifty nor mgz file'])
            else
                % add *gz to folder names
                varargin{input}{i}=fullfile(varargin{input}{i}, '*gz');
                % check that they are not empty (except for pathDirTrainingImages when useSyntheticImage=1)
                if input < 5 || (input == 5 && ~useSynthethicImages)
                    temp_struct = dir(varargin{input}{i});
                    %if isempty(temp_struct), error(['folder for ' inputname(input) ' channel ' num2str(i) ' is empty']); end
                end
            end
        elseif singleBrain && input < 4 && (contains(varargin{input}{i}, 'nii.gz') || contains(varargin{input}{i}, '.mgz'))
            if ~exist(varargin{input}{i}, 'file'), error([varargin{input}{i} ' does not exist']); end
        end
        % transform paths to absolute paths
        varargin{input}{i} = abspath(varargin{input}{i});
    end
    % outputs are absolute paths
    varargout{input} = varargin{input};
    
end

% check that test images and first labels have the same length
if length(varargin{1}) ~= length(varargin{2})
    error([inputname(1) ' and ' inputname(2) ' should have the same number of paths']);
end
% check that test images and training images have the same length
if ~useSynthethicImages && length(varargin{5}) ~= length(varargin{1})
    error([inputname(1) ' and ' inputname(5) ' should have the same number of paths']);
end

end