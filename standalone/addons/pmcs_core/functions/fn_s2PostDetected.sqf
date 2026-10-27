params ["_post", "_target"];
private _uid = (group _target) getVariable ["PMCS2_uid", ""];
if (_uid == "") exitWith {};
private _r = PMCS2_records getOrDefault [_uid, createHashMap];
if (count _r == 0) exitWith {};
[format ["detected %1 by %2 (%3 captive=%4) %5 s after change", _uid, (leader _post) getVariable ["PMCS2_role", ""], _r get "color", _r get "captive",
    (round ((diag_tickTime - (_r get "changedAt")) * 10)) / 10]] call PMCS_fnc_s2Log;
