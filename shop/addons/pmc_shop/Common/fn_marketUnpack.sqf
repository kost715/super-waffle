// [packed market (PMCS_fnc_marketPack)] -> the market, or nil when the data is not a
// valid market. Every entry is checked, so a damaged profile is refused as a whole.
params [["_packed", [], [[]]]];
private _pct = {_this isEqualType 0 && {_this >= 0} && {_this <= 90}};
private _count = {_this isEqualType 0 && {_this >= -1} && {_this <= 1e6} && {_this == floor _this}};
private _price = {_this isEqualType 0 && {_this >= -1} && {_this <= 1e7} && {_this == floor _this}};
if !(_packed isEqualTypeArray [0, [], [], [], 0, 0, []] && {(_packed select 0) == 1} && {(_packed select 4) call _pct} && {(_packed select 5) call _pct}) exitWith {nil};
private _ok = true;
private _items = createHashMap;
{
    if (_x isEqualTypeArray ["", []] && {(_x select 1) isEqualTypeArray [false, 0, 0, 0, 0]} && {((_x select 1) select 1) call _price}
        && {((_x select 1) select 2) call _pct} && {((_x select 1) select 3) call _count} && {((_x select 1) select 4) call _count}) then {
        _items set [_x select 0, +(_x select 1)];
    } else {_ok = false};
} forEach (_packed select 1);
private _custom = createHashMap;
{
    if (_x isEqualTypeArray ["", []] && {(_x select 1) isEqualTypeArray ["", "", "", ""]}) then {_custom set [_x select 0, +(_x select 1)]} else {_ok = false};
} forEach (_packed select 2);
private _cats = createHashMap;
{
    if (_x isEqualTypeArray ["", 0] && {(_x select 1) call _pct}) then {_cats set [_x select 0, _x select 1]} else {_ok = false};
} forEach (_packed select 3);
if ((_packed select 6) findIf {!(_x isEqualTypeArray ["", "", ""])} >= 0) then {_ok = false};
if (!_ok) exitWith {nil};
createHashMapFromArray [["items", _items], ["custom", _custom], ["cats", _cats], ["global", _packed select 4], ["box", _packed select 5],
    ["log", +(_packed select 6)]]
