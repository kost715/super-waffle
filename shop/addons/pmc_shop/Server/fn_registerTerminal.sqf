// [object, mode, delivery point ID] -> true. Server. Makes an object a laptop: "shop"
// (the ION market, goods go to the delivery point with that ID) or "admin" (the market
// laptop of a Zeus). Every player gets the action, those who join later too.
params [["_object", objNull, [objNull]], ["_mode", "shop", [""]], ["_point", "", [""]]];
if (!isServer || {isNull _object} || {!(_mode in ["shop", "admin"])}) exitWith {false};
call PMCS_fnc_serverLoad;
PMCS_terminals pushBackUnique _object;
_object setVariable ["PMCS_mode", _mode, true];
_object setVariable ["PMCS_point", _point, true];
[_object, _mode] remoteExec ["PMCS_fnc_terminalInit", 0, _object];
true
