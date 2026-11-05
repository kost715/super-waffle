// [item key, market] -> [state, unit price, box price, discount %, left, box units].
//   state "ok" | "hidden" | "noprice" | "soldout" | "none" (no such item)
// The price is the market's own (set by a Zeus) or the catalog's. One discount applies,
// the largest of the item's, its category's and the whole market's; a box takes the box
// discount instead when that is larger. left: -1 when the quantity is not limited.
params [["_key", "", [""]], ["_market", createHashMap]];
private _info = [_key, _market] call PMCS_fnc_itemInfo;
if (_info isEqualTo []) exitWith {["none", 0, 0, 0, -1, 0]};
_info params ["", "", "", "", "_type", "_base", "_boxUnits"];
((_market getOrDefault ["items", createHashMap]) getOrDefault [_key, [false, -1, 0, -1, -1]]) params ["_hidden", "_price", "_discount", "_max", "_left"];
if (_price >= 0) then {_base = _price};
private _left = [-1, _left] select (_max >= 0);
private _off = (_discount max ((_market getOrDefault ["cats", createHashMap]) getOrDefault [_type, 0])) max (_market getOrDefault ["global", 0]);
private _unit = round (_base * (1 - _off / 100));
private _box = 0;
if (_boxUnits > 0) then {_box = round (_base * _boxUnits * (1 - (_off max (_market getOrDefault ["box", 0])) / 100))};
private _state = switch (true) do {
    case (_hidden): {"hidden"};
    case (_base <= 0): {"noprice"};
    case (_max >= 0 && {_left <= 0}): {"soldout"};
    default {"ok"};
};
[_state, _unit, _box, _off, _left, _boxUnits]
