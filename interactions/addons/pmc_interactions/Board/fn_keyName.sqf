// [action] -> how the action's first key reads ("Space"), for the board's hints.
params ["_action"];
private _keys = [_action] call PMCI_fnc_keysOf;
if (_keys isEqualTo []) exitWith {localize "STR_PMCI_NO_KEY"};
if (!isNil "CBA_fnc_localizeKey") exitWith {(_keys select 0) call CBA_fnc_localizeKey};
keyName ((_keys select 0) select 0)
