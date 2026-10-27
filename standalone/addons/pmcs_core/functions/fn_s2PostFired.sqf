// A post fired. If its target is in a player's group, record seconds since that
// group last changed side/captive: first shot = reaction time, a shot after a
// change to a friendly state = cease-fire lag.
params ["_unit"];
private _t = getAttackTarget _unit;
if (isNull _t) then {_t = assignedTarget _unit};
if (isNull _t) exitWith {};
private _uid = (group _t) getVariable ["PMCS2_uid", ""];
if (_uid == "") exitWith {};
private _r = PMCS2_records getOrDefault [_uid, createHashMap];
if (count _r == 0) exitWith {};
private _dt = (round ((diag_tickTime - (_r get "changedAt")) * 10)) / 10;
if ((_r get "firstShot") < 0) then {_r set ["firstShot", _dt]};
_r set ["lastShot", _dt];
if (diag_tickTime - (_unit getVariable ["PMCS2_loggedAt", -1e9]) >= 2) then {
    _unit setVariable ["PMCS2_loggedAt", diag_tickTime];
    [format ["shot %1 -> %2 (%3 captive=%4) %5 s after change", _unit getVariable ["PMCS2_role", ""], _uid, _r get "color", _r get "captive", _dt]] call PMCS_fnc_s2Log;
};
