// Console requests. Own state: any player. Shared settings and posts: host/admin.
params [["_unit", objNull, [objNull]], ["_op", "", [""]], ["_arg", ""]];
if (!isServer || {!(missionNamespace getVariable ["PMCS2_ready", false])} || {isNull _unit} || {!isPlayer _unit}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != owner _unit}) exitWith {false};
private _r = PMCS2_records getOrDefault [getPlayerUID _unit, createHashMap];
if (count _r == 0) exitWith {false};
private _admin = [_unit] call PMCS_fnc_isAdmin;
private _ok = switch (_op) do {
    case "status": {true};
    case "contract": {
        if !(_arg in ["none", "west", "east", "guer"]) exitWith {false};
        _r set ["contract", _arg]; true
    };
    case "manual": {
        if !(_arg in ["", "west", "east", "guer", "civ"]) exitWith {false};
        _r set ["manual", _arg]; true
    };
    case "undercover": {
        if (!_admin || {!(_arg in ["side", "captive"])}) exitWith {false};
        PMCS2_settings set ["undercover", _arg]; true
    };
    case "aura": {
        if (!_admin || {!(_arg in [30, 300])}) exitWith {false};
        PMCS2_settings set ["aura", _arg]; true
    };
    case "forget": {
        if (!_admin || {!(_arg isEqualType true)}) exitWith {false};
        PMCS2_settings set ["forget", _arg]; true
    };
    case "post": {
        if (!_admin || {!(_arg in ["west", "east", "guer", "civ", "gang", "clear"])}) exitWith {false};
        [_arg] call PMCS_fnc_s2Post
    };
    default {false};
};
if (_ok && {_op != "status"}) then {[format ["request %1 %2 %3 by %4", _op, _arg, ["", "(admin)"] select _admin, _r get "uid"]] call PMCS_fnc_s2Log};
[_unit, _ok] call PMCS_fnc_s2Send;
_ok
