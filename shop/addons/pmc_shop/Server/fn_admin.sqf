// [unit, laptop, action, arguments] -> nothing. Client -> server from the management
// laptop. Only a Zeus by that laptop; every value is checked here. Actions:
//   "item"     [key, hidden, price (-1 catalog), discount %, quantity (-1 unlimited)]
//              setting a quantity restocks to it; an item set back to the catalog's
//              values loses its record
//   "category" [category, discount %]  the table's weapon category, "ammo" or "custom"
//   "global"   [discount %]  the whole market
//   "add"      [class, price, quantity]  a class of the game not in the catalog
//   "remove"   [key]  an added item            "reset" []  back to the catalog
// Each change goes to the journal, is saved and is sent to every open laptop.
if (!isServer) exitWith {};
call PMCS_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_terminal", objNull, [objNull]], ["_action", "", [""]], ["_args", [], [[]]]];
private _owner = [_unit] call PMCS_fnc_caller;
if (_owner < 0) exitWith {};
private _deny = {[_this, []] remoteExecCall ["PMCS_fnc_notify", _owner]};
if !([_unit, _terminal, "admin"] call PMCS_fnc_terminalNear) exitWith {"STR_PMCS_ERR_FAR" call _deny};
if !([_unit] call PMCS_fnc_isZeus) exitWith {"STR_PMCS_ERR_ZEUS" call _deny};
private _pct = {_this isEqualType 0 && {_this >= 0} && {_this <= 90} && {_this == floor _this}};
private _count = {_this isEqualType 0 && {_this >= -1} && {_this <= 1e6} && {_this == floor _this}};
private _price = {_this isEqualType 0 && {_this >= -1} && {_this <= 1e7} && {_this == floor _this}};
private _who = name _unit;
private _text = "";
switch (_action) do {
    case "item": {
        if !(_args isEqualTypeArray ["", false, 0, 0, 0] && {(_args select 2) call _price} && {(_args select 3) call _pct} && {(_args select 4) call _count}) exitWith {};
        _args params ["_key", "_hidden", "_newPrice", "_discount", "_max"];
        private _info = [_key, PMCS_market] call PMCS_fnc_itemInfo;
        if (_info isEqualTo []) exitWith {};
        private _items = PMCS_market get "items";
        private _old = _items getOrDefault [_key, [false, -1, 0, -1, -1]];
        // The stock is refilled only when the quantity itself changes.
        private _left = [_max, _old select 4] select (_max == (_old select 3));
        private _new = [_hidden, _newPrice, _discount, _max, [-1, _left] select (_max >= 0)];
        if (_new isEqualTo [false, -1, 0, -1, -1] && {(_info select 2) != "custom"}) then {_items deleteAt _key} else {_items set [_key, _new]};
        _text = format [localize "STR_PMCS_LOG_ITEM", _info select 1, [localize "STR_PMCS_UI_ON_SALE", localize "STR_PMCS_UI_HIDDEN"] select _hidden,
            [[_newPrice] call PMCS_fnc_money, localize "STR_PMCS_UI_CATALOG_PRICE"] select (_newPrice < 0), _discount,
            [str _max, localize "STR_PMCS_UI_UNLIMITED"] select (_max < 0)];
    };
    case "category": {
        if !(_args isEqualTypeArray ["", 0] && {(_args select 1) call _pct}) exitWith {};
        _args params ["_cat", "_discount"];
        if ((((call PMCS_fnc_catalog) get "categories") findIf {(_x select 0) == _cat}) < 0 && {!(_cat in ["ammo", "custom"])}) exitWith {};
        if (_discount == 0) then {(PMCS_market get "cats") deleteAt _cat} else {(PMCS_market get "cats") set [_cat, _discount]};
        _text = format [localize "STR_PMCS_LOG_CATEGORY", [_cat] call PMCS_fnc_categoryName, _discount];
    };
    case "global": {
        if !(_args isEqualTypeArray [0] && {(_args select 0) call _pct}) exitWith {};
        PMCS_market set ["global", _args select 0];
        _text = format [localize "STR_PMCS_LOG_GLOBAL", _args select 0];
    };
    case "add": {
        if !(_args isEqualTypeArray ["", 0, 0] && {(_args select 1) call _price} && {(_args select 1) > 0} && {(_args select 2) call _count}) exitWith {};
        _args params ["_class", "_newPrice", "_max"];
        private _kind = switch (true) do {
            case (isClass (configFile >> "CfgMagazines" >> _class)): {"mag"};
            case (isClass (configFile >> "CfgWeapons" >> _class)): {["item", "weapon"] select (getNumber (configFile >> "CfgWeapons" >> _class >> "type") in [1, 2, 4])};
            case (isClass (configFile >> "CfgVehicles" >> _class) && {getNumber (configFile >> "CfgVehicles" >> _class >> "isbackpack") == 1}): {"backpack"};
            default {""};
        };
        if (_kind == "") exitWith {"STR_PMCS_ERR_CLASS" call _deny};
        private _cfg = configFile >> (switch (_kind) do {case "mag": {"CfgMagazines"}; case "backpack": {"CfgVehicles"}; default {"CfgWeapons"}}) >> _class;
        _class = configName _cfg;
        private _key = "x_" + _class;
        private _catalog = (call PMCS_fnc_catalog) get "items";
        if (_class in _catalog || {_key in (PMCS_market get "custom")} || {(values _catalog) findIf {((_x select 7) findIf {(_x select 0) == _class}) >= 0} >= 0}) exitWith {
            "STR_PMCS_ERR_IN_CATALOG" call _deny;
        };
        (PMCS_market get "custom") set [_key, [_kind, _class, getText (_cfg >> "displayName"), getText (_cfg >> "picture")]];
        (PMCS_market get "items") set [_key, [false, _newPrice, 0, _max, _max]];
        _text = format [localize "STR_PMCS_LOG_ADD", getText (_cfg >> "displayName"), _class, [_newPrice] call PMCS_fnc_money,
            [str _max, localize "STR_PMCS_UI_UNLIMITED"] select (_max < 0)];
    };
    case "remove": {
        if !(_args isEqualTypeArray [""]) exitWith {};
        private _custom = (PMCS_market get "custom") getOrDefault [_args select 0, []];
        if (_custom isEqualTo []) exitWith {};
        (PMCS_market get "custom") deleteAt (_args select 0);
        (PMCS_market get "items") deleteAt (_args select 0);
        _text = format [localize "STR_PMCS_LOG_REMOVE", _custom select 2];
    };
    case "reset": {
        private _log = PMCS_market get "log";
        PMCS_market = call PMCS_fnc_marketNew;
        PMCS_market set ["log", _log];
        _text = localize "STR_PMCS_LOG_RESET";
    };
};
if (_text == "") exitWith {};
[_who, _text] call PMCS_fnc_log;
call PMCS_fnc_broadcast;
