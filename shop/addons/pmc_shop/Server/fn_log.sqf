// [actor name, text] -> nothing. Server. Appends to this mission's market journal (the
// management laptop shows it); the oldest entries beyond CBA PMCS_logLimit go.
params ["_who", "_text"];
private _two = {[str _this, "0" + str _this] select (_this < 10)};
(systemTime select [0, 5]) params ["_y", "_mo", "_d", "_h", "_mi"];
private _log = PMCS_market get "log";
_log pushBack [format ["%1-%2-%3 %4:%5", _y, _mo call _two, _d call _two, _h call _two, _mi call _two], _who, _text];
private _limit = round (missionNamespace getVariable ["PMCS_logLimit", 100]);
if (count _log > _limit) then {_log deleteRange [0, count _log - _limit]};
PMCS_dirty = true;
