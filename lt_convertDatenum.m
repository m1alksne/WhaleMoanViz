function times = lt_convertDatenum(datenums, type)

% lt_convertDatenum: convert a DURATION expressed in days (a difference of
% two datenums) into hours, minutes or seconds.
%
% The previous version ran datevec() on the duration and read off its
% hour/minute/second fields. That silently failed in two ways:
%   - a negative duration wrapped: -2 seconds came back as 86398, because
%     datevec() of a small negative number reports 23:59:58 of the previous
%     day. This threw any detection starting before the current window far
%     off the right-hand side of the plot instead of off the left.
%   - a duration of 24 h or more lost the whole-day part entirely.
% Plain arithmetic has neither problem and is what the callers expect.

    if contains(type,'hours')
        times = datenums .* 24;

    elseif contains(type,'minutes')
        times = datenums .* (24 * 60);

    elseif contains(type,'seconds')
        times = datenums .* (24 * 3600);

    else
        error('ERROR: Type used not acceptable format. Use hours, minutes, or seconds.')
    end

end
