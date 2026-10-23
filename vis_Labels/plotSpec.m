function plotSpec

% plotSpec: Plots TP / FP / FN bounding boxes on the Triton spectrogram
%
% This function is called to plot bounding boxes on the spectrogram window.
% It pulls the information for each bounding box occuring within the
% currently shown spectrogram, and calls a helper function to actually plot.
%
% Adapted from lt_lVis_plot_WAV_labels by Michaela Alksne and Shane Andres

    global REMORA PARAMS HANDLES

    % ---------------------------------------------------------------------
    % Delete the overlay objects created by the previous call.
    %
    % Rectangles / patches / text live in the spectrogram axes and are wiped
    % whenever plot_specgram redraws the image, but plotSpec is also called
    % directly with no intervening axes clear (e.g. by
    % finalizeAddDetectionMode), which used to stack a second, third, ...
    % complete set of boxes on top of the existing ones. Removing our own
    % objects first makes plotSpec idempotent: calling it twice in a row
    % leaves one set of boxes, not two. It also makes the boxes disappear
    % correctly when label display is switched off.
    % ---------------------------------------------------------------------
    if isfield(REMORA.lt.lVis_det, 'overlayHandles')
        oldHandles = REMORA.lt.lVis_det.overlayHandles;
        delete(oldHandles(isgraphics(oldHandles)));
    end
    REMORA.lt.lVis_det.overlayHandles = gobjects(0);

    % ---------------------------------------------------------------------
    % Delete orphaned axes toolbars.
    %
    % Every time plot_specgram / plot_timeseries redraw, newplot resets the
    % axes and MATLAB builds a fresh axestoolbar. The old one is not
    % destroyed with it -- it stays parented to the figure, along with its
    % ~10 buttons and ~11 internal objects, and nothing ever removes it.
    % Measured at roughly 20 stranded objects per axes reset, which is
    % unbounded over a session and slows every later subplot()/figure()
    % call, exactly as the per-box context menus used to.
    %
    % Keep whichever toolbar each live axes currently owns, bin the rest.
    % ---------------------------------------------------------------------
    staleBars = findall(HANDLES.fig.main, 'Type', 'axestoolbar');
    if ~isempty(staleBars)
        keepBar = false(size(staleBars));
        axList = findall(HANDLES.fig.main, 'Type', 'axes');
        for iAx = 1:numel(axList)
            if isprop(axList(iAx), 'Toolbar')
                tb = axList(iAx).Toolbar;
                if ~isempty(tb) && isgraphics(tb)
                    keepBar = keepBar | (staleBars == tb);
                end
            end
        end
        delete(staleBars(~keepBar));
    end

    % create start and end times of window
    startWV = PARAMS.plot.dnum;
    winLength = HANDLES.subplt.specgram.XLim(2); % get length of window in seconds, used to compute end limit
    endWV = startWV + datenum(0,0,0,0,0,winLength);

    plotFreq = PARAMS.freq1 *.9;

    colors = [
        1.0 1.0 1.0;  % white for label 1
        1.0 0.0 0.5;  % red for label 2
        0.0 1.0 0.0];  % green for label 3

    % y position for points
    yPos = plotFreq;

    % skip plotting if no detections exist
    if isempty(REMORA.lt.lVis_det.detection.labels)
        return;
    end

    if REMORA.lt.lVis_det.detection.PlotLabels
        % ---------------------------------------------------------------
        % Select every detection that OVERLAPS the window, so a box
        % straddling a window boundary is drawn (clipped) in BOTH windows
        % rather than only the one its start time happens to fall in.
        %
        % Overlap test: start <= endWV AND stop >= startWV.
        %
        % getDetectionRange is deliberately not used here. It binary-searches
        % both the starts and the stops arrays, but only starts is sorted --
        % stops is held in start_time order, and detections vary in duration,
        % so a binary search over stops can miss a box that began before this
        % window. Bound the candidates using the longest detection in the
        % file, then test overlap exactly.
        % ---------------------------------------------------------------
        detStarts = REMORA.lt.lVis_det.detection.starts;
        detStops  = REMORA.lt.lVis_det.detection.stops;

        maxDur = max(detStops - detStarts);
        if isempty(maxDur) || ~isfinite(maxDur)
            maxDur = 0;
        end

        % anything overlapping the window must start in this span
        plotIdx = find(detStarts >= (startWV - maxDur) & detStarts <= endWV);
        if ~isempty(plotIdx)
            plotIdx = plotIdx(detStops(plotIdx) >= startWV);   % exact overlap
        end

        % filter to only plot detections with pr = 1, 2, or 3
        if ~isempty(plotIdx)
            prVals = REMORA.lt.lVis_det.detection.pr(plotIdx);
            plotIdx = plotIdx(prVals == 1 | prVals == 2 | prVals == 3);
        end
