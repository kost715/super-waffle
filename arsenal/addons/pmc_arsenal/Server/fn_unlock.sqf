// [storageID, keys] -> nothing. Server. Items whose stock reaches the CBA setting
// PMCA_unlockThreshold (pieces; magazines in full magazines) become unlimited for
// good. Without keys every item of the storage is checked.
params ["_id", "_keys"];
private _threshold = missionNamespace getVariable ["PMCA_unlockThreshold", 0];
if (!isServer || {_threshold <= 0} || {isNil "PMCA_storages"}) exitWith {};
private _storage = PMCA_storages getOrDefault [_id, createHashMap];
private _items = _storage getOrDefault ["items", createHashMap];
if (isNil "_keys") then {_keys = keys _items};
private _rows = [];
{
    private _have = _items getOrDefault [_x, 0];
    if (_have > 0) then {
        private _pieces = _have;
        if (isClass (configFile >> "CfgMagazines" >> _x)) then {
            _pieces = floor (_have / ((getNumber (configFile >> "CfgMagazines" >> _x >> "count")) max 1));
        };
        if (_pieces >= _threshold) then {_items set [_x, -1]; _rows pushBack [_x, -1]};
    };
} forEach _keys;
if (_rows isNotEqualTo [] && {_storage getOrDefault ["persist", true]}) then {PMCA_dirty = true};
[_id, _rows, true, []] call PMCA_fnc_broadcast;
