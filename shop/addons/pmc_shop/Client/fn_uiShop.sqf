// [event, arguments] -> nothing. Client. The ION market page in the laptop's browser:
// header (account, cart), weapons / ammunition, filters, the grid of goods ("Name xN" and
// the box price), the card of the chosen item (variant or ammo type, quantity, a box or
// single pieces, ammunition for a weapon), the cart bar and the cart window. Prices shown are the market's (PMCS_fnc_price); the server prices the
// purchase again.
params ["_event", ["_args", []]];
if (isNil "PMCS_ui") exitWith {};
private _make = {_this call PMCS_fnc_uiMake};
private _market = PMCS_ui getOrDefault ["market", createHashMap];
private _money = {[_this] call PMCS_fnc_money};
private _click = {
    params ["_ctrl", "_event", ["_args", []]];
    _ctrl setVariable ["PMCS_event", [_event, _args]];
    _ctrl ctrlAddEventHandler ["ButtonClick", {(_this select 0) getVariable "PMCS_event" call PMCS_fnc_uiShop}];
    _ctrl
};
switch (_event) do {
    case "build": {
        ["PMCS_Text", [0.6, 0.079, 0.22, 0.022], controlNull, "page", localize "STR_PMCS_PAY_WITH", 0.016, "navyText"] call _make;
        private _account = ["PMCS_Combo", [0.6, 0.103, 0.22, 0.032], controlNull, "page", "", 0.018] call _make;
        _account ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_row"];
            if (_row >= 0) then {PMCS_ui set ["account", _ctrl lbData _row]};
        }];
        PMCS_ui set ["accountCtrl", _account];
        PMCS_ui set ["cartButton", [["PMCS_Button", [0.835, 0.088, 0.15, 0.045], controlNull, "page", "", 0.02, "text", "orange"] call _make, "cartOpen"] call _click];
        // Weapons / equipment, weapons / ammunition, search, sort.
        ["PMCS_Text", [0, 0.145, 1, 0.055], controlNull, "page", "", 0.02, "", "white"] call _make;
        ["PMCS_Text", [0, 0.199, 1, 0.001], controlNull, "page", "", 0.02, "", "line"] call _make;
        // Sections: weapons (firearms / ammunition tabs) and equipment (vests).
        PMCS_ui set ["sectionWeapons", [["PMCS_Button", [0.015, 0.153, 0.085, 0.038], controlNull, "page", localize "STR_PMCS_SECTION_WEAPONS", 0.02, "white", "navy"] call _make,
            "tab", ["weapons"]] call _click];
        PMCS_ui set ["sectionGear", [["PMCS_Button", [0.105, 0.153, 0.085, 0.038], controlNull, "page", localize "STR_PMCS_SECTION_GEAR", 0.02, "white", "navy"] call _make,
            "tab", ["gear"]] call _click];
        PMCS_ui set ["tabWeapons", [["PMCS_Button", [0.21, 0.155, 0.07, 0.034], controlNull, "page", localize "STR_PMCS_TAB_WEAPONS", 0.019] call _make, "tab", ["weapons"]] call _click];
        PMCS_ui set ["tabAmmo", [["PMCS_Button", [0.281, 0.155, 0.08, 0.034], controlNull, "page", localize "STR_PMCS_TAB_AMMO", 0.019] call _make, "tab", ["ammo"]] call _click];
        ["PMCS_TextRight", [0.52, 0.156, 0.065, 0.032], controlNull, "page", localize "STR_PMCS_SEARCH", 0.019, "grey"] call _make;
        private _search = ["PMCS_Edit", [0.59, 0.156, 0.2, 0.032], controlNull, "page", "", 0.019] call _make;
        _search ctrlAddEventHandler ["KeyUp", {
            params ["_ctrl"];
            if (ctrlText _ctrl != (PMCS_ui get "search")) then {["search", [ctrlText _ctrl]] call PMCS_fnc_uiShop};
        }];
        private _sort = ["PMCS_Combo", [0.8, 0.156, 0.185, 0.032], controlNull, "page", "", 0.019] call _make;
        {_sort lbAdd localize _x} forEach ["STR_PMCS_SORT_PRICE_UP", "STR_PMCS_SORT_PRICE_DOWN", "STR_PMCS_SORT_NAME"];
        _sort lbSetCurSel (PMCS_ui get "sort");
        _sort ctrlAddEventHandler ["LBSelChanged", {
            params ["", "_row"];
            if (_row >= 0) then {["sort", [_row]] call PMCS_fnc_uiShop};
        }];
        // Body and cart bar.
        ["PMCS_Text", [0, 0.2, 0.16, 0.685], controlNull, "page", "", 0.02, "", "panel"] call _make;
        ["PMCS_Text", [0.16, 0.2, 0.56, 0.685], controlNull, "page", "", 0.02, "", "screen"] call _make;
        ["PMCS_Text", [0.72, 0.2, 0.28, 0.685], controlNull, "page", "", 0.02, "", "white"] call _make;
        ["PMCS_Text", [0.159, 0.2, 0.001, 0.685], controlNull, "page", "", 0.02, "", "line"] call _make;
        ["PMCS_Text", [0.72, 0.2, 0.001, 0.685], controlNull, "page", "", 0.02, "", "line"] call _make;
        PMCS_ui set ["filtersGroup", ["PMCS_Group", [0, 0.2, 0.159, 0.685], controlNull, "page"] call _make];
        PMCS_ui set ["gridGroup", ["PMCS_Group", [0.16, 0.2, 0.56, 0.685], controlNull, "page"] call _make];
        PMCS_ui set ["detailGroup", ["PMCS_Group", [0.721, 0.2, 0.279, 0.685], controlNull, "page"] call _make];
        ["PMCS_Text", [0, 0.885, 1, 0.065], controlNull, "page", "", 0.02, "", "navy"] call _make;
        ["PMCS_TextBold", [0.015, 0.9, 0.065, 0.035], controlNull, "page", localize "STR_PMCS_CART", 0.021, "white"] call _make;
        PMCS_ui set ["cartSummary", ["PMCS_Struct", [0.08, 0.894, 0.47, 0.05], controlNull, "page", "", 0.017] call _make];
        ["PMCS_Text", [0.555, 0.9, 0.2, 0.035], controlNull, "page", format [localize "STR_PMCS_DELIVERY_TO", (PMCS_ui get "terminal") getVariable ["PMCS_point", ""]], 0.017, "navyText"] call _make;
        PMCS_ui set ["cartTotal", ["PMCS_TextBoldRight", [0.75, 0.895, 0.12, 0.045], controlNull, "page", "", 0.024, "white"] call _make];
        PMCS_ui set ["checkout", [["PMCS_Button", [0.877, 0.893, 0.113, 0.048], controlNull, "page", localize "STR_PMCS_CHECKOUT", 0.02, "text", "orange"] call _make, "checkout"] call _click];
        (PMCS_ui get "address") ctrlSetText localize "STR_PMCS_ADDRESS_SHOP";
        ["refresh"] call PMCS_fnc_uiShop;
    };
    case "refresh": {
        if !("market" in PMCS_ui) exitWith {};
        // Account choice: the group's account only for its treasurers (PMC Bank rules).
        (PMCS_ui get "bank") params ["_personal", "_group", "_treasurer"];
        private _account = PMCS_ui get "accountCtrl";
        lbClear _account;
        _account lbSetData [_account lbAdd format [localize "STR_PMCS_ACCOUNT_PERSONAL", _personal call _money], "personal"];
        if (_treasurer) then {_account lbSetData [_account lbAdd format [localize "STR_PMCS_ACCOUNT_GROUP", _group call _money], "group"]};
        if (!_treasurer) then {PMCS_ui set ["account", "personal"]};
        _account lbSetCurSel ([0, 1] select ((PMCS_ui get "account") == "group"));
        private _ammo = (PMCS_ui get "tab") == "ammo";
        private _gearTab = (PMCS_ui get "tab") == "gear";
        (PMCS_ui get "tabWeapons") ctrlSetBackgroundColor ([[0.91, 0.925, 0.937, 1], [1, 1, 1, 1]] select _ammo);
        (PMCS_ui get "tabAmmo") ctrlSetBackgroundColor ([[1, 1, 1, 1], [0.91, 0.925, 0.937, 1]] select _ammo);
        {_x ctrlSetTextColor (["text"] call PMCS_fnc_uiColor)} forEach [PMCS_ui get "tabWeapons", PMCS_ui get "tabAmmo"];
        // The firearms / ammunition tabs belong to the weapons section.
        {_x ctrlShow !_gearTab} forEach [PMCS_ui get "tabWeapons", PMCS_ui get "tabAmmo"];
        (PMCS_ui get "sectionWeapons") ctrlSetBackgroundColor ([["navy"] call PMCS_fnc_uiColor, ["photo"] call PMCS_fnc_uiColor] select _gearTab);
        (PMCS_ui get "sectionWeapons") ctrlSetTextColor ([["white"] call PMCS_fnc_uiColor, ["text"] call PMCS_fnc_uiColor] select _gearTab);
        (PMCS_ui get "sectionGear") ctrlSetBackgroundColor ([["photo"] call PMCS_fnc_uiColor, ["navy"] call PMCS_fnc_uiColor] select _gearTab);
        (PMCS_ui get "sectionGear") ctrlSetTextColor ([["text"] call PMCS_fnc_uiColor, ["white"] call PMCS_fnc_uiColor] select _gearTab);
        ["filters"] call PMCS_fnc_uiShop;
        ["grid"] call PMCS_fnc_uiShop;
        ["detail"] call PMCS_fnc_uiShop;
        ["cart"] call PMCS_fnc_uiShop;
        if (PMCS_ui get "cartOpen") then {["overlay"] call PMCS_fnc_uiShop};
    };
    case "filters": {
        ["filters"] call PMCS_fnc_uiClear;
        private _group = PMCS_ui get "filtersGroup";
        ([] call PMCS_fnc_uiShopList) params ["", "_types", "_cals"];
        private _ammo = (PMCS_ui get "tab") == "ammo";
        // Select every row / clear the selection (both show everything).
        [["PMCS_Button", [0.008, 0.212, 0.069, 0.03], _group, "filters", localize "STR_PMCS_FILTER_ALL", 0.015, "text", "photo"] call _make, "filterAll"] call _click;
        [["PMCS_Button", [0.081, 0.212, 0.07, 0.03], _group, "filters", localize "STR_PMCS_FILTER_NONE", 0.015, "text", "photo"] call _make, "filterNone"] call _click;
        private _y = 0.255;
        private _section = {
            params ["_title", "_rows", "_kind"];
            if (_rows isEqualTo []) exitWith {};
            ["PMCS_TextBold", [0.012, _y, 0.14, 0.025], _group, "filters", _title, 0.016, "grey"] call _make;
            _y = _y + 0.03;
            // Each row is a button (a whole-row click selects it or not); the square is filled
            // when it is selected. Only selected rows stay; none selected: all stay.
            {
                _x params ["_key", "_label", "_n"];
                private _on = _key in (PMCS_ui get (["selTypes", "selCals"] select (_kind == "cal")));
                ["PMCS_Text", [0.012, _y + 0.004, 0.012, 0.018], _group, "filters", "", 0.02, "", "navy"] call _make;
                if (!_on) then {["PMCS_Text", [0.0135, _y + 0.0065, 0.009, 0.013], _group, "filters", "", 0.02, "", "white"] call _make};
                ["PMCS_Text", [0.03, _y, 0.085, 0.026], _group, "filters", _label, 0.017, ["grey", "text"] select _on] call _make;
                ["PMCS_TextRight", [0.11, _y, 0.037, 0.026], _group, "filters", str _n, 0.017, "grey"] call _make;
                private _row = [["PMCS_ButtonClear", [0.008, _y - 0.001, 0.143, 0.028], _group, "filters"] call _make, "filter", [_kind, _key, !_on]] call _click;
                _row ctrlSetTooltip _label;
                _y = _y + 0.03;
            } forEach _rows;
            _y = _y + 0.015;
        };
        if (!_ammo) then {
            private _typeRows = [];
            {
                _x params ["_key", "_label"];
                if (_key in _types) then {_typeRows pushBack [_key, _label, _types get _key]};
            } forEach (((call PMCS_fnc_catalog) get "categories") + [["custom", localize "STR_PMCS_CATEGORY_CUSTOM"]]);
            [localize "STR_PMCS_FILTER_CATEGORY", _typeRows, "type"] call _section;
        };
        private _calRows = (keys _cals) apply {[_x, _x, _cals get _x]};
        _calRows sort true;
        [localize "STR_PMCS_FILTER_CALIBRE", _calRows, "cal"] call _section;
    };
    case "grid": {
        ["grid"] call PMCS_fnc_uiClear;
        private _group = PMCS_ui get "gridGroup";
        ([] call PMCS_fnc_uiShopList) params ["_shown"];
        PMCS_ui set ["shown", _shown];
        if !((PMCS_ui get "sel") in _shown) then {PMCS_ui set ["sel", _shown param [0, ""]]};
        if (_shown isEqualTo []) exitWith {
            ["PMCS_TextCenter", [0.16, 0.4, 0.56, 0.05], _group, "grid", localize "STR_PMCS_NOTHING", 0.022, "grey"] call _make;
        };
        private _w = (0.56 - 0.012 * 4) / 3;
        private _h = 0.2;
        {
            private _key = _x;
            private _x0 = 0.172 + (_forEachIndex % 3) * (_w + 0.012);
            private _y0 = 0.212 + floor (_forEachIndex / 3) * (_h + 0.016);
            // "Name xN" (N pieces in a box), the box price (a magazine row: of its first type,
            // Ball), then category · calibre (a magazine row: the calibre and its types) and
            // the single price, what is left, the discount or "sold out".
            private _info = [_key, _market] call PMCS_fnc_itemInfo;
            ([_key, _market] call PMCS_fnc_price) params ["_state", "_unit", "_box", "_off", "_left", "_boxUnits"];
            private _mag = (_info select 0) == "mag";
            private _title = format [localize "STR_PMCS_CARD_TITLE", [_info select 1, _info select 8] select (_mag && {(_info select 8) != ""}), _boxUnits];
            private _sub = if (_mag) then {
                format ["%1 · %2", [_info select 3, "-"] select ((_info select 3) == ""), ((_info select 7) apply {_x select 1}) joinString ", "]
            } else {([[_info select 2] call PMCS_fnc_categoryName, _info select 3] select {_x != ""}) joinString " · "};
            private _note = if (_state == "soldout") then {[localize "STR_PMCS_SOLD_OUT", "red"]} else {
                [format [localize "STR_PMCS_UNIT_LINE", _unit call _money] + ([format [localize "STR_PMCS_LEFT_LINE", _left], ""] select (_left < 0))
                    + ([format [localize "STR_PMCS_DISCOUNT_SHORT", _off], ""] select (_off <= 0)), "grey"]
            };
            private _picture = ((_info select 7) select 0) select 2;
            if (_key == (PMCS_ui get "sel")) then {["PMCS_Text", [_x0 - 0.003, _y0 - 0.005, _w + 0.006, _h + 0.01], _group, "grid", "", 0.02, "", "orange"] call _make};
            ["PMCS_Text", [_x0, _y0, _w, _h], _group, "grid", "", 0.02, "", "white"] call _make;
            ["PMCS_Text", [_x0 + 0.006, _y0 + 0.01, _w - 0.012, 0.09], _group, "grid", "", 0.02, "", "photo"] call _make;
            ["PMCS_Picture", [_x0 + 0.012, _y0 + 0.014, _w - 0.024, 0.082], _group, "grid", [_picture, "\pmc_shop\data\noimage_ca.paa"] select (_picture == "")] call _make;
            private _dim = ["text", "grey"] select (_state == "soldout");
            ["PMCS_TextBold", [_x0 + 0.008, _y0 + 0.103, _w - 0.016, 0.03], _group, "grid", _title, 0.02, _dim] call _make;
            ["PMCS_TextBold", [_x0 + 0.008, _y0 + 0.131, _w - 0.016, 0.03], _group, "grid", _box call _money, 0.021, ["orangeDark", "grey"] select (_state == "soldout")] call _make;
            ["PMCS_Text", [_x0 + 0.008, _y0 + 0.157, _w - 0.016, 0.02], _group, "grid", _sub, 0.014, "grey"] call _make;
            ["PMCS_Text", [_x0 + 0.008, _y0 + 0.176, _w - 0.016, 0.02], _group, "grid", _note select 0, 0.014, _note select 1] call _make;
            [["PMCS_ButtonClear", [_x0, _y0, _w, _h], _group, "grid"] call _make, "select", [_key]] call _click;
        } forEach _shown;
    };
    case "detail": {
        ["detail"] call PMCS_fnc_uiClear;
        private _group = PMCS_ui get "detailGroup";
        private _key = PMCS_ui get "sel";
        private _x0 = 0.735;
        private _wd = 0.25;
        if (_key == "") exitWith {};
        // Prices, quantity and the two ways to buy: the main button adds boxes, the second
        // one single pieces. Shared by weapons and magazines.
        private _buyBlock = {
            params ["_itemKey", "_variant", "_y", "_qtyVar", "_qtyEvent", "_addEvent"];
            ([_itemKey, _market, _variant] call PMCS_fnc_price) params ["_state", "_unit", "_box", "_off", "_left", "_boxUnits"];
            ["PMCS_Struct", [_x0, _y, _wd, 0.045], _group, "detail", format ["<t font='RobotoCondensedBold'>%1</t> <t color='#4a5056' size='0.6'>%2</t>",
                _box call _money, format [localize "STR_PMCS_PER_BOX_OF", _boxUnits]], 0.03] call _make;
            private _lines = [format ["<t color='#4a5056'>%1</t>", format [localize "STR_PMCS_UNIT_PRICE", _unit call _money]]];
            if (_off > 0) then {_lines pushBack format ["<t color='#2f5f2a'>%1</t>", format [localize "STR_PMCS_DISCOUNT_LINE", _off]]};
            if (_left >= 0) then {_lines pushBack format ["<t color='#4a5056'>%1</t>", format [localize "STR_PMCS_LEFT_DETAIL", _left]]};
            if (_state == "soldout") then {_lines pushBack format ["<t color='#9e291f'>%1</t>", localize "STR_PMCS_SOLD_OUT"]};
            ["PMCS_Struct", [_x0, _y + 0.045, _wd, 0.025 * count _lines + 0.01], _group, "detail", _lines joinString "<br/>", 0.016] call _make;
            _y = _y + 0.055 + 0.025 * count _lines;
            ["PMCS_Text", [_x0, _y + 0.004, 0.1, 0.03], _group, "detail", localize "STR_PMCS_QTY", 0.017, "grey"] call _make;
            [["PMCS_Button", [_x0 + 0.165, _y, 0.022, 0.034], _group, "detail", "-", 0.024, "text", "photo"] call _make, _qtyEvent, [-1]] call _click;
            private _qty = ["PMCS_Edit", [_x0 + 0.188, _y, 0.038, 0.034], _group, "detail", str (PMCS_ui get _qtyVar), 0.02] call _make;
            _qty setVariable ["PMCS_set", [_qtyEvent + "Set"]];
            _qty ctrlAddEventHandler ["KillFocus", {[((_this select 0) getVariable "PMCS_set") select 0, [ctrlText (_this select 0)]] call PMCS_fnc_uiShop}];
            [["PMCS_Button", [_x0 + 0.227, _y, 0.022, 0.034], _group, "detail", "+", 0.024, "text", "photo"] call _make, _qtyEvent, [1]] call _click;
            _y = _y + 0.045;
            private _boxButton = [["PMCS_Button", [_x0, _y, _wd, 0.045], _group, "detail", format [localize "STR_PMCS_ADD_BOX", _boxUnits], 0.021, "white", "orangeDark"] call _make,
                _addEvent, ["box"]] call _click;
            private _unitButton = [["PMCS_Button", [_x0, _y + 0.05, _wd, 0.034], _group, "detail", format [localize "STR_PMCS_ADD_UNIT", _unit call _money], 0.017, "text", "photo"] call _make,
                _addEvent, ["unit"]] call _click;
            {_x ctrlEnable (_state == "ok")} forEach [_boxButton, _unitButton];
            _y + 0.1
        };
        // Choice chips in rows of two: [ids, labels, chosen id, event, y, tooltips] -> the y below.
        private _chips = {
            params ["_ids", "_labels", "_chosen", "_event", "_y", ["_tips", []]];
            {
                private _on = _x == _chosen;
                private _chip = ["PMCS_Button", [_x0 + (_forEachIndex % 2) * 0.126, _y + floor (_forEachIndex / 2) * 0.032, 0.122, 0.028], _group, "detail",
                    _labels select _forEachIndex, 0.015, ["text", "white"] select _on, ["photo", "navy"] select _on] call _make;
                if (_forEachIndex < count _tips) then {_chip ctrlSetTooltip (_tips select _forEachIndex)};
                [_chip, _event, [_x]] call _click;
            } forEach _ids;
            _y + ceil (count _ids / 2) * 0.032 + 0.008
        };
        // The ammo types of a magazine row: the price of the chosen one is shown below.
        private _typePicker = {
            params ["_row", "_y"];
            private _variants = ([_row, _market] call PMCS_fnc_itemInfo) select 7;
            if ((_variants findIf {(_x select 0) == (PMCS_ui get "ammoType")}) < 0) then {PMCS_ui set ["ammoType", (_variants select 0) select 0]};
            ["PMCS_TextBold", [_x0, _y, _wd, 0.026], _group, "detail", localize "STR_PMCS_STEP_TYPE", 0.016, "grey"] call _make;
            _y = [_variants apply {_x select 0}, _variants apply {_x select 1}, PMCS_ui get "ammoType", "ammoType", _y + 0.028,
                _variants apply {format ["%1 (%2)", getText (configFile >> "CfgMagazines" >> (_x select 0) >> "displayName"), _x select 0]}] call _chips;
            private _chosen = _variants select (_variants findIf {(_x select 0) == (PMCS_ui get "ammoType")});
            ["PMCS_Text", [_x0, _y - 0.004, _wd, 0.026], _group, "detail", format [localize "STR_PMCS_IN_GAME",
                getText (configFile >> "CfgMagazines" >> (_chosen select 0) >> "displayName")], 0.015, "grey"] call _make;
            _y + 0.026
        };
        private _info = [_key, _market] call PMCS_fnc_itemInfo;
        if (_info isEqualTo []) exitWith {};
        private _variants = _info select 7;
        if ((_info select 0) == "mag") exitWith {
            // A magazine row: what it fits, the ammo type, then the box / single pieces.
            if ((_variants findIf {(_x select 0) == (PMCS_ui get "ammoType")}) < 0) then {PMCS_ui set ["ammoType", (_variants select 0) select 0]};
            private _picture = (_variants select (_variants findIf {(_x select 0) == (PMCS_ui get "ammoType")})) select 2;
            ["PMCS_Text", [_x0, 0.215, _wd, 0.13], _group, "detail", "", 0.02, "", "photo"] call _make;
            ["PMCS_Picture", [_x0 + 0.01, 0.222, _wd - 0.02, 0.116], _group, "detail", [_picture, "\pmc_shop\data\noimage_ca.paa"] select (_picture == "")] call _make;
            ["PMCS_TextBold", [_x0, 0.352, _wd, 0.045], _group, "detail", [_info select 1, _info select 8] select ((_info select 8) != ""), 0.03] call _make;
            private _fits = ((call PMCS_fnc_catalog) get "order") select {
                private _weapon = ((call PMCS_fnc_catalog) get "items") get _x;
                (_weapon select 0) == "weapon" && {(_weapon select 3) == (_info select 3)} && {(([_x, _market] call PMCS_fnc_price) select 0) in ["ok", "soldout"]}
            };
            ["PMCS_Text", [_x0, 0.395, _wd, 0.028], _group, "detail", [_info select 3, localize "STR_PMCS_CATEGORY_CUSTOM"] select ((_info select 3) == ""), 0.016, "grey"] call _make;
            private _y = 0.425;
            if (_fits isNotEqualTo []) then {
                ["PMCS_Text", [_x0, _y, _wd, 0.045], _group, "detail", format [localize "STR_PMCS_FITS", (_fits apply {[_x, _market] call PMCS_fnc_itemName}) joinString ", "],
                    0.015, "grey"] call _make;
                _y = _y + 0.048;
            };
            _y = [_key, _y] call _typePicker;
            ["PMCS_Text", [_x0, _y, _wd, 0.001], _group, "detail", "", 0.02, "", "line"] call _make;
            [_key, PMCS_ui get "ammoType", _y + 0.01, "qty", "qty", "add"] call _buyBlock;
        };
        if ((_variants findIf {(_x select 0) == (PMCS_ui get "variant")}) < 0) then {PMCS_ui set ["variant", (_variants select 0) select 0]};
        private _variant = _variants select (_variants findIf {(_x select 0) == (PMCS_ui get "variant")});
        ["PMCS_Text", [_x0, 0.215, _wd, 0.13], _group, "detail", "", 0.02, "", "photo"] call _make;
        ["PMCS_Picture", [_x0 + 0.01, 0.222, _wd - 0.02, 0.116], _group, "detail", [_variant select 2, "\pmc_shop\data\noimage_ca.paa"] select ((_variant select 2) == "")] call _make;
        ["PMCS_TextBold", [_x0, 0.352, _wd, 0.045], _group, "detail", _info select 1, 0.032] call _make;
        ["PMCS_Text", [_x0, 0.395, _wd, 0.028], _group, "detail", ([[_info select 2] call PMCS_fnc_categoryName, _info select 3] select {_x != ""}) joinString " · ", 0.016, "grey"] call _make;
        // What the gunsmith ("Техник") can make of it.
        private _upgrades = count ((if ((_info select 0) == "gear") then {[_variant select 0] call PMCS_fnc_gearUpgradesFor} else {[_variant select 0] call PMCS_fnc_upgradesFor})
            select {!("rev:" in ((_x select 0) select 0))});
        if (_upgrades > 0) then {
            ["PMCS_Text", [_x0, 0.418, _wd, 0.022], _group, "detail", format [localize "STR_PMCS_DETAIL_UPGRADES", _upgrades], 0.014, "green"] call _make;
        };
        private _y = 0.445;
        if (count _variants > 1) then {
            // A table class is its own button; an MMM pattern is one "MMM" button: every box
            // gets one of its classes at random.
            ["PMCS_Text", [_x0, _y, _wd, 0.028], _group, "detail", localize "STR_PMCS_VARIANT", 0.017, "grey"] call _make;
            _y = [_variants apply {_x select 0}, _variants apply {_x select 1}, _variant select 0, "variant", _y + 0.03,
                _variants apply {[_x select 0, format [localize "STR_PMCS_RANDOM_TIP", (_x select 3) joinString ", "]] select (count (_x select 3) > 1)}] call _chips;
            if (count (_variant select 3) > 1) then {
                ["PMCS_Text", [_x0, _y - 0.004, _wd, 0.026], _group, "detail", format [localize "STR_PMCS_RANDOM_LINE", count (_variant select 3)], 0.015, "grey"] call _make;
                _y = _y + 0.026;
            };
        };
        ["PMCS_Text", [_x0, _y, _wd, 0.001], _group, "detail", "", 0.02, "", "line"] call _make;
        _y = [_key, _variant select 0, _y + 0.01, "qty", "qty", "add"] call _buyBlock;
        if ((_info select 3) == "") exitWith {};
        // Ammunition for this weapon: the magazine rows of its calibre, the type, buy.
        ["PMCS_Text", [_x0, _y - 0.008, _wd, 0.001], _group, "detail", "", 0.02, "", "line"] call _make;
        ["PMCS_TextBold", [_x0, _y, _wd, 0.028], _group, "detail", format [localize "STR_PMCS_AMMO_FOR", _info select 3], 0.017] call _make;
        _y = _y + 0.034;
        private _rows = [_info select 3] call PMCS_fnc_uiCalibreMags;
        if (_rows isEqualTo []) exitWith {
            private _known = ((call PMCS_fnc_catalog) get "calibres") getOrDefault [_info select 3, []];
            ["PMCS_Text", [_x0, _y, _wd, 0.028], _group, "detail", localize (["STR_PMCS_MAGS_NONE", "STR_PMCS_MAGS_NO_PRICE"] select (_known isNotEqualTo [])), 0.016, "grey"] call _make;
        };
        if !((PMCS_ui get "mag") in _rows) then {PMCS_ui set ["mag", _rows select 0]};
        ["PMCS_TextBold", [_x0, _y, _wd, 0.026], _group, "detail", localize "STR_PMCS_STEP_MAG", 0.016, "grey"] call _make;
        _y = [_rows, _rows apply {private _row = [_x, _market] call PMCS_fnc_itemInfo; [_row select 1, _row select 8] select ((_row select 8) != "")},
            PMCS_ui get "mag", "mag", _y + 0.028] call _chips;
        _y = [PMCS_ui get "mag", _y] call _typePicker;
        [PMCS_ui get "mag", PMCS_ui get "ammoType", _y + 0.004, "magQty", "magQty", "magAdd"] call _buyBlock;
    };
    case "cart": {
        private _cart = PMCS_ui get "cart";
        ([_cart, _market] call PMCS_fnc_quote) params ["_total", "", "_error"];
        private _count = 0;
        {_count = _count + 1} forEach _cart;
        (PMCS_ui get "cartButton") ctrlSetText format [localize "STR_PMCS_CART_BUTTON", _count];
        private _parts = [];
        {
            if (_forEachIndex < 3) then {
                ([_x] call PMCS_fnc_uiCartLine) params ["_name", "_qtyText", "_sum"];
                _parts pushBack format ["%1 %2 · %3", _name, _qtyText, _sum];
            };
        } forEach _cart;
        if (count _cart > 3) then {_parts pushBack format [localize "STR_PMCS_CART_MORE", count _cart - 3]};
        if (_cart isEqualTo []) then {_parts = [localize "STR_PMCS_CART_EMPTY"]};
        (PMCS_ui get "cartSummary") ctrlSetStructuredText parseText format ["<t size='%1' color='#c7d0d8'>%2</t>", 0.017 * ((PMCS_ui get "screen") select 3) / 0.03,
            _parts joinString "   ·   "];
        (PMCS_ui get "cartTotal") ctrlSetText ([_total call _money, "-"] select (_error != "" && {_cart isNotEqualTo []}));
        (PMCS_ui get "checkout") ctrlEnable (_cart isNotEqualTo [] && {_error == ""});
    };
    case "overlay": {
        ["overlay"] call PMCS_fnc_uiClear;
        if !(PMCS_ui get "cartOpen") exitWith {};
        private _cart = PMCS_ui get "cart";
        ["PMCS_Text", [0.24, 0.215, 0.52, 0.62], controlNull, "overlay", "", 0.02, "", [0, 0, 0, 0.25]] call _make;
        ["PMCS_Text", [0.245, 0.21, 0.51, 0.62], controlNull, "overlay", "", 0.02, "", "white"] call _make;
        ["PMCS_TextBold", [0.26, 0.22, 0.3, 0.04], controlNull, "overlay", localize "STR_PMCS_CART", 0.026] call _make;
        private _list = ["PMCS_List", [0.26, 0.27, 0.48, 0.42], controlNull, "overlay", "", 0.019] call _make;
        _list lnbSetColumnsPos [0, 0.58, 0.8];
        {
            ([_x] call PMCS_fnc_uiCartLine) params ["_name", "_qtyText", "_sum"];
            _list lnbAddRow [_name, _qtyText, _sum];
        } forEach _cart;
        if ((PMCS_ui get "cartRow") < count _cart) then {_list lnbSetCurSelRow (PMCS_ui get "cartRow")};
        _list ctrlAddEventHandler ["LBSelChanged", {PMCS_ui set ["cartRow", _this select 1]}];
        ([_cart, _market] call PMCS_fnc_quote) params ["_total", "", "_error"];
        ["PMCS_TextBoldRight", [0.5, 0.7, 0.24, 0.04], controlNull, "overlay", format [localize "STR_PMCS_TOTAL", _total call _money], 0.024] call _make;
        if (_error != "") then {["PMCS_Text", [0.26, 0.7, 0.24, 0.04], controlNull, "overlay", localize _error, 0.018, "red"] call _make};
        {
            _x params ["_label", "_cartEvent", "_cartArgs", "_left"];
            [["PMCS_Button", [_left, 0.765, 0.09, 0.045], controlNull, "overlay", _label, 0.019, "text", "photo"] call _make, _cartEvent, _cartArgs] call _click;
        } forEach [["-", "cartQty", [-1], 0.26], ["+", "cartQty", [1], 0.355], [localize "STR_PMCS_REMOVE", "cartRemove", [], 0.45],
            [localize "STR_PMCS_CLEAR", "cartClear", [], 0.545], [localize "STR_PMCS_CLOSE", "cartClose", [], 0.65]];
    };
    // User actions.
    case "tab": {
        PMCS_ui set ["tab", _args select 0];
        PMCS_ui set ["selTypes", []];
        PMCS_ui set ["selCals", []];
        PMCS_ui set ["sel", ""];
        PMCS_ui set ["ammoType", ""];
        PMCS_ui set ["mag", ""];
        ["refresh"] call PMCS_fnc_uiShop;
        (PMCS_ui get "address") ctrlSetText localize (switch (_args select 0) do {case "ammo": {"STR_PMCS_ADDRESS_AMMO"}; case "gear": {"STR_PMCS_ADDRESS_GEAR"}; default {"STR_PMCS_ADDRESS_SHOP"}});
    };
    // [kind ("type" | "cal"), key, selected]: select a filter row or not.
    case "filter": {
        _args params ["_kind", "_key", "_on"];
        private _sel = PMCS_ui get (["selTypes", "selCals"] select (_kind == "cal"));
        if (_on) then {_sel pushBackUnique _key} else {
            private _at = _sel find _key;
            if (_at >= 0) then {_sel deleteAt _at};
        };
        ["filters"] call PMCS_fnc_uiShop;
        ["grid"] call PMCS_fnc_uiShop;
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "filterAll": {
        PMCS_ui set ["selTypes", []];
        PMCS_ui set ["selCals", []];
        ([] call PMCS_fnc_uiShopList) params ["", "_types", "_cals"];
        PMCS_ui set ["selTypes", if ((PMCS_ui get "tab") == "ammo") then {[]} else {keys _types}];
        PMCS_ui set ["selCals", keys _cals];
        ["filters"] call PMCS_fnc_uiShop;
        ["grid"] call PMCS_fnc_uiShop;
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "filterNone": {
        PMCS_ui set ["selTypes", []];
        PMCS_ui set ["selCals", []];
        ["filters"] call PMCS_fnc_uiShop;
        ["grid"] call PMCS_fnc_uiShop;
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "search": {
        PMCS_ui set ["search", _args select 0];
        ["filters"] call PMCS_fnc_uiShop;
        ["grid"] call PMCS_fnc_uiShop;
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "sort": {
        PMCS_ui set ["sort", _args select 0];
        ["grid"] call PMCS_fnc_uiShop;
    };
    case "select": {
        PMCS_ui set ["sel", _args select 0];
        PMCS_ui set ["qty", 1];
        PMCS_ui set ["ammoType", ""];
        PMCS_ui set ["mag", ""];
        ["grid"] call PMCS_fnc_uiShop;
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "variant": {
        PMCS_ui set ["variant", _args select 0];
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "qty": {
        PMCS_ui set ["qty", 1 max ((PMCS_ui get "qty") + (_args select 0)) min 999];
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "qtySet": {
        PMCS_ui set ["qty", 1 max (floor parseNumber (_args select 0)) min 999];
    };
    case "ammoType": {
        PMCS_ui set ["ammoType", _args select 0];
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "mag": {
        PMCS_ui set ["mag", _args select 0];
        PMCS_ui set ["ammoType", ""];
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "magQty": {
        PMCS_ui set ["magQty", 1 max ((PMCS_ui get "magQty") + (_args select 0)) min 999];
        ["detail"] call PMCS_fnc_uiShop;
    };
    case "magQtySet": {
        PMCS_ui set ["magQty", 1 max (floor parseNumber (_args select 0)) min 999];
    };
    // ["box" | "unit"]: the chosen item (a weapon with its variant, or a magazine row with
    // its ammo type on the ammunition tab).
    case "add": {
        private _key = PMCS_ui get "sel";
        private _info = [_key, _market] call PMCS_fnc_itemInfo;
        if (_info isEqualTo []) exitWith {};
        private _variant = PMCS_ui get (["variant", "ammoType"] select ((_info select 0) == "mag"));
        if (_variant == "") exitWith {};
        [_key, _variant, PMCS_ui get "qty", (_args select 0) == "box"] call PMCS_fnc_uiCartAdd;
    };
    // ["box" | "unit"]: the magazine row and ammo type chosen in a weapon's card.
    case "magAdd": {
        private _key = PMCS_ui get "mag";
        if (_key == "" || {(PMCS_ui get "ammoType") == ""}) exitWith {};
        [_key, PMCS_ui get "ammoType", PMCS_ui get "magQty", (_args select 0) == "box"] call PMCS_fnc_uiCartAdd;
    };
    case "cartOpen": {
        PMCS_ui set ["cartOpen", true];
        ["overlay"] call PMCS_fnc_uiShop;
    };
    case "cartClose": {
        PMCS_ui set ["cartOpen", false];
        ["overlay"] call PMCS_fnc_uiShop;
    };
    case "cartQty": {
        private _cart = PMCS_ui get "cart";
        private _row = PMCS_ui get "cartRow";
        if (_row < 0 || {_row >= count _cart}) exitWith {};
        private _line = _cart select _row;
        _line set [2, 1 max ((_line select 2) + (_args select 0)) min 999];
        ["cart"] call PMCS_fnc_uiShop;
        ["overlay"] call PMCS_fnc_uiShop;
    };
    case "cartRemove": {
        private _cart = PMCS_ui get "cart";
        private _row = PMCS_ui get "cartRow";
        if (_row < 0 || {_row >= count _cart}) exitWith {};
        _cart deleteAt _row;
        PMCS_ui set ["cartRow", (_row min (count _cart - 1)) max 0];
        ["cart"] call PMCS_fnc_uiShop;
        ["overlay"] call PMCS_fnc_uiShop;
    };
    case "cartClear": {
        PMCS_ui set ["cart", []];
        ["cart"] call PMCS_fnc_uiShop;
        ["overlay"] call PMCS_fnc_uiShop;
    };
    case "checkout": {
        private _cart = PMCS_ui get "cart";
        if (_cart isEqualTo []) exitWith {};
        [player, PMCS_ui get "terminal", PMCS_ui get "account", +_cart] remoteExecCall ["PMCS_fnc_buy", 2];
        ["toast", [localize "STR_PMCS_PAYING"]] call PMCS_fnc_ui;
        (PMCS_ui get "checkout") ctrlEnable false;
    };
};
