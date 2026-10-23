% rightClickMenu: contains functions to set up and assign (right click) context menus
%
% This script contains all the functions required for creating context
% menus on right clicks.
% Created by Shane Andres

function clickMenu = wmvClickMenu(action, detectionIdx)
global REMORA

    clickMenu = 0;

    if strcmp(action, 'GetMenu')
    % getClickMenu: given some detection, returns the menu appropriate for it's type.
    %
    % inputs: 
    % - detectionIdx: detection index (stored in REMORA) 
    % outputs:
    % - clickMenu (UIContextMenu): the corresponding right click menu
        
     %REMORA.lt.lVis_det.currentEdit.detectionIdx
     pr = REMORA.lt.lVis_det.detection.pr(detectionIdx);
     clickMenu = uicontextmenu;

        if pr == 1
            uimenu(clickMenu, 'Label', 'Mark FP', 'Callback', @(src, evt) wmvClickMenu('MarkFP', detectionIdx));
        elseif pr == 2
            uimenu(clickMenu, 'Label', 'Mark TP', 'Callback', @(src, evt) wmvClickMenu('MarkTP', detectionIdx));
        elseif pr == 3
            uimenu(clickMenu, 'Label', 'Delete', 'Callback', @(src, evt) wmvClickMenu('Delete', detectionIdx));
            uimenu(clickMenu, 'Label', 'Change Label', 'Callback', @(src, evt) wmvClickMenu('ChangeLabel', detectionIdx));
        end

        return;
       

    elseif strcmp(action, 'ChangeLabel')
    % ChangeLabel: a callback function to handle changing a detection's label
    %
    % This function is called by the right click menu (UIContextMenu) whenever
    % a change of labels is clicked.
    %
    % inputs:
    % - detectionIdx: the index of the detection

        labelOptions =REMORA.lt.lVis_det.labels;
        [labelIdx, ok] = listdlg('PromptString', 'Select Label:', ...
                                 'SelectionMode', 'single', ...
                                 'ListString', labelOptions);
        if ok
            label = labelOptions{labelIdx};
            disp(['Label selected: ', label]);
            REMORA.lt.lVis_det.dataTable.label(detectionIdx) = {label};
            REMORA.lt.lVis_det.detection.labels(detectionIdx) = {label};
            % initializeDetectionFields(REMORA.lt.lVis_det.dataTable, 'label')
            wmvControl('Overlay');
        else
            disp('Label selection canceled.');
        end

    elseif strcmp(action, 'Delete')
    % Delete: a callback function to handle deletion of a FN

        % delete data from dataTable
        REMORA.lt.lVis_det.dataTable(detectionIdx, :) = [];
        % update detection fields
        initializeDetectionFields(REMORA.lt.lVis_det.dataTable, 'delete');
        wmvControl('Overlay');

    elseif strcmp(action, 'MarkFP')
    % MarkFP: a callback function to mark the pr entry for a detection as FP

        % delete data from dataTable
        REMORA.lt.lVis_det.dataTable.pr(detectionIdx) = 2;
        % update detection fields
        initializeDetectionFields(REMORA.lt.lVis_det.dataTable, 'pr')
        wmvControl('Overlay');

    elseif strcmp(action, 'MarkTP')
    % MarkTP: a callback function to mark the pr entry for a detection as TP

        % delete data from dataTable
        REMORA.lt.lVis_det.dataTable.pr(detectionIdx) = 1;
        % update detection fields
        initializeDetectionFields(REMORA.lt.lVis_det.dataTable, 'pr')
        wmvControl('Overlay');

    end
end