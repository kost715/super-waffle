// [item key, market, variant id ("": the first)] -> [state, price of one piece, box price,
// discount %, left, box units].
//   state "ok" | "hidden" | "noprice" | "soldout" | "none" (no such item)
// Goods are bought mainly by the box. The base price (the market's own, set by a Zeus, or
// the catalog's) is one piece in a box; a variant may cost more (a magazine row's ammo
// type: base x the factor of its column in the table). A box costs units x that, with no
// discount of its own (units by the category, see below). One piece alone costs its price
// with a markup (CBA: weapons, vests and added items +60%, magazines +30%). One discount applies to both, the largest of the item's,
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
// Pieces in a box: magazines by the CBA setting; weapons and vests by their category (the
// table's: assault rifles 12, infantry rifles 8, ...), else by the CBA setting.
private _units = if (_mag) then {round (missionNamespace getVariable ["PMCS_magBoxUnits", 30])} else {
    private _own = ((call PMCS_fnc_catalog) get "boxUnits") getOrDefault [_category, 0];
    [round (missionNamespace getVariable ["PMCS_weaponBoxUnits", 4]), _own] select (_own > 0)
};
private _box = round (_each * _units * _keep);
// One piece alone: the price of one piece with a markup (CBA: weapons and vests +60%,
// magazines +30%).
private _markup = if (_mag) then {missionNamespace getVariable ["PMCS_magUnitMarkup", 30]} else {missionNamespace getVariable ["PMCS_weaponUnitMarkup", 60]};
private _unit = round (_each * (1 + _markup / 100) * _keep);
private _state = switch (true) do {
    case (_hidden): {"hidden"};
    case (_base <= 0): {"noprice"};
    case (_max >= 0 && {_left <= 0}): {"soldout"};
    default {"ok"};
};
[_state, _unit, _box, _off, _left, _units]