%%
        % Filter by selected labels, if the filter is active
        if isfield(REMORA.lt.lVis_det, 'selectedLabels') && ...
                ~isempty(REMORA.lt.lVis_det.selectedLabels)

            keep = ismember( ...
                REMORA.lt.lVis_det.detection.labels(plotIdx), ...
                REMORA.lt.lVis_det.selectedLabels);

            plotIdx = plotIdx(keep);
        end
 %%
        % get the final detection end time for dotted line plotting
        finalDet = REMORA.lt.lVis_det.detection.stops(end);

        % call plot_labels_wav only if there are valid detections to plot
        if ~isempty(plotIdx)
            plot_labels_wav(plotIdx, yPos, colors, startWV, endWV, finalDet);
        end
    end

end


function plot_labels_wav(plotIdx, yPos, colors, startWV, endWV, finalDet)

% plot_labels_wav: Helper function to plot bounding boxes on the triton spectrogram
%
% This function is called to plot bounding boxes on the spectrogram window.
% Inputs:
% - plotIdx: list of indices if the detections to be plotted
% - yPos: the y-position of the point to be drawn for short detections
% - colors: the colors to be used for TP / FN  / FP detections
% - startWV: start time of window
% - endWV: end time of window
% - finalDet: final detection end time
%
% Every graphics object created here is recorded in
% REMORA.lt.lVis_det.overlayHandles so the next call to plotSpec can delete
% it. Nothing created here is left for someone else to clean up.


    global REMORA PARAMS HANDLES

    % set up time bounds for detections within the spectrogram window
    lablFull = [REMORA.lt.lVis_det.detection.starts, REMORA.lt.lVis_det.detection.stops];
    winDets = lablFull(plotIdx, :);

    % calculate relative times for plotting in seconds (from window start time)
    detXstart = lt_convertDatenum(winDets(:,1) - startWV, 'seconds');
    detXend = lt_convertDatenum(winDets(:,2) - startWV, 'seconds');
    detDur = detXend - detXstart;

    hold(HANDLES.subplt.specgram, 'on');
    % bounding boxes are plotted as points if they are shorter than
    % LineTresh seconds long. Note that only bounding boxes can be
    % edited currently.
    LineThresh = 0;

    % Each box gets its own right-click menu again, as it always did -- but
    % every one is now recorded in newHandles and deleted at the top of the
    % next call. That keeps the figure bounded (which is what actually caused
    % the slowdown) without the shared-menu indirection, which depended on
    % resolving the clicked object at menu-open time and broke Mark TP.

    % collect the handles of everything drawn below (rectangle + patch +
    % context menu + two text objects per box, plus the end-of-file line)
    nDet = numel(plotIdx);
    newHandles = gobjects(5*nDet + 1, 1);
    nH = 0;

    % loop through each detection to plot with label, frequency range, and score
    for iPlot = 1:nDet
        absIdx = plotIdx(iPlot);  % absolute index for this detection

        % retrieve detection metadata
        minFreq = REMORA.lt.lVis_det.detection.min_freq(absIdx);
        maxFreq = REMORA.lt.lVis_det.detection.max_freq(absIdx);
        score = REMORA.lt.lVis_det.detection.score(absIdx);
        thislabel = REMORA.lt.lVis_det.detection.labels{absIdx};
        pr_label = REMORA.lt.lVis_det.detection.pr(absIdx);  % get label type
        % choose color based on pr label
        color = colors(pr_label, :);
        % plot detection based on duration
        if detDur(iPlot) < LineThresh
            % plot a point for short detection range
            ptHandle = plot(HANDLES.subplt.specgram, detXstart(iPlot), yPos, '*', 'Color', color);
            nH = nH + 1;  newHandles(nH) = ptHandle;
        else
            % plot rectangle with ButtonDownFcn for edit mode
            rectHandle = rectangle(HANDLES.subplt.specgram, ...
                'Position', [detXstart(iPlot), minFreq, detDur(iPlot), maxFreq - minFreq], ...
                'EdgeColor', color, ...
                'LineStyle', '--',  ...
                'LineWidth', 1.5, ...
                'EdgeColor', color);
            rectHandle.ButtonDownFcn = @(src, ~) editBoundingBox(src, absIdx, ...
                detXstart(iPlot), detXend(iPlot), ...
                minFreq, maxFreq, thislabel, score, color);
            % per-box right-click menu, tracked for deletion next redraw
            clickMenu = wmvClickMenu('GetMenu', absIdx);
            rectHandle.UserData = absIdx;
            setCtxMenu(rectHandle, clickMenu);
            nH = nH + 1;  newHandles(nH) = rectHandle;
            nH = nH + 1;  newHandles(nH) = clickMenu;

            % overlay a clickable transparent patch (allows user to select
            % rectangle by clicking inside)
            x = [detXstart(iPlot), detXend(iPlot), detXend(iPlot), detXstart(iPlot)];
            y = [minFreq, minFreq, maxFreq, maxFreq];

            clickPatch = patch('XData', x, 'YData', y, ...
                'FaceColor', 'none', ...
                'EdgeColor', 'none', ...
                'Parent', HANDLES.subplt.specgram, ...
                'HitTest', 'on', ...
                'PickableParts', 'all');
            clickPatch.ButtonDownFcn = @(src, ~) editBoundingBox(src, absIdx, ...
                detXstart(iPlot), detXend(iPlot), ...
                minFreq, maxFreq, thislabel, score, color);
            clickPatch.UserData = absIdx;
            setCtxMenu(clickPatch, clickMenu);
            nH = nH + 1;  newHandles(nH) = clickPatch;

        end

        % display the label and score at the start of each detection
        % a box carried over from the previous window starts at a negative
        % x; pin its label to the left edge so it stays readable
        txtX = max(detXstart(iPlot), 0);
        labelText = text(HANDLES.subplt.specgram, txtX, maxFreq + 9, thislabel, 'Color', color, 'FontWeight', 'normal');
        scoreText = text(HANDLES.subplt.specgram, txtX, maxFreq + 3, sprintf('%.2f', score), ...
             'Color', color, 'FontWeight', 'bold');
        nH = nH + 1;  newHandles(nH) = labelText;
        nH = nH + 1;  newHandles(nH) = scoreText;
    end

    % plot a line at the end of the detection file if applicable
    if ~isempty(winDets) && isequal(plotIdx(end), finalDet)
        endLine = plot(HANDLES.subplt.specgram, [detXend(end), detXend(end)], ...
            [PARAMS.freq0, PARAMS.freq1], ':', 'LineWidth', 2, 'Color', color);
        nH = nH + 1;  newHandles(nH) = endLine;
    end

    % store the handles so the next call to plotSpec can clean them up
    REMORA.lt.lVis_det.overlayHandles = newHandles(1:nH);

    hold(HANDLES.subplt.specgram, 'off');

end


function setCtxMenu(h, cm)

% setCtxMenu: attach a context menu, using whichever property this MATLAB has

    if isprop(h, 'ContextMenu')
        h.ContextMenu = cm;      % R2020a and later
    else
        h.UIContextMenu = cm;    % older releases
    end

end
