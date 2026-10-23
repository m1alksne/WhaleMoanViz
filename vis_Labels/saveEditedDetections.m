function saveEditedDetections(fileFullPath)

% saveEditedDetections: saves all existing and new detections to a file
%
% This script saves all of the existing and new detections to a .txt file,
% in the format of a tab-delimited table. For newly created labels, this
% will save to whatever file name the user specified in the popup window.
%
% For loaded detections, this will be stored in a file with 
% the same name as the original detections, except that 'raw' will be replaced
% with 'verified'. If this word is not found within the original name, then
% the file will be saved as [original name]_verified.txt
% Created by Michaela Alksne and Shane Andres

    global REMORA

    % Format here just in case
    REMORA.lt.lVis_det.dataTable.start_time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
    REMORA.lt.lVis_det.dataTable.end_time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
    
    % access the main data table
    data = REMORA.lt.lVis_det.dataTable;

    % naming the new label file
    [folder, name, ext] = fileparts(fileFullPath);



    % set file name for newly created detections
    if isfield(REMORA.lt.lVis_det, 'newFile') && REMORA.lt.lVis_det.newFile == true
        saveFileName = name;
        saveFilePath = fullfile(folder, [saveFileName, ext]);
        REMORA.lt.lVis_det.verifiedFilePath = saveFilePath;

    % set file name for loaded detections
    else
        % if original file name contains "raw", replace with "verified"
        if contains(name, 'raw')
            saveFileName = strrep(name, 'raw', 'verified');
        % if file name already contains "verified", overwrite
        elseif contains(name, 'verified')
            saveFileName = name;
        % if file name does not contain either, append "_verified" to end
        else
            saveFileName = strcat(name, '_verified');
        end
        saveFilePath = fullfile(folder, [saveFileName, ext]);
        REMORA.lt.lVis_det.verifiedFilePath = saveFilePath;
    end




    % write the updated data table to the new file
    try
        writetable(data, saveFilePath, 'Delimiter', '\t');  % save as tab-delimited file
        % recording saved table only when writing file is successful
        % saved table in memory matches table in files
        REMORA.lt.lVis_det.dataTableSaved = REMORA.lt.lVis_det.dataTable; 
        disp(['Edits successfully saved to ', saveFilePath]);
        REMORA.lt.lVis_det.saveFilePath = saveFilePath;
    catch ME
        disp('Error saving edits to file:');
        disp(ME.message);
    end
    
end
