// [unit, ATM, "personal"|"group", [[class, count], ...]] -> nothing.
// Client -> server. The player must carry the notes; their machine is asked to hand
// them over, and PMCB_fnc_depositSettle credits what actually left the inventory.
// Anyone may pay into the group's account.
if (!isServer) exitWith {};
call PMCB_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_atm", objNull, [objNull]], ["_account", "", [""]], ["_composition", [], [[]]]];
private _owner = [_unit] call PMCB_fnc_caller;
if (_owner < 0) exitWith {};
private _deny = {[_this, []] remoteExecCall ["PMCB_fnc_notify", _owner]};
if !([_unit, _atm] call PMCB_fnc_atmNear) exitWith {"STR_PMCB_ERR_FAR" call _deny};
private _busy = PMCB_pending getOrDefault [_owner, []];
if (_busy isNotEqualTo [] && {diag_tickTime - (_busy select 5) < 10}) exitWith {"STR_PMCB_ERR_BUSY" call _deny};
private _uid = [_unit] call PMCB_fnc_ensure;
private _key = switch (_account) do {case "personal": {_uid}; case "group": {"group"}; default {""}};
if (_key == "") exitWith {};
([_composition] call PMCB_fnc_parseComposition) params ["_rows", "_total"];
if (_total <= 0) exitWith {"STR_PMCB_ERR_AMOUNT" call _deny};
private _have = [_unit] call PMCB_fnc_noteCounts;
if ((_rows findIf {(_have getOrDefault [toLowerANSI (_x select 0), 0]) < (_x select 1)}) >= 0) exitWith {"STR_PMCB_ERR_NOT_CARRIED" call _deny};
PMCB_tokenSeq = (missionNamespace getVariable ["PMCB_tokenSeq", 0]) + 1;
PMCB_pending set [_owner, [PMCB_tokenSeq, _unit, _key, _rows, _have, diag_tickTime]];
[PMCB_tokenSeq, _rows] remoteExecCall ["PMCB_fnc_take", _owner];
