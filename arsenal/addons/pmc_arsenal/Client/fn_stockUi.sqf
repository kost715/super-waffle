#include "..\ui_defines.hpp"
// [mode, args] -> nothing. Client (Zeus). The stock window: the storage's items with a
// category filter and a name search; the selected item can be reduced, set, made
// unlimited or removed. The server applies every change and sends the stock back.
params [["_mode", "draw", [""]], ["_args", []]];
private _ui = missionNamespace getVariable ["PMCA_stockUi", createHashMap];
private _display = uiNamespace getVariable ["PMCA_stockDisplay", displayNull];
switch (_mode) do {
    case "onLoad": {
        uiNamespace setVariable ["PMCA_stockDisplay", _args select 0];
        ["draw"] call PMCA_fnc_stockUi;
    };
    case "onUnload": {
        uiNamespace setVariable ["PMCA_stockDisplay", displayNull];
        PMCA_stockUi = nil;
    };
    case "filter": {
        _ui set ["filter", _args];
        ["draw"] call PMCA_fnc_stockUi;
    };
    case "refresh": {
        [player, _ui getOrDefault ["id", ""]] remoteExecCall ["PMCA_fnc_zeusStockId", 2];
    };
    case "do": {
        private _row = lnbCurSelRow (_display displayCtrl PMCA_IDC_LIST);
        private _shown = _ui getOrDefault ["shown", []];
        if (_row < 0 || {_row >= count _shown}) exitWith {hint localize "STR_PMCA_STOCK_PICK"};
        private _value = round parseNumber ctrlText (_display displayCtrl PMCA_IDC_AMOUNT);
        [player, _ui getOrDefault ["id", ""], _shown select _row, _args, _value] remoteExecCall ["PMCA_fnc_zeusEdit", 2];
    };
    case "draw": {
        if (isNull _display) exitWith {};
        (_display displayCtrl PMCA_IDC_TITLE) ctrlSetText format [" %1", format [localize "STR_PMCA_STOCK_TITLE", _ui getOrDefault ["id", ""]]];
        private _filter = _ui getOrDefault ["filter", "all"];
        private _search = toLower ctrlText (_display displayCtrl PMCA_IDC_SEARCH);
        private _categoryOf = {
            switch (true) do {
                case (_this in [0, 2, 18, 19, 20, 21, 25, 26]): {"weapons"};
                case (_this == 1): {"launchers"};
                case (_this in [22, 23]): {"explosives"};
                case (_this in [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 24]): {"equipment"};
                default {"other"};
            }
        };
        private _rows = [];
        {
            _x params ["_class", "_amount", "_tab"];
            private _name = "";
            {
                private _cfg = configFile >> _x >> _class;
                if (_name == "" && {isClass _cfg}) then {_name = getText (_cfg >> "displayName")};
            } forEach ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"];
            if (_name == "") then {_name = _class};
            private _category = _tab call _categoryOf;
            if ((_filter == "all" || {_filter == _category}) && {_search == "" || {(toLower _name) find _search >= 0} || {(toLower _class) find _search >= 0}}) then {
                _rows pushBack [toLower _name, _name, _class, _amount, _category];
            };
        } forEach (_ui getOrDefault ["rows", []]);
        _rows sort true;
        private _list = _display displayCtrl PMCA_IDC_LIST;
        lnbClear _list;
        private _shown = [];
        {
            _x params ["", "_name", "_class", "_amount", "_category"];
            private _text = str _amount;
            if (_amount == -1) then {_text = localize "STR_PMCA_STOCK_INFINITE"} else {
                if (isClass (configFile >> "CfgMagazines" >> _class)) then {
                    private _size = (getNumber (configFile >> "CfgMagazines" >> _class >> "count")) max 1;
                    _text = format [localize "STR_PMCA_STOCK_MAGS", floor (_amount / _size)];
                    if (_amount % _size > 0) then {_text = _text + format [localize "STR_PMCA_STOCK_ROUNDS", _amount % _size]};
                };
            };
            _list lnbAddRow [_name, _text, localize ("STR_PMCA_STOCK_" + toUpper _category)];
            _shown pushBack _class;
        } forEach _rows;
        _ui set ["shown", _shown];
        (_display displayCtrl PMCA_IDC_INFO) ctrlSetStructuredText parseText format [localize "STR_PMCA_STOCK_INFO",
            count _shown, count (_ui getOrDefault ["rows", []]), localize ("STR_PMCA_STOCK_" + toUpper _filter)];
    };
};
