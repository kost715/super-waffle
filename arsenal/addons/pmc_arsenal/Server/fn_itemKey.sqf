// Canonical stock class: the same base item the arsenal lists, with config case.
// Instanced radios, weapons with preset attachments and filled backpacks map to
// their base class, so taking and returning always meet under one key.
params [["_class", "", [""]]];
if (_class == "") exitWith {""};
private _cache = missionNamespace getVariable ["PMCA_itemKeys", createHashMap];
private _lower = toLowerANSI _class;
if (_lower in _cache) exitWith {_cache get _lower};
private _key = _class;
if (isClass (configFile >> "CfgWeapons" >> _key)) then {
    private _parent = getText (configFile >> "CfgWeapons" >> _key >> "tf_parent");
    if (_parent != "" && {isClass (configFile >> "CfgWeapons" >> _parent)}) then {_key = _parent};
    private _base = getText (configFile >> "CfgWeapons" >> _key >> "baseWeapon");
    if (_base != "" && {isClass (configFile >> "CfgWeapons" >> _base)}) then {_key = _base};
    private _optic = getText (configFile >> "CfgWeapons" >> _key >> "rhs_optic_base");
    if (_optic != "" && {isClass (configFile >> "CfgWeapons" >> _optic)}) then {_key = _optic};
    if (isArray (configFile >> "CfgWeapons" >> _key >> "muzzles")) then {_key = _key call BIS_fnc_baseWeapon};
    private _acre = getText (configFile >> "CfgWeapons" >> _key >> "acre_baseClass");
    if (_acre != "" && {isClass (configFile >> "CfgWeapons" >> _acre)}) then {_key = _acre};
};
if (getNumber (configFile >> "CfgVehicles" >> _key >> "isBackpack") == 1) then {_key = _key call BIS_fnc_basicBackpack};
{
    private _cfg = configFile >> _x >> _key;
    if (isClass _cfg) exitWith {_key = configName _cfg};
} forEach ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"];
_cache set [_lower, _key];
PMCA_itemKeys = _cache;
_key
