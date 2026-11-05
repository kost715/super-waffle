// [unit, laptop, "personal" | "group", slot (0 rifle, 1 launcher, 2 handgun), upgrade key]
// -> nothing. Client -> server from the gunsmith's page ("Техник"). Checks the laptop, the
// weapon in that slot, the upgrade, the parts in the player's inventory, the account (the
// group's only for treasurers) and the balance; charges the money (PMC Bank journal:
// "upgrade") and asks the player's machine to swap the weapon and take the parts
// (PMCS_fnc_upgradeApply). That machine answers with PMCS_fnc_upgradeDone, which journals
// the upgrade or refunds it.
if (!isServer) exitWith {};
call PMCS_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_terminal", objNull, [objNull]], ["_account", "", [""]], ["_slot", -1, [0]], ["_key", "", [""]]];
private _owner = [_unit] call PMCS_fnc_caller;
if (_owner < 0) exitWith {};
private _deny = {[_this, []] remoteExecCall ["PMCS_fnc_notify", _owner]};
if !([_unit, _terminal, "shop"] call PMCS_fnc_terminalNear) exitWith {"STR_PMCS_ERR_FAR" call _deny};
if (!alive _unit || {vehicle _unit != _unit}) exitWith {"STR_PMCS_ERR_UPGRADE" call _deny};
if !(_slot in [0, 1, 2]) exitWith {};
private _upgrade = (call PMCS_fnc_upgrades) select {(_x select 0) == _key};
if (_upgrade isEqualTo []) exitWith {"STR_PMCS_ERR_UPGRADE" call _deny};
_upgrade = _upgrade select 0;
_upgrade params ["", "", "", "", "_op", "_price", "_parts", "_pairs"];
private _weapon = [primaryWeapon _unit, secondaryWeapon _unit, handgunWeapon _unit] select _slot;
private _target = [_weapon, _pairs] call PMCS_fnc_upgradeTarget;
if (_target == "") exitWith {"STR_PMCS_ERR_UPGRADE" call _deny};
private _items = items _unit;
private _short = false;
{
    private _class = _x;
    if (({_x == _class} count _items) < (_parts select _forEachIndex)) then {_short = true};
} forEach (call PMCS_fnc_parts);
if (_short) exitWith {"STR_PMCS_ERR_PARTS" call _deny};
call PMCB_fnc_serverLoad;
private _uid = [_unit] call PMCB_fnc_ensure;
private _bankKey = switch (_account) do {case "personal": {_uid}; case "group": {"group"}; default {""}};
if (_bankKey == "") exitWith {};
if (_bankKey == "group" && {!(_uid in PMCB_treasurers)}) exitWith {"STR_PMCS_ERR_NOT_TREASURER" call _deny};
private _balance = if (_bankKey == "group") then {PMCB_group} else {(PMCB_accounts get _uid) select 0};
if (_price > _balance) exitWith {"STR_PMCS_ERR_FUNDS" call _deny};
if (_price > 0) then {[_bankKey, -_price, "upgrade", _uid, name _unit] call PMCB_fnc_apply};
// One upgrade waits for the player's machine at a time; old unanswered ones are dropped.
if (isNil "PMCS_pendingUpgrades") then {PMCS_pendingUpgrades = createHashMap};
{
    if (diag_tickTime - (_y select 6) > 600) then {PMCS_pendingUpgrades deleteAt _x};
} forEach +PMCS_pendingUpgrades;
private _token = format ["%1:%2:%3", _uid, round (diag_tickTime * 1000), floor random 1e6];
PMCS_pendingUpgrades set [_token, [_uid, _bankKey, _price, _weapon, _target, _parts, diag_tickTime, _op]];
[_token, _slot, _weapon, _target, _parts] remoteExecCall ["PMCS_fnc_upgradeApply", _owner];
