// [class name, pattern] -> [matched, captures]: what each "*" of the pattern stood for, in
// order, in the name's own spelling ("MMM_weap_AK74_H2S1" by "MMM_weap_AK74_H*S*" ->
// [true, ["2", "1"]]). Case is ignored when matching; a pattern without "*" must equal
// the name (no captures).
params [["_name", "", [""]], ["_pattern", "", [""]]];
private _low = toLower _name;
private _pat = toLower _pattern;
if !("*" in _pat) exitWith {[_low == _pat, []]};
// Split on "*" keeping empty pieces (splitString drops them).
private _segs = [""];
{
    if (_x == "*") then {_segs pushBack ""} else {_segs set [count _segs - 1, (_segs select (count _segs - 1)) + _x]};
} forEach (_pat splitString "");
private _first = _segs select 0;
if ((_low select [0, count _first]) != _first) exitWith {[false, []]};
private _at = count _first;
private _caps = [];
private _ok = true;
for "_i" from 1 to (count _segs - 1) do {
    private _seg = _segs select _i;
    if (_i == count _segs - 1) then {
        // The last piece ends the name.
        private _end = count _low - count _seg;
        if (_end < _at || {(_low select [_end]) != _seg}) exitWith {_ok = false};
        _caps pushBack (_name select [_at, _end - _at]);
        _at = count _low;
    } else {
        private _found = if (_seg == "") then {0} else {(_low select [_at]) find _seg};
        if (_found < 0) exitWith {_ok = false};
        _caps pushBack (_name select [_at, _found]);
        _at = _at + _found + count _seg;
    };
    if (!_ok) exitWith {};
};
[_ok, [[], _caps] select _ok]
