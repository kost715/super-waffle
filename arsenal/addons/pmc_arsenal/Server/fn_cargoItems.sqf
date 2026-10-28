// Inventory of a vehicle/crate, including the contents of uniforms, vests and
// backpacks inside it -> hashmap canonical class -> amount (magazines in rounds).
params [["_container", objNull, [objNull]]];
private _out = createHashMap;
if (isNull _container) exitWith {_out};
private _add = {
    params ["_class", "_amount"];
    if !(_class isEqualType "" && {_class != ""} && {_amount isEqualType 0} && {_amount > 0}) exitWith {};
    private _key = [_class] call PMCA_fnc_itemKey;
    if (_key != "") then {_out set [_key, (_out getOrDefault [_key, 0]) + _amount]};
};
private _scan = {
    params ["_object"];
    {[_x select 0, _x select 1] call _add} forEach (magazinesAmmoCargo _object);
    (getItemCargo _object) params [["_items", []], ["_itemCounts", []]];
    {[_x, _itemCounts select _forEachIndex] call _add} forEach _items;
    (getBackpackCargo _object) params [["_packs", []], ["_packCounts", []]];
    {[_x, _packCounts select _forEachIndex] call _add} forEach _packs;
    private _weapons = weaponsItemsCargo _object;
    if (isNil "_weapons") then {_weapons = []};
    {
        {
            if (_x isEqualType "") then {[_x, 1] call _add} else {
                if (_x isEqualType [] && {count _x >= 2}) then {[_x select 0, _x select 1] call _add};
            };
        } forEach _x;
    } forEach _weapons;
    {[_x select 1] call _scan} forEach (everyContainer _object);
};
[_container] call _scan;
_out
