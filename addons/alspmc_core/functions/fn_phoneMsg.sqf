params ["_msg", ["_computer", objNull]];
private _op = _msg getOrDefault ["op", ""];
private _key = _msg getOrDefault ["key", ""];
if (_op == "questMap") exitWith {
    private _job = player getVariable ["ALS_coopJob", createHashMap];
    if !(_job getOrDefault ["alspmc", false]) exitWith {};
    call ALSPMC_fnc_questMarker;
    if (isNull _computer) then {(ALS_phone get "disp") closeDisplay 2} else {
        (uiNamespace getVariable ["ALSPMC_desktopDisp", displayNull]) closeDisplay 2;
    };
    openMap true;
};
if (_op in ["mark", "furnish", "view"]) exitWith {
    private _entry = (player getVariable ["ALSPMC_phoneState", createHashMap]) getOrDefault ["bases", []];
    if ((_entry findIf {(_x get "key") == _key}) < 0) exitWith {};
    switch (_op) do {
        case "mark": {[_key] call ALSPMC_fnc_markBase};
        case "view": {
            if (isNull _computer) then {[_key] call ALS_fnc_propView} else {[_key] call ALSPMC_fnc_desktopView};
        };
        case "furnish": {
            if (isNull _computer) then {(ALS_phone get "disp") closeDisplay 2} else {
                (uiNamespace getVariable ["ALSPMC_desktopDisp", displayNull]) closeDisplay 2;
            };
            [_key] call ALS_fnc_furnOpen;
        };
    };
};
if ((_op select [0,7]) == "company") exitWith {
    private _arg = _msg getOrDefault ["companyArg", []];
    if (isNull _computer) then {
        if (_op in ["companyAccept", "companyDecline"]) then {[player, _op, _arg, _msg getOrDefault ["token",0]] remoteExecCall ["ALSPMC_fnc_phoneDo",2]};
    } else {[player, _op, _arg, _msg getOrDefault ["token",0], _computer] remoteExecCall ["ALSPMC_fnc_desktopDo",2]};
};
if (_op == "questCancelRemote") exitWith {
    if (!isNull _computer) then {[player, _op, _key, _msg getOrDefault ["token", 0], _computer] remoteExecCall ["ALSPMC_fnc_desktopDo", 2]};
};
if !(_op in ["status", "license", "name", "base", "lock", "unlock", "sell", "questStart", "questCancel", "questReady"]) exitWith {};
private _arg = if (_op == "name") then {_msg getOrDefault ["name", []]} else {_key};
if (isNull _computer) then {
    [player, _op, _arg, _msg getOrDefault ["token", 0]] remoteExecCall ["ALSPMC_fnc_phoneDo", 2];
} else {
    [player, _op, _arg, _msg getOrDefault ["token", 0], _computer] remoteExecCall ["ALSPMC_fnc_desktopDo", 2];
};
