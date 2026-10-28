#include "..\ui_defines.hpp"
// [mode, args] -> nothing. Client. The ATM window: one dialog with screens
//   main     - both balances; Zeus also gets the journal
//   account  - withdraw / deposit / history for the personal or group account
//   withdraw - amount, suggested banknotes, adjustable per note value
//   deposit  - banknotes carried, how many of each to pay in
//   history  - recent operations of the account (no Zeus operations)
//   zeus     - the whole journal with export
// State lives in PMCB_ui; balances and journals come from the server.
params [["_mode", "draw", [""]], ["_args", []]];
private _ui = missionNamespace getVariable ["PMCB_ui", createHashMap];
private _display = uiNamespace getVariable ["PMCB_display", displayNull];
private _state = _ui getOrDefault ["state", []];
private _notes = call PMCB_fnc_notes;
private _accountTitle = {
    if (_this == "group") then {format [localize "STR_PMCB_UI_GROUP", _state param [6, ""]]} else {localize "STR_PMCB_UI_PERSONAL"}
};
private _balance = {
    if ((_ui getOrDefault ["account", "personal"]) == "group") then {_state param [1, 0]} else {_state param [0, 0]}
};
// Rows of the withdraw/deposit list: [note index, count].
private _draftTotal = {
    private _sum = 0;
    {_sum = _sum + (_x select 1) * ((_notes select (_x select 0)) select 1)} forEach (_ui getOrDefault ["draft", []]);
    _sum
};
switch (_mode) do {
    case "onLoad": {
        uiNamespace setVariable ["PMCB_display", _args select 0];
        ["draw"] call PMCB_fnc_ui;
    };
    case "onUnload": {
        uiNamespace setVariable ["PMCB_display", displayNull];
        if !(isNull (_ui getOrDefault ["atm", objNull])) then {[] remoteExecCall ["PMCB_fnc_closed", 2]};
        PMCB_ui = nil;
    };
    case "open": {
        _args params ["_screen", ["_account", _ui getOrDefault ["account", "personal"]]];
        _ui set ["screen", _screen];
        _ui set ["account", _account];
        private _draft = [];
        if (_screen == "withdraw") then {{_draft pushBack [_forEachIndex, 0]} forEach _notes};
        if (_screen == "deposit") then {
            private _have = [player] call PMCB_fnc_noteCounts;
            {
                if ((_have getOrDefault [toLowerANSI (_x select 0), 0]) > 0) then {_draft pushBack [_forEachIndex, 0]};
            } forEach _notes;
        };
        _ui set ["draft", _draft];
        ["draw"] call PMCB_fnc_ui;
    };
    case "menu": {
        _ui set ["message", ""];
        private _screen = _ui getOrDefault ["screen", ""];
        if (_screen == "main") then {
            switch (_args) do {
                case 0: {["open", ["account", "personal"]] call PMCB_fnc_ui};
                case 1: {["open", ["account", "group"]] call PMCB_fnc_ui};
                case 2: {
                    _ui set ["screen", "loading"];
                    ["draw"] call PMCB_fnc_ui;
                    [player] remoteExecCall ["PMCB_fnc_zeusLog", 2];
                };
            };
        };
        if (_screen == "account") then {["open", [["withdraw", "deposit", "history"] select _args]] call PMCB_fnc_ui};
    };
    case "back": {
        _ui set ["message", ""];
        switch (_ui getOrDefault ["screen", ""]) do {
            case "account": {["open", ["main"]] call PMCB_fnc_ui};
            case "withdraw";
            case "deposit";
            case "history": {["open", ["account"]] call PMCB_fnc_ui};
            case "zeus": {
                // Opened from the Zeus module without an ATM: nothing to go back to.
                if (isNull (_ui getOrDefault ["atm", objNull])) then {closeDialog 0} else {["open", ["main"]] call PMCB_fnc_ui};
            };
        };
    };
    case "pick": {
        private _amount = parseNumber ctrlText (_display displayCtrl PMCB_IDC_EDIT);
        private _composition = [round _amount, _notes] call PMCB_fnc_compose;
        if (_composition isEqualTo []) exitWith {
            _ui set ["message", localize "STR_PMCB_UI_CANNOT_PAY"];
            ["draw"] call PMCB_fnc_ui;
        };
        private _draft = [];
        {_draft pushBack [_forEachIndex, 0]} forEach _notes;
        {
            private _class = _x select 0;
            private _at = _notes findIf {(_x select 0) == _class};
            (_draft select _at) set [1, (_composition select _forEachIndex) select 1];
        } forEach _composition;
        _ui set ["draft", _draft];
        _ui set ["message", ""];
        ["draw"] call PMCB_fnc_ui;
    };
    case "step": {
        private _row = lnbCurSelRow (_display displayCtrl PMCB_IDC_LIST);
        private _draft = _ui getOrDefault ["draft", []];
        if (_row < 0 || {_row >= count _draft}) exitWith {};
        private _entry = _draft select _row;
        private _limit = 10000;
        if ((_ui get "screen") == "deposit") then {
            _limit = ([player] call PMCB_fnc_noteCounts) getOrDefault [toLowerANSI ((_notes select (_entry select 0)) select 0), 0];
        };
        _entry set [1, 0 max (((_entry select 1) + _args) min _limit)];
        ["draw"] call PMCB_fnc_ui;
        (_display displayCtrl PMCB_IDC_LIST) lnbSetCurSelRow _row;
    };
    case "all": {
        if ((_ui get "screen") == "deposit") then {
            private _have = [player] call PMCB_fnc_noteCounts;
            {_x set [1, _have getOrDefault [toLowerANSI ((_notes select (_x select 0)) select 0), 0]]} forEach (_ui getOrDefault ["draft", []]);
            ["draw"] call PMCB_fnc_ui;
        };
        if ((_ui get "screen") == "zeus") then {[_ui getOrDefault ["log", []]] call PMCB_fnc_export};
    };
    case "confirm": {
        private _screen = _ui getOrDefault ["screen", ""];
        if (_screen == "zeus") exitWith {
            private _row = lnbCurSelRow (_display displayCtrl PMCB_IDC_LIST);
            private _log = _ui getOrDefault ["log", []];
            if (_row >= 0 && {_row < count _log}) then {[[_log select _row]] call PMCB_fnc_export};
        };
        if !(_screen in ["withdraw", "deposit"]) exitWith {};
        if (_ui getOrDefault ["busy", false]) exitWith {};
        private _composition = ((_ui getOrDefault ["draft", []]) select {(_x select 1) > 0}) apply {[(_notes select (_x select 0)) select 0, _x select 1]};
        if (_composition isEqualTo []) exitWith {};
        _ui set ["busy", true];
        [player, _ui get "atm", _ui get "account", _composition] remoteExecCall [["PMCB_fnc_depositStart", "PMCB_fnc_withdraw"] select (_screen == "withdraw"), 2];
        ["draw"] call PMCB_fnc_ui;
    };
    case "amountLoad": {
        ((_args select 0) displayCtrl PMCB_IDC_AMOUNT_TITLE) ctrlSetText localize (["STR_PMCB_MODULE_REMOVE", "STR_PMCB_MODULE_ADD"] select ((missionNamespace getVariable ["PMCB_amountSign", 1]) > 0));
    };
    case "amountOk": {
        private _amount = round parseNumber ctrlText ((findDisplay PMCB_IDD_AMOUNT) displayCtrl PMCB_IDC_AMOUNT_EDIT);
        if (_amount <= 0) exitWith {hint localize "STR_PMCB_ERR_AMOUNT"};
        [player, _amount * (missionNamespace getVariable ["PMCB_amountSign", 1])] remoteExecCall ["PMCB_fnc_zeusAdjust", 2];
        closeDialog 1;
    };
    case "draw": {
        if (isNull _display) exitWith {};
        private _screen = _ui getOrDefault ["screen", "loading"];
        private _account = _ui getOrDefault ["account", "personal"];
        private _visible = switch (_screen) do {
            case "main": {[PMCB_IDC_MENU0, PMCB_IDC_MENU1, PMCB_IDC_CLOSE] + ([[], [PMCB_IDC_MENU2]] select (_state param [3, false]))};
            case "account": {[PMCB_IDC_MENU0, PMCB_IDC_MENU1, PMCB_IDC_MENU2, PMCB_IDC_BACK, PMCB_IDC_CLOSE]};
            case "withdraw": {[PMCB_IDC_LABEL, PMCB_IDC_EDIT, PMCB_IDC_PICK, PMCB_IDC_LIST, PMCB_IDC_MINUS, PMCB_IDC_PLUS, PMCB_IDC_BACK, PMCB_IDC_ACTION, PMCB_IDC_CLOSE]};
            case "deposit": {[PMCB_IDC_LIST, PMCB_IDC_MINUS, PMCB_IDC_PLUS, PMCB_IDC_ALL, PMCB_IDC_BACK, PMCB_IDC_ACTION, PMCB_IDC_CLOSE]};
            case "history": {[PMCB_IDC_LIST, PMCB_IDC_BACK, PMCB_IDC_CLOSE]};
            case "zeus": {[PMCB_IDC_LIST, PMCB_IDC_ALL, PMCB_IDC_BACK, PMCB_IDC_ACTION, PMCB_IDC_CLOSE]};
            default {[PMCB_IDC_CLOSE]};
        };
        {
            (_display displayCtrl _x) ctrlShow (_x in _visible);
        } forEach [PMCB_IDC_MENU0, PMCB_IDC_MENU1, PMCB_IDC_MENU2, PMCB_IDC_LABEL, PMCB_IDC_EDIT, PMCB_IDC_PICK, PMCB_IDC_LIST,
            PMCB_IDC_MINUS, PMCB_IDC_PLUS, PMCB_IDC_ALL, PMCB_IDC_BACK, PMCB_IDC_ACTION, PMCB_IDC_CLOSE];
        private _title = _display displayCtrl PMCB_IDC_TITLE;
        private _info = _display displayCtrl PMCB_IDC_INFO;
        private _list = _display displayCtrl PMCB_IDC_LIST;
        private _menu = {(_display displayCtrl ([PMCB_IDC_MENU0, PMCB_IDC_MENU1, PMCB_IDC_MENU2] select (_this select 0))) ctrlSetText (_this select 1)};
        private _path = [localize "STR_PMCB_UI_ATM"];
        if (_screen in ["account", "withdraw", "deposit", "history"]) then {_path pushBack (_account call _accountTitle)};
        if (_screen in ["withdraw", "deposit", "history"]) then {_path pushBack localize ("STR_PMCB_UI_" + _screen)};
        if (_screen == "zeus") then {_path = [localize "STR_PMCB_UI_JOURNAL"]};
        _title ctrlSetText (" " + (_path joinString "  >  "));
        // The list is taller where there is no amount row above it.
        private _tall = _screen in ["deposit", "history", "zeus"];
        _list ctrlSetPosition [safezoneX + safezoneW * 0.285, safezoneY + safezoneH * ([0.415, 0.365] select _tall), safezoneW * 0.43,
            safezoneH * ([0.27, [0.32, 0.375] select (_screen == "history")] select _tall)];
        _list ctrlCommit 0;
        lnbClear _list;
        private _text = "";
        private _line = {format ["%1: <t color='#9fe0a5'>%2</t>", _this select 0, [_this select 1] call PMCB_fnc_money]};
        switch (_screen) do {
            case "loading": {_text = localize "STR_PMCB_UI_LOADING"};
            case "main": {
                _text = [[localize "STR_PMCB_UI_PERSONAL", _state param [0, 0]] call _line, ["group" call _accountTitle, _state param [1, 0]] call _line] joinString "<br/>";
                [0, localize "STR_PMCB_UI_PERSONAL"] call _menu;
                [1, "group" call _accountTitle] call _menu;
                [2, localize "STR_PMCB_UI_JOURNAL"] call _menu;
            };
            case "account": {
                _text = [localize "STR_PMCB_UI_BALANCE", call _balance] call _line;
                private _canWithdraw = _account == "personal" || {_state param [2, false]};
                if (_account == "group") then {
                    _text = _text + "<br/>" + localize (["STR_PMCB_UI_TREASURER_ONLY", "STR_PMCB_UI_TREASURER"] select _canWithdraw);
                };
                [0, localize "STR_PMCB_UI_withdraw"] call _menu;
                [1, localize "STR_PMCB_UI_deposit"] call _menu;
                [2, localize "STR_PMCB_UI_history"] call _menu;
                (_display displayCtrl PMCB_IDC_MENU0) ctrlEnable _canWithdraw;
            };
            case "withdraw";
            case "deposit": {
                private _have = [player] call PMCB_fnc_noteCounts;
                private _withdraw = _screen == "withdraw";
                _list lnbSetColumnsPos [0, 0.35, 0.65];
                {
                    _x params ["_index", "_count"];
                    (_notes select _index) params ["_class", "_value"];
                    private _name = getText (configFile >> (["CfgWeapons", "CfgMagazines"] select (isClass (configFile >> "CfgMagazines" >> _class))) >> _class >> "displayName");
                    private _second = if (_withdraw) then {format ["x %1", _count]} else {
                        format ["%1 / %2", _count, _have getOrDefault [toLowerANSI _class, 0]]
                    };
                    _list lnbAddRow [format ["%1  (%2)", [_value] call PMCB_fnc_money, _name], _second, [_count * _value] call PMCB_fnc_money];
                } forEach (_ui getOrDefault ["draft", []]);
                private _total = call _draftTotal;
                _text = [[localize "STR_PMCB_UI_BALANCE", call _balance] call _line,
                    [localize (["STR_PMCB_UI_TO_DEPOSIT", "STR_PMCB_UI_TO_WITHDRAW"] select _withdraw), _total] call _line] joinString "<br/>";
                if (_notes isEqualTo []) then {_text = _text + "<br/><t color='#ff8080'>" + localize "STR_PMCB_UI_NO_NOTES" + "</t>"};
                if (!_withdraw && {_notes isNotEqualTo []} && {(_ui getOrDefault ["draft", []]) isEqualTo []}) then {
                    _text = _text + "<br/>" + localize "STR_PMCB_UI_NO_CASH";
                };
                if (_withdraw && {_total > call _balance}) then {_text = _text + "<br/><t color='#ff8080'>" + localize "STR_PMCB_ERR_FUNDS" + "</t>"};
                private _action = _display displayCtrl PMCB_IDC_ACTION;
                _action ctrlSetText localize (["STR_PMCB_UI_DO_DEPOSIT", "STR_PMCB_UI_DO_WITHDRAW"] select _withdraw);
                _action ctrlEnable (_total > 0 && {!(_ui getOrDefault ["busy", false])} && {!_withdraw || {_total <= call _balance}});
                (_display displayCtrl PMCB_IDC_ALL) ctrlSetText localize "STR_PMCB_UI_ALL";
            };
            case "history": {
                _text = _account call _accountTitle;
                _list lnbSetColumnsPos [0, 0.3, 0.5, 0.67, 0.84];
                {
                    _x params ["_time", "_op", "_amount", "_after", "_who"];
                    _list lnbAddRow [_time, localize ("STR_PMCB_OP_" + _op), [_amount] call PMCB_fnc_money, [_after] call PMCB_fnc_money, _who];
                } forEach (_state param [[4, 5] select (_account == "group"), []]);
            };
            case "zeus": {
                private _log = _ui getOrDefault ["log", []];
                _text = format [localize "STR_PMCB_UI_JOURNAL_INFO", count _log];
                _list lnbSetColumnsPos [0, 0.07, 0.3, 0.47, 0.64, 0.76, 0.88];
                {
                    _x params ["_n", "_time", "", "_accountName", "_op", "_amount", "_after", "", "_who"];
                    _list lnbAddRow [str _n, _time, _accountName, localize ("STR_PMCB_OP_" + _op), [_amount] call PMCB_fnc_money, [_after] call PMCB_fnc_money, _who];
                } forEach _log;
                (_display displayCtrl PMCB_IDC_ACTION) ctrlSetText localize "STR_PMCB_UI_EXPORT_ONE";
                (_display displayCtrl PMCB_IDC_ACTION) ctrlEnable true;
                (_display displayCtrl PMCB_IDC_ALL) ctrlSetText localize "STR_PMCB_UI_EXPORT_ALL";
            };
        };
        private _message = _ui getOrDefault ["message", ""];
        if (_message != "") then {_text = _text + "<br/><t color='#ffd27f'>" + _message + "</t>"};
        _info ctrlSetStructuredText parseText _text;
    };
};
