function addDetection(~, ~)

% addDetection: handles the creation of new bounding boxes
%
% This script is called whenever the user wants to add a new bounding box.
% It creates a temporary rectangle (REMORA.tempRect) which the user can
% resize with their mouse. As soon as the user releases the click button,
% the box is funalized.
% Created by Michaela Alksne and Shane Andres

    global REMORA HANDLES PARAMS % CMS added params here

    % Get the initial click position
    cursorPoint = get(HANDLES.subplt.specgram, 'CurrentPoint');
    x0 = cursorPoint(1,1);
    y0 = cursorPoint(1,2);

    % Create a temporary rectangle for visual feedback
    REMORA.tempRect = rectangle(HANDLES.subplt.specgram, 'Position', [x0, y0, 1, 1], ...
                                'EdgeColor', 'cyan', 'LineWidth', 1.5, 'LineStyle', '--');
    REMORA.tempRectStartWV = PARAMS.plot.dnum;   % <--pins down the reference for pos(1) CMS edit

    % Set up a mouse motion function to resize the rectangle
    set(HANDLES.fig.main, 'WindowButtonMotionFcn', @(~, ~) updateRectangleSize(x0, y0));

    % Set up a function to finalize the box when the mouse button is released
    set(HANDLES.fig.main, 'WindowButtonUpFcn', @(~, ~) finalizeAddDetectionMode());
    
end
