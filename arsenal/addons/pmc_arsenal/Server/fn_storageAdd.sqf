#include "..\defineCommon.inc"
// [storageID, [[class, amount], ...]] -> number of rows added. Server API.
// Weapons, items and backpacks are counted in pieces, magazines in magazines
// (stored as rounds, like returned partial magazines). Amount -1: unlimited.
params [["_id", "", [""]], ["_list", [], [[]]]];
if (!isServer) exitWith {0};
call PMCA_fnc_serverLoad;
private _storage = PMCA_storages getOrDefault [_id, createHashMap];
if (count _storage == 0) exitWith {0};
private _items = _storage get "items";
private _added = [];
{
    _x params [["_class", "", [""]], ["_amount", 1, [0]]];
    private _key = [_class] call PMCA_fnc_itemKey;
    if (_key != "" && {(_key call PMCA_fnc_arsenal_itemType) >= 0} && {_amount == -1 || {_amount > 0 && {_amount == floor _amount}}}) then {
        if (_amount > 0 && {isClass (configFile >> "CfgMagazines" >> _key)}) then {
            _amount = _amount * ((getNumber (configFile >> "CfgMagazines" >> _key >> "count")) max 1);
        };
        private _have = _items getOrDefault [_key, 0];
        _items set [_key, if (_have == -1 || {_amount == -1}) then {-1} else {_have + _amount}];
        _added pushBack [_key, _amount];
    };
} forEach _list;
if (_added isNotEqualTo [] && {_storage getOrDefault ["persist", true]}) then {PMCA_dirty = true};
[_id, _added, true, []] call PMCA_fnc_broadcast;
[_id, _added apply {_x select 0}] call PMCA_fnc_unlock;
count _added
