// [event, arguments] -> nothing. Client. The laptop: frame, desktop A and the browser.
// The shop page is PMCS_fnc_uiShop, the market management page PMCS_fnc_uiAdmin. State
// lives in PMCS_ui (a hashmap) while the dialog is open.
params ["_event", ["_args", []]];
if (isNil "PMCS_ui") exitWith {};
private _make = {_this call PMCS_fnc_uiMake};
switch (_event) do {
    case "onLoad": {
        _args params ["_display"];
        PMCS_ui set ["display", _display];
        PMCS_ui set ["regions", createHashMap];
        PMCS_ui set ["screen", [safezoneX + safezoneW * 0.07, safezoneY + safezoneH * 0.06, safezoneW * 0.86, safezoneH * 0.86]];
        // The laptop around the screen: dimmed world, bezel, camera, base.
        ["PMCS_Text", [-0.09, -0.08, 1.18, 1.17], controlNull, "frame", "", 0.02, "", "dim"] call _make;
        ["PMCS_Text", [-0.018, -0.045, 1.036, 1.075], controlNull, "frame", "", 0.02, "", "bezel"] call _make;
        ["PMCS_Text", [0.497, -0.03, 0.006, 0.012], controlNull, "frame", "", 0.02, "", [0.23, 0.24, 0.26, 1]] call _make;
        ["PMCS_Text", [-0.04, 1.03, 1.08, 0.03], controlNull, "frame", "", 0.02, "", [0.106, 0.11, 0.118, 1]] call _make;
        ["PMCS_Text", [0, 0, 1, 1], controlNull, "frame", "", 0.02, "", "desk"] call _make;
        ["desktop"] call PMCS_fnc_ui;
        // The taskbar clock follows the mission's time.
        [] spawn {
            while {!isNil "PMCS_ui" && {!isNull (PMCS_ui get "display")}} do {
                private _clock = PMCS_ui getOrDefault ["clock", controlNull];
                if (!isNull _clock) then {
                    private _now = date;
                    private _two = {[str _this, "0" + str _this] select (_this < 10)};
                    _clock ctrlSetStructuredText parseText format ["<t align='right' size='%5'>%1:%2<br/>%3.%4.%6</t>", (_now select 3) call _two,
                        (_now select 4) call _two, (_now select 2) call _two, (_now select 1) call _two,
                        0.018 * ((PMCS_ui get "screen") select 3) / 0.03, _now select 0];
                };
                uiSleep 5;
            };
        };
    };
    case "onUnload": {
        if (PMCS_ui getOrDefault ["requested", false]) then {[] remoteExecCall ["PMCS_fnc_closed", 2]};
        PMCS_ui = nil;
    };
    case "desktop": {
        [["page", "filters", "grid", "detail", "cart", "overlay", "toast", "aside", "table", "tools", "tech"]] call PMCS_fnc_uiClear;
        PMCS_ui set ["view", "desk"];
        if ((PMCS_ui get "regions") getOrDefault ["desk", []] isNotEqualTo []) exitWith {};
        ["PMCS_Picture", [0, 0, 1, 0.95], controlNull, "desk", "\pmc_shop\data\wallpaper_co.paa"] call _make;
        private _admin = (PMCS_ui get "mode") == "admin";
        private _icons = [
            ["\pmc_shop\data\icon_pc_ca.paa", localize "STR_PMCS_DESK_PC", false],
            ["\pmc_shop\data\icon_folder_ca.paa", localize "STR_PMCS_DESK_DOCS", false],
            ["\pmc_shop\data\icon_browser_ca.paa", localize (["STR_PMCS_DESK_SHOP", "STR_PMCS_DESK_ADMIN"] select _admin), true],
            ["\pmc_shop\data\icon_bin_ca.paa", localize "STR_PMCS_DESK_BIN", false]
        ];
        {
            _x params ["_picture", "_label", "_live"];
            private _y = 0.03 + _forEachIndex * 0.155;
            if (_live) then {["PMCS_Text", [0.012, _y - 0.008, 0.075, 0.145], controlNull, "desk", "", 0.02, "", "iconSel"] call _make};
            ["PMCS_Picture", [0.028, _y, 0.043, 0.085], controlNull, "desk", _picture] call _make;
            ["PMCS_TextCenter", [0.008, _y + 0.09, 0.083, 0.04], controlNull, "desk", _label, 0.019, "white"] call _make;
            if (_live) then {
                private _button = ["PMCS_ButtonClear", [0.012, _y - 0.008, 0.075, 0.145], controlNull, "desk"] call _make;
                _button ctrlAddEventHandler ["ButtonClick", {["browser"] call PMCS_fnc_ui}];
            };
        } forEach _icons;
        // Taskbar.
        ["PMCS_Text", [0, 0.95, 1, 0.05], controlNull, "desk", "", 0.02, "", "navy2"] call _make;
        ["PMCS_TextCenter", [0.006, 0.956, 0.028, 0.038], controlNull, "desk", "ION", 0.016, "text", "orange"] call _make;
        ["PMCS_Text", [0.04, 0.957, 0.17, 0.036], controlNull, "desk", "  " + localize "STR_PMCS_DESK_SEARCH", 0.018, "navyText", "navy"] call _make;
        ["PMCS_Picture", [0.222, 0.957, 0.022, 0.036], controlNull, "desk", "\pmc_shop\data\icon_browser_ca.paa"] call _make;
        ["PMCS_Text", [0.218, 0.992, 0.03, 0.005], controlNull, "desk", "", 0.02, "", "orange"] call _make;
        private _pin = ["PMCS_ButtonClear", [0.216, 0.952, 0.034, 0.046], controlNull, "desk"] call _make;
        _pin ctrlAddEventHandler ["ButtonClick", {["browser"] call PMCS_fnc_ui}];
        ["PMCS_TextRight", [0.74, 0.956, 0.17, 0.038], controlNull, "desk", localize "STR_PMCS_DESK_TRAY", 0.018, "navyText"] call _make;
        PMCS_ui set ["clock", ["PMCS_Struct", [0.915, 0.952, 0.08, 0.046], controlNull, "desk", "", 0.018] call _make];
    };
    case "browser": {
        if ((PMCS_ui get "view") == "browser") exitWith {};
        PMCS_ui set ["view", "browser"];
        private _admin = (PMCS_ui get "mode") == "admin";
        // Window chrome: tabs, address bar.
        ["PMCS_Text", [0, 0, 1, 0.035], controlNull, "page", "", 0.02, "", "tabs"] call _make;
        ["PMCS_Text", [0.006, 0.005, 0.17, 0.03], controlNull, "page", "   " + localize (["STR_PMCS_TAB_SHOP", "STR_PMCS_TAB_ADMIN"] select _admin), 0.017, "text", "screen"] call _make;
        ["PMCS_Text", [0.18, 0.005, 0.15, 0.03], controlNull, "page", "   " + localize "STR_PMCS_TAB_BANK", 0.017, "grey"] call _make;
        private _close = ["PMCS_Button", [0.972, 0.004, 0.026, 0.027], controlNull, "page", "×", 0.022, "text", "tabs"] call _make;
        _close ctrlSetActiveColor ([0.85, 0.3, 0.25, 1]);
        _close ctrlAddEventHandler ["ButtonClick", {["desktop"] call PMCS_fnc_ui}];
        ["PMCS_Text", [0, 0.035, 1, 0.04], controlNull, "page", "", 0.02, "", "screen"] call _make;
        ["PMCS_Text", [0.008, 0.04, 0.05, 0.03], controlNull, "page", "<   >", 0.018, "grey"] call _make;
        ["PMCS_Text", [0.06, 0.042, 0.93, 0.027], controlNull, "page", "", 0.02, "", "white"] call _make;
        PMCS_ui set ["address", ["PMCS_Text", [0.068, 0.042, 0.9, 0.027], controlNull, "page", "", 0.017, "grey"] call _make];
        ["PMCS_Text", [0, 0.074, 1, 0.001], controlNull, "page", "", 0.02, "", "line"] call _make;
        // Site header.
        ["PMCS_Text", [0, 0.075, 1, 0.07], controlNull, "page", "", 0.02, "", "navy"] call _make;
        ["PMCS_TextBold", [0.018, 0.08, 0.1, 0.035], controlNull, "page", "ION", 0.032, "white"] call _make;
        ["PMCS_Text", [0.018, 0.112, 0.12, 0.025], controlNull, "page", localize (["STR_PMCS_SITE_SUB", "STR_PMCS_SITE_SUB_ADMIN"] select _admin), 0.015, "navyText"] call _make;
        PMCS_ui set ["requested", true];
        [player, PMCS_ui get "terminal"] remoteExecCall ["PMCS_fnc_requestState", 2];
        if (_admin) exitWith {["build"] call PMCS_fnc_uiAdmin};
        // The site's two sections: the market and the gunsmith ("Техник").
        private _site = PMCS_ui getOrDefault ["site", "shop"];
        {
            _x params ["_key", "_label", "_x0", "_w"];
            private _on = _key == _site;
            [["PMCS_TextBold", "PMCS_Text"] select !_on, [_x0, 0.075, _w, 0.064], controlNull, "page", localize _label, 0.024, ["navyMuted", "white"] select _on] call _make;
            if (_on) then {["PMCS_Text", [_x0, 0.139, _w * 0.8, 0.006], controlNull, "page", "", 0.02, "", "orange"] call _make};
            private _go = ["PMCS_ButtonClear", [_x0, 0.075, _w, 0.07], controlNull, "page"] call _make;
            _go setVariable ["PMCS_site", _key];
            _go ctrlAddEventHandler ["ButtonClick", {["site", [(_this select 0) getVariable "PMCS_site"]] call PMCS_fnc_ui}];
        } forEach [["shop", "STR_PMCS_NAV_SHOP", 0.13, 0.07], ["tech", "STR_PMCS_NAV_TECH", 0.205, 0.07]];
        if (_site == "tech") then {["build"] call PMCS_fnc_uiTech} else {["build"] call PMCS_fnc_uiShop};
    };
    // ["shop" | "tech"]: switch the site's section; the page is drawn again.
    case "site": {
        _args params [["_site", "shop", [""]]];
        if (_site == (PMCS_ui getOrDefault ["site", "shop"]) || {(PMCS_ui get "mode") == "admin"}) exitWith {};
        PMCS_ui set ["site", _site];
        PMCS_ui set ["techArmed", ["", -1]];
        [["page", "filters", "grid", "detail", "cart", "overlay", "toast", "tech"]] call PMCS_fnc_uiClear;
        PMCS_ui set ["view", "switching"];
        ["browser"] call PMCS_fnc_ui;
    };
    case "receive": {
        if ((PMCS_ui get "view") != "browser") exitWith {};
        if ((PMCS_ui get "mode") == "admin") exitWith {["refresh"] call PMCS_fnc_uiAdmin};
        if ((PMCS_ui getOrDefault ["site", "shop"]) == "tech") then {["refresh"] call PMCS_fnc_uiTech} else {["refresh"] call PMCS_fnc_uiShop};
    };
    case "toast": {
        _args params ["_text"];
        ["toast"] call PMCS_fnc_uiClear;
        if ((PMCS_ui get "view") != "browser") exitWith {};
        ["PMCS_Text", [0.17, 0.835, 0.54, 0.042], controlNull, "toast", "  " + _text, 0.019, "white", [0.122, 0.165, 0.2, 0.95]] call _make;
        private _stamp = diag_tickTime;
        PMCS_ui set ["toastAt", _stamp];
        [_stamp] spawn {
            params ["_stamp"];
            uiSleep 6;
            if (!isNil "PMCS_ui" && {(PMCS_ui getOrDefault ["toastAt", -1]) == _stamp}) then {["toast"] call PMCS_fnc_uiClear};
        };
    };
};
