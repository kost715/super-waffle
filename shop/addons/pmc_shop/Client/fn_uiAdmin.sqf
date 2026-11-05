// [event, arguments] -> nothing. Client. The market management page (a Zeus at the
// management laptop): "Ассортимент" — every item with its state, price, discount and
// quantity, and the editor of the chosen one; adding a class of the game; reset;
// "Скидки" — the whole market, boxes and categories; "Журнал". Every change is a request
// to the server (PMCS_fnc_admin), which checks it and sends the market back.
params ["_event", ["_args", []], ["_source", controlNull]];
if (isNil "PMCS_ui") exitWith {};
private _make = {_this call PMCS_fnc_uiMake};
private _market = PMCS_ui getOrDefault ["market", createHashMap];
private _money = {[_this] call PMCS_fnc_money};
private _click = {
    params ["_ctrl", "_event", ["_args", []]];
    _ctrl setVariable ["PMCS_event", [_event, _args]];
    _ctrl ctrlAddEventHandler ["ButtonClick", {((_this select 0) getVariable "PMCS_event") + [_this select 0] call PMCS_fnc_uiAdmin}];
    _ctrl
};
private _send = {
    params ["_action", "_actionArgs"];
    [player, PMCS_ui get "terminal", _action, _actionArgs] remoteExecCall ["PMCS_fnc_admin", 2];
};
private _number = {
    params ["_text", "_empty"];
    _text = _text trim [" $%", 0];
    if (_text == "") exitWith {_empty};
    private _n = parseNumber _text;
    if (_n != floor _n) exitWith {-2};
    _n
};
switch (_event) do {
    case "build": {
        {
            _x params ["_page", "_label", "_left"];
            PMCS_ui set ["nav_" + _page, [["PMCS_Button", [_left, 0.075, 0.075, 0.07], controlNull, "page", _label, 0.022, "white", "navy"] call _make, "page", [_page]] call _click];
        } forEach [["items", localize "STR_PMCS_ADMIN_ITEMS", 0.13], ["discounts", localize "STR_PMCS_ADMIN_DISCOUNTS", 0.21], ["log", localize "STR_PMCS_ADMIN_LOG", 0.29]];
        PMCS_ui set ["navLine", ["PMCS_Text", [0.13, 0.139, 0.075, 0.006], controlNull, "page", "", 0.02, "", "orange"] call _make];
        ["PMCS_TextRight", [0.55, 0.082, 0.43, 0.025], controlNull, "page", format [localize "STR_PMCS_ADMIN_WHO", name player], 0.016, "navyText"] call _make;
        ["PMCS_TextRight", [0.55, 0.108, 0.43, 0.025], controlNull, "page", format [localize "STR_PMCS_ADMIN_MISSION", missionName, worldName], 0.016, "navyText"] call _make;
        ["PMCS_Text", [0, 0.145, 1, 0.74], controlNull, "page", "", 0.02, "", "white"] call _make;
        (PMCS_ui get "address") ctrlSetText localize "STR_PMCS_ADDRESS_ADMIN";
        ["refresh"] call PMCS_fnc_uiAdmin;
    };
    case "refresh": {
        if !("market" in PMCS_ui) exitWith {};
        private _page = PMCS_ui get "apage";
        {
            private _button = PMCS_ui get ("nav_" + _x);
            _button ctrlSetTextColor ([["navyMuted"] call PMCS_fnc_uiColor, [1, 1, 1, 1]] select (_x == _page));
        } forEach ["items", "discounts", "log"];
        private _line = PMCS_ui get "navLine";
        _line ctrlSetPosition [((PMCS_ui get "screen") select 0) + ((PMCS_ui get "screen") select 2) * (0.13 + 0.08 * (["items", "discounts", "log"] find _page)),
            (ctrlPosition _line) select 1, (ctrlPosition _line) select 2, (ctrlPosition _line) select 3];
        _line ctrlCommit 0;
        [["table", "aside", "tools"]] call PMCS_fnc_uiClear;
        switch (_page) do {
            case "items": {["items"] call PMCS_fnc_uiAdmin};
            case "discounts": {["discounts"] call PMCS_fnc_uiAdmin};
            default {["log"] call PMCS_fnc_uiAdmin};
        };
    };
    case "items": {
        // Tools: section, filter, search, add, reset.
        ["PMCS_Text", [0, 0.145, 1, 0.055], controlNull, "tools", "", 0.02, "", "white"] call _make;
        ["PMCS_Text", [0, 0.199, 1, 0.001], controlNull, "tools", "", 0.02, "", "line"] call _make;
        private _section = ["PMCS_Combo", [0.015, 0.156, 0.14, 0.032], controlNull, "tools", "", 0.019] call _make;
        {_section lbSetData [_section lbAdd localize (_x select 1), _x select 0]} forEach [["weapon", "STR_PMCS_TAB_WEAPONS"], ["mag", "STR_PMCS_TAB_AMMO"], ["custom", "STR_PMCS_CATEGORY_CUSTOM"]];
        _section lbSetCurSel (["weapon", "mag", "custom"] find (PMCS_ui get "asection"));
        _section ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_row"];
            if (_row >= 0 && {(_ctrl lbData _row) != (PMCS_ui get "asection")}) then {["set", ["asection", _ctrl lbData _row]] call PMCS_fnc_uiAdmin};
        }];
        private _show = ["PMCS_Combo", [0.165, 0.156, 0.15, 0.032], controlNull, "tools", "", 0.019] call _make;
        {_show lbAdd localize _x} forEach ["STR_PMCS_SHOW_ALL", "STR_PMCS_SHOW_ON_SALE", "STR_PMCS_SHOW_HIDDEN", "STR_PMCS_SHOW_NO_PRICE",
            "STR_PMCS_SHOW_LIMITED", "STR_PMCS_SHOW_DISCOUNT", "STR_PMCS_SHOW_CHANGED"];
        _show lbSetCurSel (PMCS_ui get "ashow");
        _show ctrlAddEventHandler ["LBSelChanged", {
            params ["", "_row"];
            if (_row >= 0 && {_row != (PMCS_ui get "ashow")}) then {["set", ["ashow", _row]] call PMCS_fnc_uiAdmin};
        }];
        private _calCombo = ["PMCS_Combo", [0.325, 0.156, 0.14, 0.032], controlNull, "tools", "", 0.019] call _make;
        _calCombo lbSetData [_calCombo lbAdd localize "STR_PMCS_ALL_CALIBRES", ""];
        private _calibres = [];
        {
            if ((_y select 0) == (PMCS_ui get "asection") && {(_y select 3) != ""}) then {_calibres pushBackUnique (_y select 3)};
        } forEach ((call PMCS_fnc_catalog) get "items");
        _calibres sort true;
        {_calCombo lbSetData [_calCombo lbAdd _x, _x]} forEach _calibres;
        _calCombo lbSetCurSel ((_calibres find (PMCS_ui get "acal")) + 1);
        _calCombo ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_row"];
            if (_row >= 0 && {(_ctrl lbData _row) != (PMCS_ui get "acal")}) then {["set", ["acal", _ctrl lbData _row]] call PMCS_fnc_uiAdmin};
        }];
        ["PMCS_TextRight", [0.47, 0.156, 0.05, 0.032], controlNull, "tools", localize "STR_PMCS_SEARCH", 0.019, "grey"] call _make;
        private _search = ["PMCS_Edit", [0.525, 0.156, 0.1, 0.032], controlNull, "tools", PMCS_ui get "asearch", 0.019] call _make;
        _search ctrlAddEventHandler ["KeyUp", {
            params ["_ctrl"];
            if (ctrlText _ctrl != (PMCS_ui get "asearch")) then {
                PMCS_ui set ["asearch", ctrlText _ctrl];
                ["table"] call PMCS_fnc_uiAdmin;
            };
        }];
        [["PMCS_Button", [0.635, 0.154, 0.155, 0.038], controlNull, "tools", localize "STR_PMCS_ADMIN_ADD", 0.019, "white", "orangeDark"] call _make, "addOpen"] call _click;
        private _armed = diag_tickTime - (PMCS_ui get "aresetAt") < 5;
        [["PMCS_Button", [0.8, 0.154, 0.185, 0.038], controlNull, "tools", localize (["STR_PMCS_ADMIN_RESET", "STR_PMCS_ADMIN_RESET_CONFIRM"] select _armed), 0.019,
            ["text", "white"] select _armed, ["photo", "red"] select _armed] call _make, "reset"] call _click;
        ["table"] call PMCS_fnc_uiAdmin;
        ["aside"] call PMCS_fnc_uiAdmin;
    };
    case "table": {
        ["table"] call PMCS_fnc_uiClear;
        private _section = PMCS_ui get "asection";
        private _catalog = call PMCS_fnc_catalog;
        private _keys = if (_section == "custom") then {keys (_market get "custom")} else {(_catalog get "order") select {(((_catalog get "items") get _x) select 0) == _section}};
        private _search = toLower (PMCS_ui get "asearch");
        private _show = PMCS_ui get "ashow";
        private _list = ["PMCS_List", [0.012, 0.21, 0.676, 0.665], controlNull, "table", "", 0.016] call _make;
        _list lnbSetColumnsPos [0, 0.085, 0.3, 0.45, 0.58, 0.66, 0.75, 0.83, 0.88, 0.95];
        // Columns: state, item, two by section (category and calibre; calibre and ammo type;
        // kind and class), base price, box, single piece, discount, quantity, source.
        private _heads = switch (_section) do {
            case "mag": {["STR_PMCS_COL_MAGAZINE", "STR_PMCS_COL_CALIBRE", "STR_PMCS_COL_AMMO"]};
            case "custom": {["STR_PMCS_COL_ITEM", "STR_PMCS_COL_KIND", "STR_PMCS_COL_CLASS"]};
            default {["STR_PMCS_COL_ITEM", "STR_PMCS_COL_CATEGORY", "STR_PMCS_COL_CALIBRE"]};
        };
        _list lnbAddRow ((["STR_PMCS_COL_STATE"] + _heads + ["STR_PMCS_COL_PRICE", "STR_PMCS_COL_BOX", "STR_PMCS_COL_UNIT", "STR_PMCS_COL_DISCOUNT",
            "STR_PMCS_COL_QTY", "STR_PMCS_COL_SOURCE"]) apply {localize _x});
        _list lnbSetColor [[0, 0], ["grey"] call PMCS_fnc_uiColor];
        private _calibre = PMCS_ui get "acal";
        {
            private _key = _x;
            private _info = [_key, _market] call PMCS_fnc_itemInfo;
            private _over = (_market get "items") getOrDefault [_key, []];
            ([_key, _market] call PMCS_fnc_price) params ["_state", "_unit", "_box", "_off", "_left", "_boxUnits"];
            private _name = [_key, _market] call PMCS_fnc_itemName;
            private _cells = switch (_section) do {
                case "mag": {[[_info select 8, _info select 1] select ((_info select 8) == ""), _info select 3, ((_info select 7) apply {_x select 1}) joinString ", "]};
                case "custom": {[_name, localize ("STR_PMCS_KIND_" + (_info select 0)), ((_info select 7) select 0) select 0]};
                default {[_name, [_info select 2] call PMCS_fnc_categoryName, _info select 3]};
            };
            private _match = (_search == "" || {_search in toLower _name} || {_search in toLower (_info select 3)}
                || {(_info select 7) findIf {(_x select 3) findIf {_search in toLower _x} >= 0} >= 0}) && {_calibre == "" || {(_info select 3) == _calibre}};
            private _fits = switch (_show) do {
                case 1: {_state in ["ok", "soldout"]};
                case 2: {_state == "hidden"};
                case 3: {_state == "noprice"};
                case 4: {_over isNotEqualTo [] && {(_over select 3) >= 0}};
                case 5: {_off > 0};
                case 6: {_over isNotEqualTo []};
                default {true};
            };
            if (_match && {_fits}) then {
                private _base = if (_over isNotEqualTo [] && {(_over select 1) >= 0}) then {_over select 1} else {_info select 5};
                private _priced = _base > 0;
                private _row = _list lnbAddRow ([localize ("STR_PMCS_STATE_" + _state)] + _cells + [
                    if (_priced) then {_base call _money} else {"-"},
                    if (_priced) then {format ["%1 × %2", _boxUnits, _box call _money]} else {"-"},
                    if (_priced) then {_unit call _money} else {"-"},
                    if (_off > 0) then {format ["%1 %2", _off, "%"]} else {"-"},
                    if (_left < 0) then {localize "STR_PMCS_UI_UNLIMITED"} else {format ["%1 / %2", _left, _over select 3]},
                    localize (["STR_PMCS_SOURCE_CATALOG", "STR_PMCS_SOURCE_CHANGED", "STR_PMCS_SOURCE_ADDED"] select ([[0, 1] select (_over isNotEqualTo []), 2] select ((_info select 2) == "custom")))
                ]);
                _list lnbSetData [[_row, 0], _key];
                if !(_state in ["ok", "soldout"]) then {
                    for "_c" from 0 to 9 do {_list lnbSetColor [[_row, _c], ["grey"] call PMCS_fnc_uiColor]};
                };
                if (_key == (PMCS_ui get "asel")) then {_list lnbSetCurSelRow _row};
            };
        } forEach _keys;
        _list ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_row"];
            if (_row < 1) exitWith {};
            private _key = _ctrl lnbData [_row, 0];
            if (_key != (PMCS_ui get "asel")) then {
                PMCS_ui set ["asel", _key];
                PMCS_ui set ["aadd", false];
                ["aside"] call PMCS_fnc_uiAdmin;
            };
        }];
    };
    case "aside": {
        ["aside"] call PMCS_fnc_uiClear;
        private _x0 = 0.705;
        private _wd = 0.28;
        ["PMCS_Text", [0.695, 0.2, 0.305, 0.685], controlNull, "aside", "", 0.02, "", "panel"] call _make;
        if (PMCS_ui get "aadd") exitWith {["addForm"] call PMCS_fnc_uiAdmin};
        private _key = PMCS_ui get "asel";
        private _info = [_key, _market] call PMCS_fnc_itemInfo;
        if (_info isEqualTo []) exitWith {
            ["PMCS_Text", [_x0, 0.215, _wd, 0.05], controlNull, "aside", localize "STR_PMCS_ADMIN_PICK", 0.019, "grey"] call _make;
        };
        private _over = (_market get "items") getOrDefault [_key, [false, -1, 0, -1, -1]];
        ([_key, _market] call PMCS_fnc_price) params ["_state", "_unit", "_box", "_off", "_left", "_boxUnits"];
        private _picture = ((_info select 7) select 0) select 2;
        ["PMCS_Text", [_x0, 0.215, _wd, 0.1], controlNull, "aside", "", 0.02, "", "photo"] call _make;
        ["PMCS_Picture", [_x0 + 0.01, 0.22, _wd - 0.02, 0.09], controlNull, "aside", [_picture, "\pmc_shop\data\noimage_ca.paa"] select (_picture == "")] call _make;
        ["PMCS_TextBold", [_x0, 0.322, _wd, 0.04], controlNull, "aside", [_key, _market] call PMCS_fnc_itemName, 0.026] call _make;
        // A weapon: category, calibre, its classes (a pattern stands for its random pool); a
        // magazine row: the calibre and each ammo type with its price factor.
        private _line = if ((_info select 0) == "mag") then {
            format ["%1 · %2", _info select 3, ((_info select 7) apply {format ["%1 ×%2", _x select 1, _x select 4]}) joinString ", "]
        } else {
            format ["%1 · %2 · %3", [_info select 2] call PMCS_fnc_categoryName, _info select 3, (_info select 7) apply {_x select 0} joinString ", "]
        };
        private _lineCtrl = ["PMCS_Text", [_x0, 0.36, _wd, 0.026], controlNull, "aside", _line, 0.015, "grey"] call _make;
        _lineCtrl ctrlSetTooltip _line;
        ["PMCS_Text", [_x0, 0.386, _wd, 0.026], controlNull, "aside", format [localize "STR_PMCS_ADMIN_CATALOG_PRICE", [(_info select 5) call _money, "-"] select ((_info select 5) <= 0)], 0.016, "grey"] call _make;
        private _onSale = ["PMCS_Check", [_x0, 0.422, 0.012, 0.024], controlNull, "aside"] call _make;
        _onSale cbSetChecked !(_over select 0);
        ["PMCS_Text", [_x0 + 0.016, 0.42, 0.2, 0.028], controlNull, "aside", localize "STR_PMCS_UI_ON_SALE", 0.019] call _make;
        private _field = {
            params ["_label", "_value", "_y", "_tip"];
            ["PMCS_Text", [_x0, _y, 0.13, 0.032], controlNull, "aside", _label, 0.018] call _make;
            private _edit = ["PMCS_Edit", [_x0 + 0.135, _y, 0.145, 0.032], controlNull, "aside", _value, 0.019] call _make;
            _edit ctrlSetTooltip _tip;
            _edit
        };
        private _price = [localize "STR_PMCS_COL_PRICE", ["", str (_over select 1)] select ((_over select 1) >= 0), 0.458, localize "STR_PMCS_ADMIN_PRICE_TIP"] call _field;
        private _discount = [localize "STR_PMCS_COL_DISCOUNT", str (_over select 2), 0.498, localize "STR_PMCS_ADMIN_DISCOUNT_TIP"] call _field;
        ["PMCS_Text", [_x0, 0.538, 0.13, 0.032], controlNull, "aside", localize "STR_PMCS_COL_QTY", 0.018] call _make;
        private _mode = ["PMCS_Combo", [_x0 + 0.135, 0.538, 0.145, 0.032], controlNull, "aside", "", 0.018] call _make;
        _mode lbAdd localize "STR_PMCS_UI_UNLIMITED";
        _mode lbAdd localize "STR_PMCS_UI_LIMITED";
        _mode lbSetCurSel ([0, 1] select ((_over select 3) >= 0));
        private _qty = [localize "STR_PMCS_ADMIN_QTY", [str (_over select 3), ""] select ((_over select 3) < 0), 0.578, localize "STR_PMCS_ADMIN_QTY_TIP"] call _field;
        if ((_over select 3) >= 0) then {
            ["PMCS_Text", [_x0, 0.612, _wd, 0.026], controlNull, "aside", format [localize "STR_PMCS_LEFT_DETAIL", _left], 0.016, "grey"] call _make;
        };
        ["PMCS_Struct", [_x0, 0.64, _wd, 0.05], controlNull, "aside", format [localize "STR_PMCS_ADMIN_FINAL", [format [localize "STR_PMCS_BOX_DETAIL", _boxUnits, _box call _money], "-"] select (_state == "noprice"),
            format [localize "STR_PMCS_UNIT_DETAIL", _boxUnits, _unit call _money]], 0.017] call _make;
        private _apply = [["PMCS_Button", [_x0, 0.7, _wd, 0.045], controlNull, "aside", localize "STR_PMCS_ADMIN_APPLY", 0.021, "white", "navy"] call _make, "apply"] call _click;
        _apply setVariable ["PMCS_fields", [_onSale, _price, _discount, _mode, _qty]];
        [["PMCS_Button", [_x0, 0.755, 0.137, 0.04], controlNull, "aside", localize "STR_PMCS_ADMIN_DEFAULT", 0.018, "text", "photo"] call _make, "default"] call _click;
        if ((_info select 2) == "custom") then {
            [["PMCS_Button", [_x0 + 0.143, 0.755, 0.137, 0.04], controlNull, "aside", localize "STR_PMCS_REMOVE", 0.018, "white", "red"] call _make, "remove"] call _click;
        };
        PMCS_ui set ["afields", [_onSale, _price, _discount, _mode, _qty]];
    };
    case "addForm": {
        private _x0 = 0.705;
        private _wd = 0.28;
        ["PMCS_TextBold", [_x0, 0.215, _wd, 0.04], controlNull, "aside", localize "STR_PMCS_ADMIN_ADD_TITLE", 0.024] call _make;
        ["PMCS_Text", [_x0, 0.255, _wd, 0.05], controlNull, "aside", localize "STR_PMCS_ADMIN_ADD_HINT", 0.015, "grey"] call _make;
        ["PMCS_Text", [_x0, 0.31, 0.13, 0.032], controlNull, "aside", localize "STR_PMCS_ADMIN_CLASS", 0.018] call _make;
        private _class = ["PMCS_Edit", [_x0 + 0.135, 0.31, 0.145, 0.032], controlNull, "aside", PMCS_ui getOrDefault ["aaddClass", ""], 0.018] call _make;
        private _found = PMCS_ui getOrDefault ["aaddFound", []];
        [["PMCS_Button", [_x0, 0.35, _wd, 0.036], controlNull, "aside", localize "STR_PMCS_ADMIN_FIND", 0.018, "text", "photo"] call _make, "addFind"] call _click;
        if (_found isNotEqualTo []) then {
            _found params ["_foundName", "_foundPicture", "_foundKind"];
            ["PMCS_Text", [_x0, 0.395, _wd, 0.09], controlNull, "aside", "", 0.02, "", "photo"] call _make;
            ["PMCS_Picture", [_x0 + 0.01, 0.4, _wd - 0.02, 0.08], controlNull, "aside", [_foundPicture, "\pmc_shop\data\noimage_ca.paa"] select (_foundPicture == "")] call _make;
            ["PMCS_TextBold", [_x0, 0.49, _wd, 0.032], controlNull, "aside", format ["%1 · %2", _foundName, localize ("STR_PMCS_KIND_" + _foundKind)], 0.018] call _make;
        };
        ["PMCS_Text", [_x0, 0.53, 0.13, 0.032], controlNull, "aside", localize "STR_PMCS_COL_PRICE", 0.018] call _make;
        private _price = ["PMCS_Edit", [_x0 + 0.135, 0.53, 0.145, 0.032], controlNull, "aside", "", 0.018] call _make;
        ["PMCS_Text", [_x0, 0.57, 0.13, 0.032], controlNull, "aside", localize "STR_PMCS_ADMIN_QTY", 0.018] call _make;
        private _qty = ["PMCS_Edit", [_x0 + 0.135, 0.57, 0.145, 0.032], controlNull, "aside", "", 0.018] call _make;
        _qty ctrlSetTooltip localize "STR_PMCS_ADMIN_ADD_QTY_TIP";
        PMCS_ui set ["aaddFields", [_class, _price, _qty]];
        [["PMCS_Button", [_x0, 0.62, _wd, 0.045], controlNull, "aside", localize "STR_PMCS_ADMIN_ADD_CONFIRM", 0.021, "white", "orangeDark"] call _make, "addConfirm"] call _click;
        [["PMCS_Button", [_x0, 0.675, _wd, 0.04], controlNull, "aside", localize "STR_PMCS_CLOSE", 0.018, "text", "photo"] call _make, "addClose"] call _click;
    };
    case "discounts": {
        private _list = ["PMCS_List", [0.012, 0.16, 0.676, 0.715], controlNull, "table", "", 0.019] call _make;
        _list lnbSetColumnsPos [0, 0.75];
        _list lnbAddRow [localize "STR_PMCS_COL_CATEGORY", localize "STR_PMCS_COL_DISCOUNT"];
        _list lnbSetColor [[0, 0], ["grey"] call PMCS_fnc_uiColor];
        private _rows = ((call PMCS_fnc_catalog) get "categories") apply {[_x select 1, _x select 0]};
        _rows append [[localize "STR_PMCS_TAB_AMMO", "ammo"], [localize "STR_PMCS_CATEGORY_CUSTOM", "custom"]];
        {
            _x params ["_label", "_cat"];
            private _row = _list lnbAddRow [_label, format ["%1 %2", (_market get "cats") getOrDefault [_cat, 0], "%"]];
            _list lnbSetData [[_row, 0], _cat];
            if (_cat == (PMCS_ui get "acat")) then {_list lnbSetCurSelRow _row};
        } forEach _rows;
        _list ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_row"];
            if (_row < 1) exitWith {};
            PMCS_ui set ["acat", _ctrl lnbData [_row, 0]];
            ["refresh"] call PMCS_fnc_uiAdmin;
        }];
        private _x0 = 0.705;
        private _wd = 0.28;
        ["PMCS_Text", [0.695, 0.145, 0.305, 0.74], controlNull, "aside", "", 0.02, "", "panel"] call _make;
        ["PMCS_Text", [_x0, 0.16, _wd, 0.06], controlNull, "aside", localize "STR_PMCS_ADMIN_DISCOUNT_RULE", 0.016, "grey"] call _make;
        private _row = {
            params ["_label", "_value", "_y", "_action", "_actionArgs"];
            ["PMCS_Text", [_x0, _y, 0.15, 0.032], controlNull, "aside", _label, 0.019] call _make;
            private _edit = ["PMCS_Edit", [_x0 + 0.155, _y, 0.06, 0.032], controlNull, "aside", str _value, 0.019] call _make;
            private _apply = [["PMCS_Button", [_x0 + 0.22, _y, 0.06, 0.032], controlNull, "aside", localize "STR_PMCS_ADMIN_OK", 0.017, "white", "navy"] call _make, "discount", [_action, _actionArgs]] call _click;
            _apply setVariable ["PMCS_edit", _edit];
        };
        [localize "STR_PMCS_ADMIN_DISC_GLOBAL", _market get "global", 0.235, "global", []] call _row;
        private _cat = PMCS_ui get "acat";
        if (_cat != "") then {
            [[_cat] call PMCS_fnc_categoryName, (_market get "cats") getOrDefault [_cat, 0], 0.28, "category", [_cat]] call _row;
        } else {
            ["PMCS_Text", [_x0, 0.28, _wd, 0.032], controlNull, "aside", localize "STR_PMCS_ADMIN_PICK_CATEGORY", 0.017, "grey"] call _make;
        };
        ["PMCS_Text", [_x0, 0.33, _wd, 0.1], controlNull, "aside", localize "STR_PMCS_ADMIN_PACK_RULE", 0.015, "grey"] call _make;
    };
    case "log": {
        private _list = ["PMCS_List", [0.012, 0.16, 0.976, 0.715], controlNull, "table", "", 0.018] call _make;
        _list lnbSetColumnsPos [0, 0.13, 0.27];
        _list lnbAddRow [localize "STR_PMCS_COL_TIME", localize "STR_PMCS_COL_WHO", localize "STR_PMCS_COL_WHAT"];
        _list lnbSetColor [[0, 0], ["grey"] call PMCS_fnc_uiColor];
        private _log = +(_market get "log");
        reverse _log;
        {_list lnbAddRow _x} forEach _log;
        if (_log isEqualTo []) then {_list lnbAddRow ["", "", localize "STR_PMCS_ADMIN_LOG_EMPTY"]};
    };
    // Actions.
    case "page": {
        PMCS_ui set ["apage", _args select 0];
        PMCS_ui set ["aadd", false];
        ["refresh"] call PMCS_fnc_uiAdmin;
    };
    case "set": {
        PMCS_ui set [_args select 0, _args select 1];
        if ((_args select 0) == "asection") then {
            PMCS_ui set ["asel", ""];
            PMCS_ui set ["acal", ""];
        };
        ["refresh"] call PMCS_fnc_uiAdmin;
    };
    case "apply": {
        (PMCS_ui get "afields") params ["_onSale", "_priceEdit", "_discountEdit", "_mode", "_qtyEdit"];
        private _price = [ctrlText _priceEdit, -1] call _number;
        private _discount = [ctrlText _discountEdit, 0] call _number;
        private _max = if (lbCurSel _mode == 1) then {[ctrlText _qtyEdit, 0] call _number} else {-1};
        if (_price < -1 || {_discount < 0} || {_discount > 90} || {_max < -1}) exitWith {["toast", [localize "STR_PMCS_ERR_VALUE"]] call PMCS_fnc_ui};
        ["item", [PMCS_ui get "asel", !(cbChecked _onSale), _price, _discount, _max]] call _send;
    };
    case "default": {
        ["item", [PMCS_ui get "asel", false, -1, 0, -1]] call _send;
    };
    case "remove": {
        ["remove", [PMCS_ui get "asel"]] call _send;
        PMCS_ui set ["asel", ""];
    };
    case "reset": {
        if (diag_tickTime - (PMCS_ui get "aresetAt") < 5) then {
            PMCS_ui set ["aresetAt", -100];
            ["reset", []] call _send;
        } else {
            PMCS_ui set ["aresetAt", diag_tickTime];
            ["refresh"] call PMCS_fnc_uiAdmin;
        };
    };
    case "addOpen": {
        PMCS_ui set ["aadd", true];
        PMCS_ui set ["aaddFound", []];
        ["aside"] call PMCS_fnc_uiAdmin;
    };
    case "addClose": {
        PMCS_ui set ["aadd", false];
        ["aside"] call PMCS_fnc_uiAdmin;
    };
    case "addFind": {
        private _class = (ctrlText ((PMCS_ui get "aaddFields") select 0)) trim [" ", 0];
        PMCS_ui set ["aaddClass", _class];
        private _found = switch (true) do {
            case (_class == ""): {[]};
            case (isClass (configFile >> "CfgMagazines" >> _class)): {[configFile >> "CfgMagazines" >> _class, "mag"]};
            case (isClass (configFile >> "CfgWeapons" >> _class)): {[configFile >> "CfgWeapons" >> _class, ["item", "weapon"] select (getNumber (configFile >> "CfgWeapons" >> _class >> "type") in [1, 2, 4])]};
            case (isClass (configFile >> "CfgVehicles" >> _class) && {getNumber (configFile >> "CfgVehicles" >> _class >> "isbackpack") == 1}): {[configFile >> "CfgVehicles" >> _class, "backpack"]};
            default {[]};
        };
        if (_found isEqualTo []) then {
            PMCS_ui set ["aaddFound", []];
            ["toast", [localize "STR_PMCS_ERR_CLASS"]] call PMCS_fnc_ui;
        } else {
            PMCS_ui set ["aaddFound", [getText ((_found select 0) >> "displayName"), getText ((_found select 0) >> "picture"), _found select 1]];
        };
        ["aside"] call PMCS_fnc_uiAdmin;
    };
    case "addConfirm": {
        (PMCS_ui get "aaddFields") params ["_classEdit", "_priceEdit", "_qtyEdit"];
        private _class = (ctrlText _classEdit) trim [" ", 0];
        private _price = [ctrlText _priceEdit, 0] call _number;
        private _max = [ctrlText _qtyEdit, -1] call _number;
        if (_class == "" || {_price <= 0} || {_max < -1}) exitWith {["toast", [localize "STR_PMCS_ERR_VALUE"]] call PMCS_fnc_ui};
        ["add", [_class, _price, _max]] call _send;
        PMCS_ui set ["aadd", false];
        PMCS_ui set ["aaddClass", ""];
        PMCS_ui set ["asection", "custom"];
    };
    case "discount": {
        _args params ["_action", "_actionArgs"];
        private _value = [ctrlText (_source getVariable ["PMCS_edit", controlNull]), 0] call _number;
        if (_value < 0 || {_value > 90}) exitWith {["toast", [localize "STR_PMCS_ERR_VALUE"]] call PMCS_fnc_ui};
        [_action, _actionArgs + [_value]] call _send;
    };
};
