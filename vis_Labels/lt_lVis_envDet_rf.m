function [prevDet,nextDet] = lt_lVis_envDet_rf()

% lt_lVis_envDet: finds the nearest detections not shown in the current window, 
% one before and one after.
%
% This function is called by "motion.m" in the base Triton package as a
% helper function to move the plot window the previous or next detection.
% It returns the closest detection before the window (prevDet) and after
% the window (nextDet).
% 
% The naming for this function is legacy from another Remora, since the 
% base Triton package looks for a function with this name specifically.

    global REMORA PARAMS HANDLES
    
    prevDet = [];
    nextDet = [];
    
    % create start and end times of window
    startWV = PARAMS.plot.dnum;
    if isfield(HANDLES.subplt,'specgram')
        winLength = HANDLES.subplt.specgram.XLim(2);
    elseif isfield(HANDLES.subplt,'timeseries')
        winLength = HANDLES.subplt.timeseries.XLim(2);
    else
        disp('Error: cannot jump to next/previous rf detection. Please plot either spectrogram, timeseries, or both to use this function')
        return
    end
    endWV = startWV + datenum(0,0,0,0,0,winLength);
    
    % finds the nearest detections
    if isfield(REMORA.lt.lVis_det.detection,'starts')
        labs = REMORA.lt.lVis_det.detection.starts;
        labels = REMORA.lt.lVis_det.detection.labels;
    
        % Apply label filter if active
        if isfield(REMORA.lt.lVis_det, 'selectedLabels') && ...
                ~isempty(REMORA.lt.lVis_det.selectedLabels)
    
            keep = ismember(labels, REMORA.lt.lVis_det.selectedLabels);
            labs = labs(keep);
        end
    
        next = labs(find(labs > endWV, 1));
        prev = labs(find(labs < startWV, 1, 'last'));
    end
    
    % check if previous / next detection exists, and exclude detections 
    % outside of current LTSA file  

    if ~isempty(next) && next <= PARAMS.ltsa.end.dnum
        nextDet = next;
    end
    
    if ~isempty(prev) && prev >= PARAMS.ltsa.start.dnum
        prevDet = prev;
    end

end
