// [unit, laptop, "personal" | "group", vest upgrade key] -> nothing. Client -> server from
// the gunsmith's page ("Техник"): upgrades the vest the player wears. Checks the laptop, the
// vest, the upgrade, the items it takes from the inventory (warbelts, old uniforms, the
// table's 6Sh92 or 6Sh48), the account and the balance; charges the money if any (PMC Bank
// journal: "upgrade") and asks the player's machine to swap the vest and take the items
// (PMCS_fnc_gearApply), which answers with PMCS_fnc_upgradeDone (journal or refund). An
// undo ("rev:" key) takes nothing and gives back what the upgrade took.
if (!isServer) exitWith {};
call PMCS_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_terminal", objNull, [objNull]], ["_account", "", [""]], ["_key", "", [""]]];
private _owner = [_unit] call PMCS_fnc_caller;
if (_owner < 0) exitWith {};
private _deny = {[_this, []] remoteExecCall ["PMCS_fnc_notify", _owner]};
if !([_unit, _terminal, "shop"] call PMCS_fnc_terminalNear) exitWith {"STR_PMCS_ERR_FAR" call _deny};
if (!alive _unit || {vehicle _unit != _unit}) exitWith {"STR_PMCS_ERR_UPGRADE" call _deny};
private _found = ([vest _unit] call PMCS_fnc_gearUpgradesFor) select {((_x select 0) select 0) == _key};
if (_found isEqualTo []) exitWith {"STR_PMCS_ERR_UPGRADE" call _deny};
(_found select 0) params ["_upgrade", "_target"];
private _price = _upgrade select 6;
private _take = [_upgrade] call PMCS_fnc_gearTake;
private _items = items _unit;
if ((_take findIf {private _c = _x select 0; ({_x == _c} count _items) < (_x select 1)}) >= 0) exitWith {"STR_PMCS_ERR_ITEMS" call _deny};
call PMCB_fnc_serverLoad;
private _uid = [_unit] call PMCB_fnc_ensure;
private _bankKey = switch (_account) do {case "personal": {_uid}; case "group": {"group"}; default {""}};
if (_bankKey == "") exitWith {};
if (_price > 0 && {_bankKey == "group"} && {!(_uid in PMCB_treasurers)}) exitWith {"STR_PMCS_ERR_NOT_TREASURER" call _deny};
private _balance = if (_bankKey == "group") then {PMCB_group} else {(PMCB_accounts get _uid) select 0};
if (_price > _balance) exitWith {"STR_PMCS_ERR_FUNDS" call _deny};
if (_price > 0) then {[_bankKey, -_price, "upgrade", _uid, name _unit] call PMCB_fnc_apply};
if (isNil "PMCS_pendingUpgrades") then {PMCS_pendingUpgrades = createHashMap};
{
    if (diag_tickTime - (_y select 6) > 600) then {PMCS_pendingUpgrades deleteAt _x};
} forEach +PMCS_pendingUpgrades;
private _token = format ["%1:%2:%3", _uid, round (diag_tickTime * 1000), floor random 1e6];
private _give = _upgrade param [11, []];
PMCS_pendingUpgrades set [_token, [_uid, _bankKey, _price, vest _unit, _target, [], diag_tickTime, _upgrade select 2, "gear", _take, _give]];
[_token, vest _unit, _target, _take, _give] remoteExecCall ["PMCS_fnc_gearApply", _owner];
