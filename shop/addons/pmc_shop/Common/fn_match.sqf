// [class name, pattern] -> true when the name fits the pattern. "*" stands for any run
// of characters (none too); the rest must match in order, ignoring case. A pattern
// without "*" must equal the name.
params [["_name", "", [""]], ["_pattern", "", [""]]];
_name = toLower _name;
_pattern = toLower _pattern;
if !("*" in _pattern) exitWith {_name == _pattern};
private _parts = _pattern splitString "*";
// splitString drops empty pieces: anchor the ends from the pattern itself.
private _openStart = (_pattern select [0, 1]) == "*";
private _openEnd = (_pattern select [count _pattern - 1, 1]) == "*";
private _at = 0;
private _ok = true;
{
    private _found = (_name select [_at]) find _x;
    if (_found < 0 || {_forEachIndex == 0 && {!_openStart} && {_found != 0}}) exitWith {_ok = false};
    _at = _at + _found + count _x;
} forEach _parts;
if (_ok && {!_openEnd} && {_parts isNotEqualTo []}) then {
    private _last = _parts select (count _parts - 1);
    _ok = count _name >= count _last && {(_name select [count _name - count _last]) == _last} && {_at <= count _name};
};
_ok
