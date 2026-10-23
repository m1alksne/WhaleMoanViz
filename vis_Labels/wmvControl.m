function wmvControl(action)

% wmvControl: contains functions to handle GUI events
%
% This function contains many sub-functions that are called from primarily 
% GUI event handlers. Note that functions related to bounding box
% modification are not included here.
%
% Adapted from lt_lVis_control by Michaela Alksne and Shane Andres
    
    global REMORA HANDLES PARAMS
    
    
    if strcmp(action,'LoadLabels')
    % loads labels from a file

        % check if there are any unsaved edits
        if isfield(REMORA.lt.lVis_det, 'dataTable') && isfield(REMORA.lt.lVis_det, 'dataTableSaved')
            data = table2cell(sortrows(REMORA.lt.lVis_det.dataTable,'start_time'));
            dataSaved = table2cell(sortrows(REMORA.lt.lVis_det.dataTableSaved,'start_time'));
    
            % show popup if edits are not saved
            if ~isequaln(data, dataSaved) 
                % ask user to confirm exit
                choice = questdlg('Unsaved changes - do you want to discard?', ...
                                  'Discard Changes', ...
                                  'Discard', 'Cancel', 'Cancel');
                % handle response
                switch choice
                    case 'Cancel'
                        return;        
                end
            end
        end
    
        % get detection label file
        [filename, path]= uigetfile('*.txt','Select detection labels file');
        % if canceled button pushed:
        if strcmp(num2str(filename),'0')
            return
        end
        fileFullPath = fullfile(path, filename);
        
        % store the file path globally
        REMORA.lt.lVis_det.fileFullPath = fileFullPath;
        data = readtable(fileFullPath, 'Delimiter', '\t', 'ReadVariableNames', true);
        
        if height(data) == 0
            % initialize blank data table
           data = table( ...
               cell(0,1), ...         % wav_file_path
               zeros(0,1,'double'), ... % model_no
               zeros(0,1,'double'), ... % image_file_path
               cell(0,1), ...         % label
               zeros(0,1,'double'), ... % score
               zeros(0,1,'double'), ... % start_time_sec
               zeros(0,1,'double'), ... % end_time_sec
               NaT(0,1,'Format','yyyy-MM-dd HH:mm:ss'), ... % start_time
               NaT(0,1,'Format','yyyy-MM-dd HH:mm:ss'), ... % end_time
               zeros(0,1,'double'), ... % min_frequency
               zeros(0,1,'double'), ... % max_frequency
               zeros(0,1,'double'), ... % box_x1
               zeros(0,1,'double'), ... % box_x2
               zeros(0,1,'double'), ... % box_y1
               zeros(0,1,'double'), ... % box_y2
               zeros(0,1,'double'), ... % pr
               zeros(0,1,'double'), ... % sonobuoy_id
               zeros(0,1,'double'), ... % category
               'VariableNames', { ...
                   'wav_file_path','model_no','image_file_path','label','score', ...
                   'start_time_sec','end_time_sec','start_time','end_time','min_frequency', ...
                   'max_frequency','box_x1','box_x2','box_y1','box_y2','pr','sonobuoy_id','category'} ...
           );
            data.pr = ones(height(data), 1); % Initialize all as true positives
            disp("Initializing pr")
    
            REMORA.lt.lVis_det.dataTable = data;
            REMORA.lt.lVis_det.dataTableSaved = data;    
            REMORA.lt.lVis_det.detection.starts = [];
            REMORA.lt.lVis_det.detection.stops = [];
            REMORA.lt.lVis_det.detection.labels = [];
            REMORA.lt.lVis_det.detection.min_freq = [];
            REMORA.lt.lVis_det.detection.max_freq = [];
            REMORA.lt.lVis_det.detection.score = [];
            REMORA.lt.lVis_det.detection.pr = [];
        else
            % sort by the 'start_time' column
            data = sortrows(data, 'start_time');

            % % Only add fractional seconds if the timestamp has no milliseconds
            % needsFix = mod(second(data.start_time), 1) == 0;
            % 
            % data.start_time(needsFix) = ...
            %     data.start_time(needsFix) + seconds(mod(data.start_time_sec(needsFix),1));
            % 
            % data.end_time(needsFix) = ...
            %     data.end_time(needsFix) + seconds(mod(data.end_time_sec(needsFix),1));
            
            data.start_time = datetime(data.start_time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
            data.end_time = datetime(data.end_time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
            % Add only the fractional seconds from the Unix timestamps
            Starts_time = data.start_time;
            Stops_time   = data.end_time;

            excelEpoch = datetime(2000,1,0);
            
            Starts = days(Starts_time - excelEpoch);
            Stops  = days(Stops_time - excelEpoch);
        
            % add frequency and score
            Labels = data.label;
            
            % check if the 'pr' column exists; if not, initialize as true positives (1)
            if ~ismember('pr', data.Properties.VariableNames)
                data.pr = ones(height(data), 1); % Initialize all as true positives
                disp("Initializing pr")
            end
            
            min_freq = data.min_frequency;
            max_freq = data.max_frequency;
            Score = data.score;
                
            % ensure sorted
            if ~issorted(Starts)
                fprintf('Sorting labels...')
                [Starts, Permutation] = sort(Starts);
                Stops = Stops(Permutation);  % put Stops in new order
                fprintf('complete\n');
            end

            REMORA.lt.lVis_det.detection.starts = Starts;
            REMORA.lt.lVis_det.detection.stops = Stops;
            REMORA.lt.lVis_det.detection.labels = Labels;
            REMORA.lt.lVis_det.detection.min_freq = min_freq;
            REMORA.lt.lVis_det.detection.max_freq = max_freq;
            REMORA.lt.lVis_det.detection.score = Score;
            REMORA.lt.lVis_det.detection.pr = data.pr;
        end

        % save the data table to REMORA for global access
        REMORA.lt.lVis_det.dataTable = data;
        % initialize the 'saved' version of the data table 
        % (used to block accidental window closure)
        REMORA.lt.lVis_det.dataTableSaved = data;
            
        % set to display labels
        REMORA.lt.lVis_det.detection.PlotLabels = true;
        set(REMORA.lt.lVis_labels.label1Check,'Value',1)
        % add file name to gui
        REMORA.lt.lVis_det.detection.files = {filename};
        set(REMORA.lt.lVis_labels.label1Check,'Enable','on')
        set(REMORA.lt.lVis_labels.label1Check,'String',filename)
        set(REMORA.lt.lVis_labels.label1Check,'BackgroundColor',[1 1 1])
           
        % refresh window
        wmvControl('Overlay')


    else if strcmp(action,'NewLabels')
    % initializes a new label file and opens WMV window
    
        % select where new label file should be saved to
        config;
        baseFolder = PARAMS.inpath;
        [filename, path] = uiputfile('*.txt', 'Select location to save new label file', strcat(baseFolder, '/new_detections.txt'));
        if isequal(filename,0) || isequal(path,0) % triggers when user clicks cancel in file save popup
           disp('New label file creation cancelled.')
           return
        end
        fileFullPath = fullfile(path, filename);
        REMORA.lt.lVis_det.fileFullPath = fileFullPath;  
        

        % open WMV window and modify for label creation mode
        wmvWindow;
        set(REMORA.fig.lt.lVis_settings,'Name', 'Create Labels');
        REMORA.lt.lVis_verify.load1.Enable = 'off';
        REMORA.lt.lVis_det.newFile = true;
        
        % initialize blank data table
        data = table( ...
           cell(0,1), ...         % wav_file_path
           zeros(0,1,'double'), ... % model_no
           zeros(0,1,'double'), ... % image_file_path
           cell(0,1), ...         % label
           zeros(0,1,'double'), ... % score
           zeros(0,1,'double'), ... % start_time_sec
           zeros(0,1,'double'), ... % end_time_sec
           NaT(0,1,'Format','yyyy-MM-dd HH:mm:ss'), ... % start_time
           NaT(0,1,'Format','yyyy-MM-dd HH:mm:ss'), ... % end_time
           zeros(0,1,'double'), ... % min_frequency
           zeros(0,1,'double'), ... % max_frequency
           zeros(0,1,'double'), ... % box_x1
           zeros(0,1,'double'), ... % box_x2
           zeros(0,1,'double'), ... % box_y1
           zeros(0,1,'double'), ... % box_y2
           zeros(0,1,'double'), ... % pr
           zeros(0,1,'double'), ... % sonobuoy_id
           zeros(0,1,'double'), ... % category
           'VariableNames', { ...
               'wav_file_path','model_no','image_file_path','label','score', ...
               'start_time_sec','end_time_sec','start_time','end_time','min_frequency', ...
               'max_frequency','box_x1','box_x2','box_y1','box_y2','pr','sonobuoy_id','category'} ...
        );

        REMORA.lt.lVis_det.dataTable = data;
        REMORA.lt.lVis_det.dataTableSaved = data;    
        REMORA.lt.lVis_det.detection.starts = [];
        REMORA.lt.lVis_det.detection.stops = [];
        REMORA.lt.lVis_det.detection.labels = [];
        REMORA.lt.lVis_det.detection.min_freq = [];
        REMORA.lt.lVis_det.detection.max_freq = [];
        REMORA.lt.lVis_det.detection.score = [];
        REMORA.lt.lVis_det.detection.pr = [];

        
        % set to display labels
        REMORA.lt.lVis_det.detection.PlotLabels = true;
        set(REMORA.lt.lVis_labels.label1Check,'Value',1)
        % add file name to gui
        REMORA.lt.lVis_det.detection.files = {filename};
        set(REMORA.lt.lVis_labels.label1Check,'Enable','on')
        set(REMORA.lt.lVis_labels.label1Check,'String',filename)
     
        set(REMORA.lt.lVis_labels.label1Check,'BackgroundColor',[1 1 1])
        
    
    elseif strcmp(action, 'LoadPrev')
    % grabs previous recording from the folder the current recording is from
    
         % getting folder path and audio file extension
        folder = PARAMS.inpath;
        file = PARAMS.infile;
        parts = split(file, '.');
        name = parts{1};
        ext  = strcat('.', strjoin(parts(2:end), '.'));

        % retrieving file path of all audio files in folder with same extension
        files = dir(folder);
        filteredFiles = {};
        for k = 1:length(files)
            if contains(files(k).name, '.')
                parts = split(files(k).name, '.');
                if strcmp(strcat('.', strjoin(parts(2:end), '.')), ext)
                    filteredFiles{end+1} = files(k).name;
                end
            end
        end
        
        % extract names, sort alphabetically
        sortedFiles = sort(filteredFiles);
        idx = find(strcmp(sortedFiles, file));
  
         % retrieve the name of the next file (if it exists)
        if ~isempty(idx) && idx > 1
            openFile(sortedFiles{idx - 1}, folder);
        else
            disp('First file! No files found before current file inside source folder.')
        end

        % add overlays
        wmvControl('Overlay');
    

    elseif strcmp(action, 'LoadNext')
    % grabs next recording from the folder the current recording is from
    
        % getting folder path and audio file extension
        folder = PARAMS.inpath;
        file = PARAMS.infile;
        parts = split(file, '.');
        name = parts{1};
        ext  = strcat('.', strjoin(parts(2:end), '.'));

        % retrieving file path of all audio files in folder with same extension
        files = dir(folder);
        filteredFiles = {};
        for k = 1:length(files)
            if contains(files(k).name, '.')
                parts = split(files(k).name, '.');
                if strcmp(strcat('.', strjoin(parts(2:end), '.')), ext)
                    filteredFiles{end+1} = files(k).name;
                end
            end
        end
        
        % extract names, sort alphabetically
        sortedFiles = sort(filteredFiles);
        idx = find(strcmp(sortedFiles, file));
    
        % retrieve the name of the next file (if it exists)
        if ~isempty(idx) && idx < length(sortedFiles)
            openFile(sortedFiles{idx + 1}, folder);
        else
            disp('Last file! No files found after current file inside source folder.')
        end

        % add overlays
        wmvControl('Overlay');
        
    
    elseif strcmp(action,'Display')
    % redraws detection overlays on spectrogram / time series plots
       
        enabled = get(REMORA.lt.lVis_labels.label1Check,'Enable');
        if strcmp(enabled,'on')
            checked = get(REMORA.lt.lVis_labels.label1Check,'Value');
            if checked
                REMORA.lt.lVis_det.detection.PlotLabels = true;
            else
                REMORA.lt.lVis_det.detection.PlotLabels = false;
            end
        else
            return
        end
        
        wmvControl('Overlay')

    elseif strcmp(action, 'Overlay')
    % redraws all plots and overlays labels on spectrogram / time series plots

        % if bounding box is being edited, deletes edit and resets keypress listener
        if (~isempty(REMORA.lt.lVis_det.currentEdit) && ~isempty(REMORA.lt.lVis_det.currentEdit.editedRect))
            delete(REMORA.lt.lVis_det.currentEdit.editedRect);
            REMORA.lt.lVis_det.currentEdit = [];
            set(HANDLES.subplt.specgram, 'ButtonDownFcn', '');
        end

        % refreshes triton plot window
        plot_triton

        if HANDLES.display.specgram.Value
            plotSpec
        end
        
        if HANDLES.display.timeseries.Value
            plotTimeSeries
        end    
             
    elseif strcmp(action, 'SmallStepBack')
    % callback function to move plots backwards
        motion('back');
        wmvControl('Overlay');
        
    

   
    elseif strcmp(action, 'SmallStepForward')
    % callback function to move plots forwards
        motion('forward');
        wmvControl('Overlay');
        
    % elseif strcmp(action, 'PrevDetection')
    %     motion('prevDet');
    %     wmvControl('Overlay');
    elseif strcmp(action, 'PrevDetection')

        [prevDet, ~] = lt_lVis_envDet_rf;

        if isempty(prevDet)
            disp('First detection! No detections found before current window.')
            return
        end

        % Previous detection is still inside the current x.wav
        if prevDet >= PARAMS.raw.dnumStart(1)
            disp(prevDet)
            disp(PARAMS.raw.dnumStart(1))
            motion('prevDet');
            wmvControl('Overlay');
            return
        else
            wmvControl('LoadPrev')
        end

        % ---------- Cross-x.wav case only --------- 

        winLength = PARAMS.tseg.sec;
        stepFW = winLength * 0.5;
        PARAMS.plot.dnum = prevDet - datenum([0 0 0 0 0 stepFW]);
        PARAMS.plot.dvec = datevec(PARAMS.plot.dnum);

        readseg
        plot_triton
        wmvControl('Overlay'); 
                
    
    elseif strcmp(action, 'NextDetection')
        [~, nextDet] = lt_lVis_envDet_rf;
    
        if isempty(nextDet)
            disp('Last detection! No detections found after current window.')
            return
        end
    
        REMORA.lt.lVis_det.suppressOverlay = true;
    
        while nextDet > PARAMS.raw.dnumEnd(end)
            wmvControl('LoadNext');
        end
    
        REMORA.lt.lVis_det.suppressOverlay = false;
    
        motion('nextDet');
        wmvControl('Overlay');

        
    
    elseif strcmp(action, 'AddDetection')
    % callback function for adding a detection to the plot
        if isfield(REMORA, 'tempRect') && ~isequal(REMORA.tempRect, [])
            return % do nothing if already in add detecton mode
        end

        disp('Click and drag on the spectrogram to add a new detection.');
    
        % Set up normal click for adding a bounding box
        set(HANDLES.fig.main, 'WindowButtonDownFcn', @addDetection);
        
    
    elseif strcmp(action, 'SaveEdits')
    % callback function for saving the current edits
        if isfield(REMORA.lt.lVis_det, 'fileFullPath')
            saveEditedDetections(REMORA.lt.lVis_det.fileFullPath);
        end


    elseif strcmp(action, 'makeNewExamples')
    % callback function for creating new training examples from detections
        wmvControl('SaveEdits');
        if isfield(REMORA.lt.lVis_det, 'verifiedFilePath')
            makeNewExamples;
        end
%%
    elseif strcmp(action, 'FilterDetections')
        % callback function for filtering detections
        disp('Filter detections button clicked.');
    
        labelOptions = REMORA.lt.lVis_det.labels;

        [selectedIdx, ok] = listdlg( ...
            'PromptString', 'Select labels to display:', ...
            'SelectionMode', 'multiple', ...
            'ListString', labelOptions);
    
        if ~ok
            return;
        end
    
        selectedLabels = labelOptions(selectedIdx);
    
        % Store the selected labels
        REMORA.lt.lVis_det.selectedLabels = selectedLabels;
    
        % Refresh the display
        wmvControl('Overlay');
   end   
%%     

   % graying out forwards / backwards buttons if at end / beginning of file
   % (this is achieved by copying the current state of the previous / next
   % buttons inside of the control window)
    if ~isempty(PARAMS.infile)
        set(REMORA.lt.lVis_labels.RFfwd,'Enable',...
            get(HANDLES.motion.fwd,'Enable'));
        set(REMORA.lt.lVis_labels.nextF,'Enable',...
            get(HANDLES.motion.nextfile,'Enable'));
        set(REMORA.lt.lVis_labels.RFback,'Enable',...
            get(HANDLES.motion.back,'Enable'));
        set(REMORA.lt.lVis_labels.prevF,'Enable',...
            get(HANDLES.motion.prevfile,'Enable'));
    end

end 
