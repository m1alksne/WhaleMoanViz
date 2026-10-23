
function initializeDetectionFields(data, changeType)

% initializeDetectionFields: Populates the "detection" data structure
% (used when plotting bounding boxes)
%
% The information for each detected / added bounding box audio is stored in 
% a dataTable which is updated whenever a bounding box is modified.
% The "detection" data structure stores a copy of this
% information, which is used for plotting each bounding box, and 
% it must be updated whenever the dataTable is. This script is used to 
% populate the "detection" data structure.
% 
% Note that the dataTable is passed in as an argument.
% Created by Michaela Alksne

% Doesn't sortrows unless a detection was added or time is changed because sortrows
% is O(n*logn) time complexity
% changeType can be pr, delete, which will update the detection fields but
% not call sortrows

% Updated by Max Niu 

    global REMORA

    if nargin < 2
        changeType = 'full';
    end

    % Only sort when row order may have changed
    if any(strcmp(changeType, {'add', 'time', 'full'})) 
        data = sortrows(data, 'start_time');
        REMORA.lt.lVis_det.dataTable = data;
    end

    excelEpoch = datetime(2000, 1, 0);

    REMORA.lt.lVis_det.detection.starts = days(data.start_time - excelEpoch);
    REMORA.lt.lVis_det.detection.stops = days(data.end_time - excelEpoch);
    REMORA.lt.lVis_det.detection.labels = data.label;
    REMORA.lt.lVis_det.detection.min_freq = data.min_frequency;
    REMORA.lt.lVis_det.detection.max_freq = data.max_frequency;
    REMORA.lt.lVis_det.detection.score = data.score;
    REMORA.lt.lVis_det.detection.pr = data.pr;

end