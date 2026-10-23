function finalizeEditMode(event)

% finalizeEditMode: handles the saving / deletion of edited bounding boxes
%
% This script is called by an event listener which is set up whenever a
% user begins to edit an existing bounding box. It finalizes the box
% whether it is resized or deleted, stores the updates info inside of
% the global dataTable, and deletes the event listener.
% Created by Michaela Alksne and Shane Andres

    global REMORA HANDLES PARAMS

    % retrieve detection index, rectangle information, and label
    detectionIdx = REMORA.lt.lVis_det.currentEdit.detectionIdx;
    editedRect = REMORA.lt.lVis_det.currentEdit.editedRect;
    label = REMORA.lt.lVis_det.currentEdit.label;
    pr = REMORA.lt.lVis_det.detection.pr(detectionIdx);

    % handle button clicks
    if isa(event, 'matlab.graphics.eventdata.Hit') || isfield(event, 'IntersectionPoint')
        disp('Cancelling bounding box modifications.');
        % get rid of temporary editing box
        delete(editedRect);
    
        % clear the stored currentEdit data, remove button press listener
        REMORA.lt.lVis_det.currentEdit = [];
        set(HANDLES.subplt.specgram, 'ButtonDownFcn', '');
        
    elseif isa(event, 'matlab.ui.eventdata.KeyData') || isfield(event, 'Key')
        % check if the escape key was pressed (to cancel edits)
        if strcmp(event.Key, 'escape')
            disp('Cancelling bounding box modifications.');
            % get rid of temporary editing box
            delete(editedRect);
        
            % clear the stored currentEdit data, remove key press listener
            REMORA.lt.lVis_det.currentEdit = [];
            set(HANDLES.fig.main, 'WindowKeyPressFcn', '');
    
        
        % check if the Enter key was pressed (to save edits)
        elseif strcmp(event.Key, 'return') || strcmp(event.Key, 'enter')
            disp('Saving modified bounding box.');
            
            % convert editedRect position to absolute datenums
            pos = editedRect.Position;
%             startWV = PARAMS.plot.dnum;  % spectrogram window start time in datenum format -  CMS edit
startWV = REMORA.lt.lVis_det.currentEdit.startWV;  % use the reference captured when editing began, not a fresh read
            
            excelEpoch = datetime(2000, 1, 0);  % reference epoch
            % calculate absolute start and end times in "days since epoch"
            startTimeDays = startWV + pos(1) / (24 * 3600);  % convert seconds to days
            endTimeDays = startWV + (pos(1) + pos(3)) / (24 * 3600);  % furation in seconds to days
           
            % convert days since epoch to datetime format for the main data table
            startTime = excelEpoch + days(startTimeDays); 
            endTime = excelEpoch + days(endTimeDays);
            
            % Convert the WAV start time to datetime format
            wav_start_time_days = PARAMS.raw.dnumStart(1);  % Start time in datenum format
            wav_start_datetime = excelEpoch + days(wav_start_time_days);  % Convert to datetime
            % calculate start time in seconds relative to the WAV file start
            start_time_sec = seconds(startTime - wav_start_datetime);  % Time difference in seconds
            end_time_sec = seconds(endTime - wav_start_datetime);  % Time difference in seconds
    
            minFreq = pos(2);
            maxFreq = pos(2) + pos(4);
    
            % update main data table with edited values
            REMORA.lt.lVis_det.dataTable.start_time_sec(detectionIdx) = start_time_sec;
            REMORA.lt.lVis_det.dataTable.end_time_sec(detectionIdx) = end_time_sec;
            REMORA.lt.lVis_det.dataTable.start_time(detectionIdx) = startTime;
            REMORA.lt.lVis_det.dataTable.end_time(detectionIdx) = endTime;
            REMORA.lt.lVis_det.dataTable.min_frequency(detectionIdx) = minFreq;
            REMORA.lt.lVis_det.dataTable.max_frequency(detectionIdx) = maxFreq;
            REMORA.lt.lVis_det.dataTable.label{detectionIdx} = label;
            
            % update detection fields
            initializeDetectionFields(REMORA.lt.lVis_det.dataTable);
            % initializeDetectionFields(REMORA.lt.lVis_det.dataTable, "time");
    
            % redraw spectrogram
            wmvControl('Overlay');

            % clear the stored currentEdit data, remove key press listener
            REMORA.lt.lVis_det.currentEdit = [];
            set(HANDLES.fig.main, 'WindowKeyPressFcn', '');
           
    
        % check if the Delete or Backspace key was pressed (to delete detection)
        elseif strcmp(event.Key, 'delete') || strcmp(event.Key, 'backspace')

            if pr == 1
                disp('Marking as false positive.');
        
                % mark detection as a false positive by setting pr to 2
                REMORA.lt.lVis_det.dataTable.pr(detectionIdx) = 2;    
                % populates data structure containing each bounding box
                % (this data structure is used for plotting)
                initializeDetectionFields(REMORA.lt.lVis_det.dataTable, "pr");
        
                % remove original rectangle from the display
                delete(REMORA.lt.lVis_det.currentEdit.originalRect);

            elseif pr == 2
                disp('Selected detection is already marked as false positive, cancelling edit.');

            elseif pr == 3
                disp('Deleting selected detection.')
                % remove original rectangle from the display
                delete(REMORA.lt.lVis_det.currentEdit.originalRect);
                % delete data from dataTable
                REMORA.lt.lVis_det.dataTable(detectionIdx, :) = [];
                % update detection fields
                initializeDetectionFields(REMORA.lt.lVis_det.dataTable, "delete");

            end

            % redraw spectrogram
            wmvControl('Overlay');

            % clear the stored currentEdit data, remove key press listener
            REMORA.lt.lVis_det.currentEdit = [];
            set(HANDLES.fig.main, 'WindowKeyPressFcn', '');
            
    
        % if not a relevant key/button press, ignore
        else
            return
        end

    end
    
end
