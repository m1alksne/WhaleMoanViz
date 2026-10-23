function finalizeAddDetectionMode(~,~)

% finalizeAddDetectionMode: handles the completion of a newly added bounding box
%
% This script is called by an event handler which is set up once a new
% bounding box has begun to be drawn. It stores the new bounding box inside
% of the global dataTable, deletes the temporary rectangle, and disables
% the event handler.
% Created by Michaela Alksne

    global REMORA PARAMS HANDLES
    
    % Disable the motion function to stop updating the rectangle
    set(HANDLES.fig.main, 'WindowButtonMotionFcn', '');

     % Prompt for label selection
    labelOptions =REMORA.lt.lVis_det.labels;

    %runtime long because it's waiting for user input
    [labelIdx, ok] = listdlg('PromptString', 'Select Label:', ...
                             'SelectionMode', 'single', ...
                             'ListString', labelOptions);
    
    if ok
        label = labelOptions{labelIdx};
        disp(['Label selected: ', label]);
        
         % Save the new detection
        pos = REMORA.tempRect.Position;
                         
%         startWV = PARAMS.plot.dnum;  % Spectrogram window start time in datenum format
startWV = REMORA.tempRectStartWV;  % use the reference captured when the box was started, not a fresh read CMS edit

        % Convert seconds to datenum and calculate absolute start and end times
        startTimeDays = startWV + pos(1) / (24 * 3600);  % Convert seconds offset to days
        endTimeDays = startWV + (pos(1) + pos(3)) / (24 * 3600);  % Duration in days
        % Convert days since epoch (datenum) to datetime
        excelEpoch = datetime(2000, 1, 0);  % Reference epoch for Triton format
        startTime = excelEpoch + days(startTimeDays);
        endTime = excelEpoch + days(endTimeDays);
        minFreq = pos(2);
        maxFreq = pos(2) + pos(4);
    
        % Convert the WAV start time to datetime format
        wav_start_time_days = PARAMS.raw.dnumStart(1);  % Start time in datenum format
        wav_start_datetime = excelEpoch + days(wav_start_time_days);  % Convert to datetime

        % Calculate start time in seconds relative to the WAV file start
        start_time_sec = seconds(startTime - wav_start_datetime);  % Time difference in seconds
        end_time_sec = seconds(endTime - wav_start_datetime);  % Time difference in seconds

        startTime.Format = 'yyyy-MM-dd HH:mm:ss.SSS'; % Display with fractions of a second
        endTime.Format = 'yyyy-MM-dd HH:mm:ss.SSS'; % Display with fractions of a second
        % Retrieve necessary fields for new detection row
        wav_file_path = fullfile(PARAMS.inpath, PARAMS.infile);
        score = 1;  % Default score, adjust if needed
        pr = 3;  % Default to false negative for new detections

        % Create a blank row by copying the first row (or zero row) and setting blanks
        newRow = blankRowLike(REMORA.lt.lVis_det.dataTable);
        
        % Fill in only relevant fields in dataTable (rest will be blank)
        newRow.wav_file_path = {wav_file_path};
        newRow.label = {label};
        newRow.score = score;
        newRow.start_time_sec = start_time_sec;
        newRow.end_time_sec = end_time_sec;
        newRow.start_time = startTime;
        newRow.end_time = endTime;
        newRow.min_frequency = minFreq;
        newRow.max_frequency = maxFreq;
        newRow.pr = pr;
        
        % Append the row
        REMORA.lt.lVis_det.dataTable = [REMORA.lt.lVis_det.dataTable; newRow];

        % Sort by start_time to keep order consistent
        REMORA.lt.lVis_det.dataTable = sortrows(REMORA.lt.lVis_det.dataTable, 'start_time');

        % Update detection fields
        initializeDetectionFields(REMORA.lt.lVis_det.dataTable);

    else 
        % If canceled, remove the temporary rectangle
        disp('Label selection canceled.');
        delete(REMORA.tempRect);
        REMORA.tempRect = [];
        
    end 

    % Clear the temporary rectangle used for drawing
    delete(REMORA.tempRect);
    REMORA.tempRect = [];
    
    % Reset callback functions to exit "Add Detection" mode
    set(HANDLES.fig.main, 'WindowButtonDownFcn', '');
    set(HANDLES.fig.main, 'WindowButtonMotionFcn', '');
    set(HANDLES.fig.main, 'WindowButtonUpFcn', '');
    set(HANDLES.fig.main, 'WindowKeyPressFcn', '');

    plotSpec;
    if HANDLES.display.timeseries.Value
        plotTimeSeries
    end   
    REMORA.lt.lVis_det.dataTable.start_time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
    REMORA.lt.lVis_det.dataTable.end_time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
end


function row = blankRowLike(T)
% blankRowLike: creates a row of the same structure as T, with blank values
% Works even if T has 0 rows

    varNames = T.Properties.VariableNames;
    varTypes = varfun(@class, T, 'OutputFormat', 'cell'); % get column types
    nVars = numel(varNames);

    % Preallocate containers for each column
    data = cell(1, nVars);

    for k = 1:nVars
        type = varTypes{k};

        switch type
            case 'cell'
                data{k} = {[]};
            case 'char'
                data{k} = {''};
            case 'string'
                data{k} = missing;
            case 'categorical'
                data{k} = categorical(missing);
            case 'datetime'
                data{k} = NaT;
            case 'double'
                data{k} = NaN;
            case 'single'
                data{k} = single(NaN);
            case 'logical'
                data{k} = false;
            otherwise
                data{k} = missing;
        end
    end

    % Build table
    row = cell2table(data, 'VariableNames', varNames);
end



% 

% function row = blankRowLike(T)
% 
% % blankRowLike: creates a row of the same structure as T, with blank values
% % (necessary because the dataTable of detections contains multiple types)
% 
%     row = T(ones(1,1),:);
%     for k = 1:width(T)
%         var = T.Properties.VariableNames{k};
%         val = T.(var);
%         if iscell(val)
%             row.(var) = {[]};
%         elseif ischar(val)
%             row.(var) = {''};
%         elseif isstring(val)
%             row.(var) = missing;
%         elseif iscategorical(val)
%             row.(var) = categorical(missing);
%         elseif isdatetime(val)
%             row.(var) = NaT;
%         elseif isnumeric(val)
%             row.(var) = NaN;
%         elseif islogical(val)
%             row.(var) = false;
%         else
%             row.(var) = missing;
%         end
%     end
% end
