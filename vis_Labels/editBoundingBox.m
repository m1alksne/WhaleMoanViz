function editBoundingBox(src, detectionIdx, startX, endX, minY, maxY, label, score, color)

% editBoundingBox: handles the creation of an interactive bounding box
% whenever a detection is clicked on in the spectrogram
%
% This script is called by an event listener which is set up for every
% bounding box plotted in the spectrogram. When a rectange is clicked, an
% interactive bounding box is created. Event listeners are set up to allow
% for the finalizing of the bounding box (on key press).
% Created by Michaela Alksne and Shane Andres

    global REMORA HANDLES PARAMS % CMS added PARAMS as global var

    % if another box is already being edited, do not enter edit mode
    if ~( isa(REMORA.lt.lVis_det.currentEdit, 'double') && isempty(REMORA.lt.lVis_det.currentEdit) )
        return
    end

    % enter edit mode by turning the selected rectangle into an interactive drawrectangle
    src.Visible = 'off';  % Hide original rectangle temporarily

    % create an interactive rectangle in place of the original
    editedRect = drawrectangle('Position', [startX, minY, endX - startX, maxY - minY], ...
                               'Color', 'cyan', 'LineWidth', 2);

    % own right-click menu, as before -- but registered in overlayHandles so
    % the next plotSpec deletes it instead of leaving it on the figure
    clickMenu = wmvClickMenu('GetMenu', detectionIdx);
    if isprop(editedRect, 'ContextMenu')
        editedRect.ContextMenu = clickMenu;
    else
        editedRect.UIContextMenu = clickMenu;
    end
    if isfield(REMORA.lt.lVis_det, 'overlayHandles')
        REMORA.lt.lVis_det.overlayHandles(end+1) = clickMenu;
    else
        REMORA.lt.lVis_det.overlayHandles = clickMenu;
    end
    disp('Interactive bounding box created.');

    % save the initial rectangle properties in currentEdit
    REMORA.lt.lVis_det.currentEdit = struct( ...
        'originalRect', src, ...
        'editedRect', editedRect, ...  % store edited rectangle handle
         'startWV', PARAMS.plot.dnum, ...   % <-- pins down the reference used for pos(1) CMS edit
        'start_datenum', startX, ...
        'end_datenum', endX, ...
        'min_freq', minY, ...
        'max_freq', maxY, ...
        'label', label, ...
        'score', score, ...
        'detectionIdx', detectionIdx ...  % store index directly
    );

    % set up the KeyPressFcn to finalize with Enter key or Delete with Delete key
    set(HANDLES.fig.main, 'WindowKeyPressFcn', @(~, event) finalizeEditMode(event));    

    % set up ButtonDownFcn to cancel edit if user clicks outside box
    set(HANDLES.plt.specgram, 'HitTest', 'off', 'PickableParts', 'none');
    set(HANDLES.subplt.specgram, 'ButtonDownFcn', @(~, event) finalizeEditMode(event));
end