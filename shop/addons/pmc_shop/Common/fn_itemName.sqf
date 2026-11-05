// [item key, market, variant id ("": none)] -> how the shop names the item: a weapon by
// its catalog name, a magazine row as "5.45x39 АК 30 патр. Бакелит", an added item by the
// game's name. With a variant of an item that has several: "name (variant)".
params [["_key", "", [""]], ["_market", createHashMap], ["_variant", "", [""]]];
private _info = [_key, _market] call PMCS_fnc_itemInfo;
if (_info isEqualTo []) exitWith {_key};
private _variants = _info select 7;
private _at = _variants findIf {(_x select 0) == _variant};
if (_at < 0 || {count _variants < 2}) exitWith {_info select 1};
format ["%1 (%2)", _info select 1, (_variants select _at) select 1]
