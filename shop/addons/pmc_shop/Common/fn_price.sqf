// [item key, market] -> [state, price of one piece, box price, discount %, left, box units].
//   state "ok" | "hidden" | "noprice" | "soldout" | "none" (no such item)
// Goods are bought mainly by the box: the base price (the market's own, set by a Zeus, or
// the catalog's) is one piece in a box, so a box costs units x base, with no discount of
// its own. One piece alone costs more: a weapon (and an added item or backpack) a share of
// the box (CBA, 40% of a box of 4), a magazine its base with a markup (CBA, +30%, box of
// 30). One discount applies to both, the largest of the item's, its category's (the
// table's weapon category, "ammo", "custom") and the whole market's. left: -1 when the
// quantity is not limited.
params [["_key", "", [""]], ["_market", createHashMap]];
private _info = [_key, _market] call PMCS_fnc_itemInfo;
if (_info isEqualTo []) exitWith {["none", 0, 0, 0, -1, 0]};
_info params ["_kind", "", "_category", "", "", "_base"];
((_market getOrDefault ["items", createHashMap]) getOrDefault [_key, [false, -1, 0, -1, -1]]) params ["_hidden", "_price", "_discount", "_max", "_left"];
if (_price >= 0) then {_base = _price};
private _left = [-1, _left] select (_max >= 0);
private _off = (_discount max ((_market getOrDefault ["cats", createHashMap]) getOrDefault [_category, 0])) max (_market getOrDefault ["global", 0]);
private _keep = 1 - _off / 100;
private _mag = _kind == "mag";
private _units = round (missionNamespace getVariable [["PMCS_weaponBoxUnits", "PMCS_magBoxUnits"] select _mag, [4, 30] select _mag]);
private _box = round (_base * _units * _keep);
private _unit = if (_mag) then {
    round (_base * (1 + (missionNamespace getVariable ["PMCS_magUnitMarkup", 30]) / 100) * _keep)
} else {
    round (_base * _units * (missionNamespace getVariable ["PMCS_weaponUnitShare", 40]) / 100 * _keep)
};
private _state = switch (true) do {
    case (_hidden): {"hidden"};
    case (_base <= 0): {"noprice"};
    case (_max >= 0 && {_left <= 0}): {"soldout"};
    default {"ok"};
};
[_state, _unit, _box, _off, _left, _units]
