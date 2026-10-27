// RPT line "[PMCS S2] ..." plus the last 12 events shown in the console.
params [["_text", "", [""]]];
private _line = format ["%1 %2", (round (diag_tickTime * 10)) / 10, _text];
diag_log text ("[PMCS S2] " + _line);
PMCS2_events pushBack _line;
if (count PMCS2_events > 12) then {PMCS2_events deleteAt 0};
