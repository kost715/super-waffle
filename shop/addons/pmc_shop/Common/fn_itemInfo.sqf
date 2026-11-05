// [item key, market] -> the item as the catalog describes it (PMCS_fnc_catalog), or as a
// Zeus added it to this mission's market ("custom": category "custom", no base price),
// or [] when there is no such item.
params [["_key", "", [""]], ["_market", createHashMap]];
private _item = ((call PMCS_fnc_catalog) get "items") getOrDefault [_key, []];
if (_item isNotEqualTo []) exitWith {_item};
private _custom = (_market getOrDefault ["custom", createHashMap]) getOrDefault [_key, []];
if (_custom isEqualTo []) exitWith {[]};
_custom params ["_kind", "_class", "_name", "_picture"];
[_kind, _name, "custom", "", "", 0, 0, [[_class, _name, _picture, [_class], 1]], "", ""]
