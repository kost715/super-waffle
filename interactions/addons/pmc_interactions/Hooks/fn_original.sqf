// [variable name, args] -> what ACE would use: a number as is, a function called with args.
// nil when ACE has no such variable (an ACE version without it).
params ["_name", "_args"];
if (_name == "" || {isNil _name}) exitWith {nil};
private _value = missionNamespace getVariable _name;
if (_value isEqualType {}) exitWith {_args call _value};
_value
