// [unit, token, done] -> nothing. Client -> server: the player's machine swapped the weapon
// (or the vest) and took the parts or items (done), or could not (they were gone by then):
// the upgrade is journalled, or its money goes back (PMC Bank journal: "upgradeRefund").
if (!isServer) exitWith {};
params [["_unit", objNull, [objNull]], ["_token", "", [""]], ["_done", false, [false]]];
private _owner = [_unit] call PMCS_fnc_caller;
if (_owner < 0 || {isNil "PMCS_pendingUpgrades"}) exitWith {};
private _pending = PMCS_pendingUpgrades getOrDefault [_token, []];
if (_pending isEqualTo []) exitWith {};
_pending params ["_uid", "_bankKey", "_price", "_from", "_to", "_parts", "", "_op", ["_what", "weapon"], ["_take", []], ["_give", []]];
if (getPlayerUID _unit != _uid) exitWith {};
PMCS_pendingUpgrades deleteAt _token;
private _money = [_price] call PMCS_fnc_money;
private _name = {private _shown = getText (configFile >> "CfgWeapons" >> _this >> "displayName"); [_shown, _this] select (_shown == "")};
if (_done) then {
    if (_what == "gear") then {
        private _taken = (_take apply {format ["%1 ×%2", (_x select 0) call PMCS_fnc_itemTitle, _x select 1]})
            + (_give apply {format ["+%1 ×%2", (_x select 0) call PMCS_fnc_itemTitle, _x select 1]});
        [name _unit, format [localize "STR_PMCS_LOG_GEAR", _from call _name, _to call _name, _money, [localize "STR_PMCS_NOTHING_TAKEN", _taken joinString ", "] select (_taken isNotEqualTo [])]] call PMCS_fnc_log;
    } else {
        [name _unit, format [localize "STR_PMCS_LOG_UPGRADE", _from call _name, _to call _name, _op, _money,
            _parts select 0, _parts select 1, _parts select 2]] call PMCS_fnc_log;
    };
    ["STR_PMCS_DONE_UPGRADE", [_to call _name, _money]] remoteExecCall ["PMCS_fnc_notify", _owner];
} else {
    if (_price > 0) then {[_bankKey, _price, "upgradeRefund", _uid, name _unit] call PMCB_fnc_apply};
    ["STR_PMCS_ERR_UPGRADE_FAILED", [_money]] remoteExecCall ["PMCS_fnc_notify", _owner];
};
[_owner, _unit, "shop", "upgraded"] call PMCS_fnc_push;
