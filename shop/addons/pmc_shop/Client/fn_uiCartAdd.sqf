// [item key, class, quantity, as boxes] -> nothing. Client. Puts goods in the cart (a line
// for the same item, variant and packing grows) and tells the player.
params ["_key", "_class", "_qty", "_asBox"];
private _cart = PMCS_ui get "cart";
private _at = _cart findIf {(_x select 0) == _key && {(_x select 1) == _class} && {(_x select 3) isEqualTo _asBox}};
if (_at < 0 && {count _cart >= 50}) exitWith {["toast", [localize "STR_PMCS_ERR_CART"]] call PMCS_fnc_ui};
if (_at >= 0) then {
    private _line = _cart select _at;
    _line set [2, ((_line select 2) + _qty) min 999];
} else {
    _cart pushBack [_key, _class, _qty, _asBox];
};
["cart"] call PMCS_fnc_uiShop;
if (PMCS_ui get "cartOpen") then {["overlay"] call PMCS_fnc_uiShop};
["toast", [format [localize "STR_PMCS_ADDED", ([_key, PMCS_ui get "market"] call PMCS_fnc_itemName)]]] call PMCS_fnc_ui;
