// [amount, notes] -> [[class, count], ...] paying exactly this amount with the
// fewest banknotes found, largest first; [] when the notes cannot make it.
// The search tries the greedy choice first and backs off a little per value,
// so it also handles sets like 50/20 that greedy alone gets wrong.
params [["_amount", 0, [0]], ["_notes", [], [[]]]];
if (_amount <= 0 || {_amount != floor _amount} || {_notes isEqualTo []}) exitWith {[]};
private _counts = _notes apply {0};
private _budget = 5000;
private _search = {
    params ["_rest", "_index"];
    if (_rest == 0) exitWith {true};
    if (_index >= count _notes || {_budget <= 0}) exitWith {false};
    _budget = _budget - 1;
    private _value = (_notes select _index) select 1;
    private _most = floor (_rest / _value);
    private _found = false;
    for "_n" from _most to (0 max (_most - 20)) step -1 do {
        _counts set [_index, _n];
        if ([_rest - _n * _value, _index + 1] call _search) exitWith {_found = true};
    };
    if (!_found) then {_counts set [_index, 0]};
    _found
};
if !([_amount, 0] call _search) exitWith {[]};
private _out = [];
{
    if ((_counts select _forEachIndex) > 0) then {_out pushBack [_x select 0, _counts select _forEachIndex]};
} forEach _notes;
_out
