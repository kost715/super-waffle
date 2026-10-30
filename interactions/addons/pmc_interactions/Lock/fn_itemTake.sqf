// [unit, class] -> nothing. Takes one of the item or magazine from the unit (a broken
// lockpick); the class name is matched without regard to case (== on strings).
params ["_unit", "_class"];
if (_class == "") exitWith {};
private _item = (items _unit) findIf {_x == _class};
if (_item >= 0) exitWith {_unit removeItem ((items _unit) select _item)};
private _magazine = (magazines _unit) findIf {_x == _class};
if (_magazine >= 0) then {_unit removeMagazine ((magazines _unit) select _magazine)};
