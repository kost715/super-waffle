// [class] -> how the gunsmith names an item it takes: the warbelt and the old uniform by
// their shop names, anything else by the game's name (CfgWeapons, then CfgMagazines), or
// the class itself.
params [["_class", "", [""]]];
(call PMCS_fnc_gearItems) params ["_belt", "_uniform"];
if (_class == _belt) exitWith {localize "STR_PMCS_ITEM_BELT"};
if (_class == _uniform) exitWith {localize "STR_PMCS_ITEM_UNIFORM"};
private _shown = getText (configFile >> "CfgWeapons" >> _class >> "displayName");
if (_shown == "") then {_shown = getText (configFile >> "CfgMagazines" >> _class >> "displayName")};
[_shown, _class] select (_shown == "")
