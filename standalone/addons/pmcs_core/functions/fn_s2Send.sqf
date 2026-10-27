params ["_unit", ["_ok", true]];
if (!isServer || {isNull _unit}) exitWith {};
private _r = PMCS2_records getOrDefault [getPlayerUID _unit, createHashMap];
if (count _r == 0) exitWith {};
private _now = diag_tickTime;
private _state = createHashMapFromArray [
    ["color", _r get "color"], ["captive", _r get "captive"], ["reason", _r get "reason"],
    ["contract", _r get "contract"], ["manual", _r get "manual"], ["inZone", _r get "inZone"], ["inGang", _r getOrDefault ["inGang", false]],
    ["distance", _r get "distance"], ["auraLeft", ceil (((_r get "auraUntil") - _now) max 0)],
    ["changedAgo", round (_now - (_r get "changedAt"))], ["firstShot", _r get "firstShot"], ["lastShot", _r get "lastShot"],
    ["undercover", PMCS2_settings get "undercover"], ["aura", PMCS2_settings get "aura"], ["forget", PMCS2_settings get "forget"],
    ["posts", keys PMCS2_posts], ["admin", [_unit] call PMCS_fnc_isAdmin], ["events", +PMCS2_events], ["ok", _ok]
];
[_state] remoteExecCall ["PMCS_fnc_s2Receive", _unit];
