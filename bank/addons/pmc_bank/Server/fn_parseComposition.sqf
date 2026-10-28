// [[[class, count], ...]] -> [[[class, count], ...], total]. Server. Accepts only
// configured banknotes and whole counts 1..10000; anything else rejects it all.
params [["_composition", [], [[]]]];
private _notes = call PMCB_fnc_notes;
private _rows = [];
private _total = 0;
private _valid = _composition isNotEqualTo [];
{
    if !(_x isEqualTypeArray ["", 0]) exitWith {_valid = false};
    _x params ["_class", "_count"];
    private _lower = toLowerANSI _class;
    private _note = _notes findIf {toLowerANSI (_x select 0) == _lower};
    if (_note < 0 || {_count < 1} || {_count > 10000} || {_count != floor _count}) exitWith {_valid = false};
    _note = _notes select _note;
    private _at = _rows findIf {(_x select 0) == (_note select 0)};
    if (_at < 0) then {_rows pushBack [_note select 0, _count]} else {(_rows select _at) set [1, ((_rows select _at) select 1) + _count]};
    _total = _total + _count * (_note select 1);
} forEach _composition;
if (!_valid) exitWith {[[], 0]};
[_rows, _total]
