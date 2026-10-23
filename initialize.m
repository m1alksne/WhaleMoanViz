global REMORA HANDLES PARAMS

% initialization script for label tracking remora
% Created by Michaela Alksne and Shane Andres

% config

REMORA.lt.menu = uimenu(HANDLES.remmenu,'Label','&WhaleMoanVizGit',...
    'Enable','on','Visible','on');

uimenu(REMORA.lt.menu, 'Label', 'Visualize Labels', ...
    'Callback', 'wmvWindow');

uimenu(REMORA.lt.menu, 'Label', 'Create Labels', ...
       'Callback', 'wmvControl(''NewLabels'')');


if ~isfield(REMORA,'fig')
    REMORA.fig = [];
end
