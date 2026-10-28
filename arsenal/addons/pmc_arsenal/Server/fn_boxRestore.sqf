// [object, cargo] -> nothing. Server. Replaces the ordinary inventory of an object
// with a PMCA_fnc_boxCargo record: partial magazines, attachments and the contents
// of uniforms, vests and backpacks included.
params [["_object", objNull, [objNull]], ["_cargo", [], [[]]]];
if (isNull _object) exitWith {};
_cargo params [["_mags", []], ["_items", []], ["_weapons", []], ["_containers", []]];
clearMagazineCargoGlobal _object;
clearItemCargoGlobal _object;
clearWeaponCargoGlobal _object;
clearBackpackCargoGlobal _object;
{_object addMagazineAmmoCargo [_x select 0, 1, _x select 1]} forEach _mags;
{_object addItemCargoGlobal [_x select 0, _x select 1]} forEach _items;
{_object addWeaponWithAttachmentsCargoGlobal [_x, 1]} forEach _weapons;
{
    _x params ["_class", "_contents"];
    private _known = (everyContainer _object) apply {_x select 1};
    if (getNumber (configFile >> "CfgVehicles" >> _class >> "isBackpack") == 1) then {
        _object addBackpackCargoGlobal [_class, 1];
    } else {
        _object addItemCargoGlobal [_class, 1];
    };
    // The container just added is the one not seen before; its preset contents are replaced.
    private _new = ((everyContainer _object) apply {_x select 1}) - _known;
    if (_new isNotEqualTo []) then {[_new select 0, _contents] call PMCA_fnc_boxRestore};
} forEach _containers;
