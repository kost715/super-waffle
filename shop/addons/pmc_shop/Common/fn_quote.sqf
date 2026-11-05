// [cart lines, market] -> [total, units per item (key -> units), error string key ("" ok)].
// A line: [item key, variant id, quantity, as boxes]. The variant must be one of the
// item's (it sets the price: a magazine row's ammo type); quantities are whole numbers 1-999; a box line needs a box size. Limited
// items must have enough left for all lines together. The server decides with this; the
// client shows the same total.
params [["_lines", [], [[]]], ["_market", createHashMap]];
private _total = 0;
private _units = createHashMap;
private _error = "";
if (_lines isEqualTo [] || {count _lines > 50}) exitWith {[0, _units, "STR_PMCS_ERR_CART"]};
{
    if !(_x isEqualTypeArray ["", "", 0, false]) exitWith {_error = "STR_PMCS_ERR_CART"};
    _x params ["_key", "_variant", "_qty", "_asBox"];
    if (_qty < 1 || {_qty > 999} || {_qty != floor _qty}) exitWith {_error = "STR_PMCS_ERR_CART"};
    private _info = [_key, _market] call PMCS_fnc_itemInfo;
    if (_info isEqualTo [] || {(_info select 7) findIf {(_x select 0) == _variant} < 0}) exitWith {_error = "STR_PMCS_ERR_CART"};
    ([_key, _market, _variant] call PMCS_fnc_price) params ["_state", "_unit", "_box", "", "_left", "_boxUnits"];
    if (_state != "ok") exitWith {_error = "STR_PMCS_ERR_UNAVAILABLE"};
    if (_asBox && {_boxUnits <= 0}) exitWith {_error = "STR_PMCS_ERR_CART"};
    private _count = [_qty, _qty * _boxUnits] select _asBox;
    _units set [_key, (_units getOrDefault [_key, 0]) + _count];
    if (_left >= 0 && {(_units get _key) > _left}) exitWith {_error = "STR_PMCS_ERR_STOCK"};
    _total = _total + ([_qty * _unit, _qty * _box] select _asBox);
} forEach _lines;
[_total, _units, _error]
