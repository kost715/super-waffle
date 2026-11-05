// [item key, market, variant id ("": the first)] -> [state, price of one piece, box price,
// discount %, left, box units].
//   state "ok" | "hidden" | "noprice" | "soldout" | "none" (no such item)
// Goods are bought mainly by the box. The base price (the market's own, set by a Zeus, or
// the catalog's) is one piece in a box; a variant may cost more (a magazine row's ammo
// type: base x the factor of its column in the table). A box costs units x that, with no
// discount of its own. One piece alone costs more: a weapon (and an added item or
// backpack) a share of the box (CBA, 40% of a box of 4), a magazine its price with a
// markup (CBA, +30%, box of 30). One discount applies to both, the largest of the item's,
// its category's (the table's weapon category, "ammo", "custom") and the whole market's.
// left: -1 when the quantity is not limited (a limit counts pieces of every variant).
params [["_key", "", [""]], ["_market", createHashMap], ["_variant", "", [""]]];
private _info = [_key, _market] call PMCS_fnc_itemInfo;
if (_info isEqualTo []) exitWith {["none", 0, 0, 0, -1, 0]};
_info params ["_kind", "", "_category", "", "", "_base", "", "_variants"];
((_market getOrDefault ["items", createHashMap]) getOrDefault [_key, [false, -1, 0, -1, -1]]) params ["_hidden", "_price", "_discount", "_max", "_left"];
if (_price >= 0) then {_base = _price};
private _at = (_variants findIf {(_x select 0) == _variant}) max 0;
private _each = _base * ((_variants select _at) param [4, 1]);
private _left = [-1, _left] select (_max >= 0);
private _off = (_discount max ((_market getOrDefault ["cats", createHashMap]) getOrDefault [_category, 0])) max (_market getOrDefault ["global", 0]);
private _keep = 1 - _off / 100;
private _mag = _kind == "mag";
private _units = round (missionNamespace getVariable [["PMCS_weaponBoxUnits", "PMCS_magBoxUnits"] select _mag, [4, 30] select _mag]);
private _box = round (_each * _units * _keep);
private _unit = if (_mag) then {
    round (_each * (1 + (missionNamespace getVariable ["PMCS_magUnitMarkup", 30]) / 100) * _keep)
} else {
    round (_each * _units * (missionNamespace getVariable ["PMCS_weaponUnitShare", 40]) / 100 * _keep)
};
private _state = switch (true) do {
    case (_hidden): {"hidden"};
    case (_base <= 0): {"noprice"};
    case (_max >= 0 && {_left <= 0}): {"soldout"};
    default {"ok"};
};
[_state, _unit, _box, _off, _left, _units]
