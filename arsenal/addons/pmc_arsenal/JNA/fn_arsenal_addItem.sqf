#include "defineCommon.inc"
/*
    Author: Jeroen Notenbomer; preview-only version: LifeSim PMC project
    Called by the arsenal interface when an item goes back to the arsenal.
    Accepts [index, item], [index, item, amount] or a 27-tab list.
    Stock is not changed here: the server shows the change to everyone browsing
    the storage (this client included) and settles stock when the session closes.
*/
private _array = EMPTY_ARRAY;
if (typeName (_this select 0) isEqualTo "SCALAR") then {
	params ["_index", "_item", ["_amount", 1]];
	if (_index < 0) exitWith {ERROR_JN_2("Failed to addItem: ", _this)};
	_array set [_index, [[_item, _amount]]];
} else {
	_array = _this;
};
private _rows = [];
{
	private _index = [_forEachIndex, IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL] select (_forEachIndex == IDC_RSCDISPLAYARSENAL_TAB_CARGOMAG);
	{
		_x params [["_item", "", [""]], ["_amount", 0, [0]]];
		if (_item != "" && {_amount > 0}) then {_rows pushBack [_index, _item, _amount]};
	} forEach _x;
} forEach _array;
if (_rows isNotEqualTo []) then {[_rows, true] remoteExecCall ["PMCA_fnc_preview", 2]};
