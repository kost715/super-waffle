// [object] -> [magazines, items, weapons, containers]. Server. The ordinary
// inventory of an arsenal object, as saved to the profile: magazines
// [[class, rounds], ...], items [[class, count], ...] without uniforms and vests,
// weapons with attachments (weaponsItemsCargo), and uniforms, vests and backpacks
// as [[class, contents], ...] with their own contents in this same format.
params [["_object", objNull, [objNull]], ["_depth", 0]];
if (isNull _object || {_depth > 3}) exitWith {[[], [], [], []]};
private _containers = (everyContainer _object) apply {[_x select 0, [_x select 1, _depth + 1] call PMCA_fnc_boxCargo]};
private _items = [];
(getItemCargo _object) params [["_classes", []], ["_counts", []]];
{
    private _class = toLowerANSI _x;
    // getItemCargo also lists the uniforms and vests saved as containers.
    private _count = (_counts select _forEachIndex) - ({toLowerANSI (_x select 0) == _class} count _containers);
    if (_count > 0) then {_items pushBack [_x, _count]};
} forEach _classes;
private _weapons = weaponsItemsCargo _object;
if (isNil "_weapons") then {_weapons = []};
[magazinesAmmoCargo _object, _items, _weapons, _containers]
