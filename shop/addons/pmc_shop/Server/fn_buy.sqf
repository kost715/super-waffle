// [unit, laptop, "personal" | "group", cart lines] -> nothing. Client -> server: buys
// the cart. Everything is decided here: the prices (PMCS_fnc_quote, never the client's),
// the stock, the account (the group's only for its treasurers, as in PMC Bank), the
// balance and the delivery box. Then the account is charged (PMC Bank journal: "shop"),
// limited items lose what was sold and the goods go into the box. A variant with several
// classes (an MMM pattern) gives each box, or each single piece, one of them at random.
if (!isServer) exitWith {};
call PMCS_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_terminal", objNull, [objNull]], ["_account", "", [""]], ["_lines", [], [[]]]];
private _owner = [_unit] call PMCS_fnc_caller;
if (_owner < 0) exitWith {};
private _deny = {[_this, []] remoteExecCall ["PMCS_fnc_notify", _owner]};
if !([_unit, _terminal, "shop"] call PMCS_fnc_terminalNear) exitWith {"STR_PMCS_ERR_FAR" call _deny};
([_lines, PMCS_market] call PMCS_fnc_quote) params ["_total", "_units", "_error"];
if (_error != "") exitWith {
    _error call _deny;
    [_owner, _unit, "shop"] call PMCS_fnc_push;
};
if (_total <= 0) exitWith {"STR_PMCS_ERR_CART" call _deny};
call PMCB_fnc_serverLoad;
private _uid = [_unit] call PMCB_fnc_ensure;
private _key = switch (_account) do {case "personal": {_uid}; case "group": {"group"}; default {""}};
if (_key == "") exitWith {};
if (_key == "group" && {!(_uid in PMCB_treasurers)}) exitWith {"STR_PMCS_ERR_NOT_TREASURER" call _deny};
private _balance = if (_key == "group") then {PMCB_group} else {(PMCB_accounts get _uid) select 0};
if (_total > _balance) exitWith {"STR_PMCS_ERR_FUNDS" call _deny};
private _point = _terminal getVariable ["PMCS_point", ""];
private _boxes = (PMCS_points getOrDefault [_point, []]) select {!isNull _x && {alive _x}};
if (_boxes isEqualTo []) exitWith {["STR_PMCS_ERR_NO_BOX", [_point]] remoteExecCall ["PMCS_fnc_notify", _owner]};
private _box = _boxes select 0;
[_key, -_total, "shop", _uid, name _unit] call PMCB_fnc_apply;
private _items = PMCS_market get "items";
private _stock = false;
{
    private _over = _items getOrDefault [_x, []];
    if (_over isNotEqualTo [] && {(_over select 3) >= 0}) then {
        _over set [4, (_over select 4) - _y];
        _stock = true;
    };
} forEach _units;
private _bought = [];
{
    _x params ["_itemKey", "_variant", "_qty", "_asBox"];
    private _info = [_itemKey, PMCS_market] call PMCS_fnc_itemInfo;
    private _classes = ((_info select 7) select ((_info select 7) findIf {(_x select 0) == _variant})) select 3;
    private _per = [1, ([_itemKey, PMCS_market, _variant] call PMCS_fnc_price) select 5] select _asBox;
    private _given = createHashMap;
    for "_i" from 1 to _qty do {
        private _class = selectRandom _classes;
        _given set [_class, (_given getOrDefault [_class, 0]) + _per];
    };
    {[_box, _info select 0, _x, _y] call PMCS_fnc_deliver} forEach _given;
    _bought pushBack format ["%1 × %2", [_itemKey, PMCS_market, _variant] call PMCS_fnc_itemName, _qty * _per];
} forEach _lines;
[name _unit, format [localize "STR_PMCS_LOG_BUY", [_total] call PMCS_fnc_money, _bought joinString ", ", _point]] call PMCS_fnc_log;
["STR_PMCS_DONE_BUY", [[_total] call PMCS_fnc_money, _point]] remoteExecCall ["PMCS_fnc_notify", _owner];
[_owner, _unit, "shop", "bought"] call PMCS_fnc_push;
// The others see what is left.
if (_stock) then {call PMCS_fnc_broadcast};
