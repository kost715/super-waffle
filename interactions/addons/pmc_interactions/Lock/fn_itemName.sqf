// [class] -> the item's display name, or the class name when no config has it.
params ["_class"];
private _name = "";
{
    private _config = configFile >> _x >> _class;
    if (_name == "" && {isClass _config}) then {_name = getText (_config >> "displayName")};
} forEach ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"];
[_name, _class] select (_name == "")
