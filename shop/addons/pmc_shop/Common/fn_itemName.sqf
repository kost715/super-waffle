// [item key, market] -> how the shop names the item: a weapon by its catalog name, a
// magazine as "30 патр. Полимер · обычные" (magazine and ammo type), an added item by
// the game's name.
params [["_key", "", [""]], ["_market", createHashMap]];
private _info = [_key, _market] call PMCS_fnc_itemInfo;
if (_info isEqualTo []) exitWith {_key};
if ((_info select 0) == "mag" && {(_info select 8) != ""}) exitWith {
    format ["%1 · %2", _info select 8, localize ("STR_PMCS_AMMO_" + (_info select 9))]
};
_info select 1
