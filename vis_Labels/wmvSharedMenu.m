function cm = wmvSharedMenu(varargin)

% wmvSharedMenu: single, reusable right-click menu for all detection boxes
%
% Previously every bounding box got its own uicontextmenu, created fresh on
% every redraw (see wmvClickMenu('GetMenu', ...)). A uicontextmenu is a child
% of the FIGURE, not of the axes, so clearing the spectrogram axes never
% deleted them -- they accumulated on HANDLES.fig.main for the whole session,
% one per visible box per redraw. Tens of thousands of dead menu objects make
% every subsequent subplot()/figure() call (and every new menu) progressively
% slower, which is what made WhaleMoanViz crawl after a while of labelling.
%
% This function keeps exactly ONE menu for the whole session. Its items are
% rebuilt at the moment it is opened, for whichever box was right-clicked --
% the box carries its own detection index in its UserData.
%
% Usage:
%   cm = wmvSharedMenu()                - handle to the shared menu
%        wmvSharedMenu('attach', h, ix) - tag graphics object h with detection
%                                         index ix and attach the shared menu
%        wmvSharedMenu('build', cm)     - internal; runs when the menu opens
%        wmvSharedMenu('reset')         - delete the shared menu
%
% Created to replace the per-box menus in plotSpec / editBoundingBox

    global REMORA

    action = 'get';
    if nargin >= 1
        action = varargin{1};
    end

    switch action

        case 'get'
            cm = getMenu();

        case 'attach'
            % attach the shared menu to a box and record which detection it is
            h   = varargin{2};
            idx = varargin{3};
            cm  = getMenu();
            if ~isempty(h) && isvalid(h)
                h.UserData = idx;
                if isprop(h, 'ContextMenu')
                    h.ContextMenu = cm;     % R2020a and later
                else
                    h.UIContextMenu = cm;   % older releases
                end
            end

        case 'build'
            % called each time the menu is opened
            cm = varargin{2};
            buildItems(cm);

        case 'reset'
            if isfield(REMORA.lt.lVis_det, 'sharedMenu') && ...
                    ~isempty(REMORA.lt.lVis_det.sharedMenu) && ...
                    isgraphics(REMORA.lt.lVis_det.sharedMenu)
                delete(REMORA.lt.lVis_det.sharedMenu);
            end
            REMORA.lt.lVis_det.sharedMenu = gobjects(1);
            cm = gobjects(1);

        otherwise
            error('wmvSharedMenu: unknown action ''%s''', action);

    end

end


function cm = getMenu()

% getMenu: return the shared menu, creating it on first use

    global REMORA HANDLES

    if isfield(REMORA.lt.lVis_det, 'sharedMenu') && ...
            ~isempty(REMORA.lt.lVis_det.sharedMenu) && ...
            isgraphics(REMORA.lt.lVis_det.sharedMenu)
        cm = REMORA.lt.lVis_det.sharedMenu;
        return
    end

    cm = uicontextmenu(HANDLES.fig.main);

    % rebuild the items whenever the menu is opened, so one menu can serve
    % every box regardless of its pr type
    if isprop(cm, 'ContextMenuOpeningFcn')
        cm.ContextMenuOpeningFcn = @(src, ~) wmvSharedMenu('build', src);  % R2020a+
    else
        cm.Callback = @(src, ~) wmvSharedMenu('build', src);               % older
    end

    REMORA.lt.lVis_det.sharedMenu = cm;

end


function buildItems(cm)

% buildItems: populate the shared menu for the box that was right-clicked

    global REMORA

    % clear the items left over from the previous right-click
    delete(cm.Children);

    idx = detectionIdxUnderCursor();
    if isempty(idx)
        return
    end

    pr = REMORA.lt.lVis_det.detection.pr(idx);

    if pr == 1
        uimenu(cm, 'Label', 'Mark FP', ...
            'Callback', @(~, ~) wmvClickMenu('MarkFP', idx));
    elseif pr == 2
        uimenu(cm, 'Label', 'Mark TP', ...
            'Callback', @(~, ~) wmvClickMenu('MarkTP', idx));
    elseif pr == 3
        uimenu(cm, 'Label', 'Delete', ...
            'Callback', @(~, ~) wmvClickMenu('Delete', idx));
        uimenu(cm, 'Label', 'Change Label', ...
            'Callback', @(~, ~) wmvClickMenu('ChangeLabel', idx));
    end

end


function idx = detectionIdxUnderCursor()

% detectionIdxUnderCursor: work out which detection was right-clicked
%
% The rectangle / patch drawn by plotSpec stores its detection index in
% UserData. drawrectangle ROIs can report an internal child as the figure's
% CurrentObject, so fall back to the detection currently being edited.

    global REMORA HANDLES

    idx = [];

    src = HANDLES.fig.main.CurrentObject;
    if ~isempty(src) && all(isvalid(src)) && isprop(src, 'UserData')
        val = src.UserData;
        if isnumeric(val) && isscalar(val)
            idx = val;
        end
    end

    if isempty(idx) && isfield(REMORA.lt.lVis_det, 'currentEdit') && ...
            isstruct(REMORA.lt.lVis_det.currentEdit) && ...
            isfield(REMORA.lt.lVis_det.currentEdit, 'detectionIdx')
        idx = REMORA.lt.lVis_det.currentEdit.detectionIdx;
    end

    % guard against a stale index (e.g. a row deleted since the box was drawn)
    if ~isempty(idx)
        if idx < 1 || idx > numel(REMORA.lt.lVis_det.detection.pr)
            idx = [];
        end
    end

end
