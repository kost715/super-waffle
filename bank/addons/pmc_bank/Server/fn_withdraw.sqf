// [unit, ATM, "personal"|"group", [[class, count], ...]] -> nothing.
// Client -> server. Pays out banknotes: the account is charged first, then the
// player's machine receives the notes. Only treasurers draw on the group's account.
if (!isServer) exitWith {};
call PMCB_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_atm", objNull, [objNull]], ["_account", "", [""]], ["_composition", [], [[]]]];
private _owner = [_unit] call PMCB_fnc_caller;
if (_owner < 0) exitWith {};
private _deny = {[_this, []] remoteExecCall ["PMCB_fnc_notify", _owner]};
if !([_unit, _atm] call PMCB_fnc_atmNear) exitWith {"STR_PMCB_ERR_FAR" call _deny};
private _uid = [_unit] call PMCB_fnc_ensure;
private _key = switch (_account) do {case "personal": {_uid}; case "group": {"group"}; default {""}};
if (_key == "") exitWith {};
if (_key == "group" && {!(_uid in PMCB_treasurers)}) exitWith {"STR_PMCB_ERR_NOT_TREASURER" call _deny};
([_composition] call PMCB_fnc_parseComposition) params ["_rows", "_total"];
if (_total <= 0) exitWith {"STR_PMCB_ERR_AMOUNT" call _deny};
private _balance = if (_key == "group") then {PMCB_group} else {(PMCB_accounts get _uid) select 0};
if (_total > _balance) exitWith {"STR_PMCB_ERR_FUNDS" call _deny};
[_key, -_total, "withdraw", _uid, name _unit] call PMCB_fnc_apply;
[_rows] remoteExecCall ["PMCB_fnc_give", _owner];
["STR_PMCB_DONE_WITHDRAW", [[_total] call PMCB_fnc_money]] remoteExecCall ["PMCB_fnc_notify", _owner];
[_owner, _unit] call PMCB_fnc_push;
if (_key == "group") then {[_owner] call PMCB_fnc_pushGroup};
