// [unit] -> hashmap lower-case class -> number of banknotes of that class the unit
// carries (uniform, vest and backpack). Works for remote units on the server.
params [["_unit", objNull, [objNull]]];
private _out = createHashMap;
if (isNull _unit) exitWith {_out};
private _wanted = (call PMCB_fnc_notes) apply {toLowerANSI (_x select 0)};
{
    private _class = toLowerANSI _x;
    if (_class in _wanted) then {_out set [_class, (_out getOrDefault [_class, 0]) + 1]};
} forEach ((items _unit) + (magazines _unit));
_out
