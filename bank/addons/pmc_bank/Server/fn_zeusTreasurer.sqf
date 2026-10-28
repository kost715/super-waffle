// [Zeus unit, player unit] -> nothing. Zeus module -> server. Grants the player
// withdrawals from the group's account, or takes that right away if they had it.
if (!isServer) exitWith {};
call PMCB_fnc_serverLoad;
params [["_zeus", objNull, [objNull]], ["_target", objNull, [objNull]]];
private _owner = [_zeus, false] call PMCB_fnc_caller;
if (_owner < 0 || {!([_zeus] call PMCB_fnc_isZeus)}) exitWith {};
private _uid = getPlayerUID _target;
if (isNull _target || {!isPlayer _target} || {_uid == ""}) exitWith {["STR_PMCB_ERR_NOT_PLAYER", []] remoteExecCall ["PMCB_fnc_notify", _owner]};
private _grant = !(_uid in PMCB_treasurers);
if (_grant) then {PMCB_treasurers set [_uid, name _target]} else {PMCB_treasurers deleteAt _uid};
["group", missionNamespace getVariable ["PMCB_groupName", "Group"], ["treasurer_remove", "treasurer_add"] select _grant, 0, PMCB_group,
    getPlayerUID _zeus, format ["%1 -> %2 (%3)", name _zeus, name _target, _uid]] call PMCB_fnc_log;
private _key = ["STR_PMCB_DONE_TREASURER_REMOVE", "STR_PMCB_DONE_TREASURER_ADD"] select _grant;
[_key, [name _target]] remoteExecCall ["PMCB_fnc_notify", _owner];
private _targetOwner = owner _target;
if (_targetOwner != _owner) then {[_key, [name _target]] remoteExecCall ["PMCB_fnc_notify", _targetOwner]};
if (_targetOwner in PMCB_viewers) then {[_targetOwner, _target] call PMCB_fnc_push};
