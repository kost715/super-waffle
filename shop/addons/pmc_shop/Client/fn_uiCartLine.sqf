// [cart line] -> [name, quantity text, sum text] for the cart. Client. The variant is
// named when the item has several; a box line shows boxes and the units in them.
params ["_line"];
_line params ["_key", "_class", "_qty", "_asBox"];
private _market = PMCS_ui get "market";
private _info = [_key, _market] call PMCS_fnc_itemInfo;
if (_info isEqualTo []) exitWith {[_key, str _qty, "-"]};
private _name = [_key, _market] call PMCS_fnc_itemName;
private _variants = _info select 7;
if (count _variants > 1) then {
    private _at = _variants findIf {(_x select 0) == _class};
    if (_at >= 0) then {_name = format ["%1 (%2)", _name, (_variants select _at) select 1]};
};
([_key, _market] call PMCS_fnc_price) params ["_state", "_unit", "_box", "", "", "_boxUnits"];
private _qtyText = if (_asBox) then {format [localize "STR_PMCS_QTY_BOX", _qty, _qty * _boxUnits]} else {format [localize "STR_PMCS_QTY_UNITS", _qty]};
[_name, _qtyText, if (_state == "ok") then {[[_qty * _unit, _qty * _box] select _asBox] call PMCS_fnc_money} else {localize "STR_PMCS_UNAVAILABLE"}]
