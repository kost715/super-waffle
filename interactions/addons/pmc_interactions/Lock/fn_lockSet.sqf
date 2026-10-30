// [Zeus unit, box, type, difficulty, key class, code] -> nothing. Server, from the Zeus
// module's window. Locks the box ("classic" with a key, "code" or "safe" with a code of 4
// to 6 digits) or opens it ("none"). The code stays on the server; every machine, players
// joining later too, gets [type, difficulty, key, code length] and locks the inventory
// (PMCI_fnc_lockApply).
if (!isServer) exitWith {};
params [["_zeus", objNull, [objNull]], ["_box", objNull, [objNull]], ["_type", "", [""]], ["_difficulty", 1, [0]],
    ["_key", "", [""]], ["_code", "", [""]]];
if (isNull _zeus || {isNull _box} || {isRemoteExecuted && {owner _zeus != remoteExecutedOwner}} || {isNull getAssignedCuratorLogic _zeus}) exitWith {};
if (_type == "none") exitWith {
    [_box, _zeus, "STR_PMCI_LOCK_REMOVED"] call PMCI_fnc_lockClear;
};
if !(_type in ["classic", "code", "safe"]) exitWith {};
if (_type == "classic") then {_code = ""} else {_key = ""};
if (_type != "classic" && {!([_code] call PMCI_fnc_codeValid)}) exitWith {
    ["STR_PMCI_LOCK_ERR_CODE"] remoteExecCall ["PMCI_fnc_lockNotify", _zeus];
};
private _lock = [_type, 0 max (round _difficulty min 2), _key, count _code];
_box setVariable ["PMCI_lockCode", _code];
_box setVariable ["PMCI_lock", _lock];
[_box, _lock] remoteExecCall ["PMCI_fnc_lockApply", 0, _box];
["STR_PMCI_LOCK_DONE"] remoteExecCall ["PMCI_fnc_lockNotify", _zeus];
