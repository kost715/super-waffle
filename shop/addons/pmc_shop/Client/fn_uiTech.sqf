// [event, arguments] -> nothing. Client. The gunsmith's page ("Техник") in the market
// laptop's browser: the player's weapons (rifle, launcher, handgun) and weapon parts on
// the left, the upgrades the chosen weapon can take on the right, each with its cost in
// money and parts (what the player has against what it needs). "Улучшить" asks for a
// second click, then the server checks and charges (PMCS_fnc_upgrade) and the player's
// machine swaps the weapon (PMCS_fnc_upgradeApply).
params ["_event", ["_args", []]];
if (isNil "PMCS_ui" || {(PMCS_ui getOrDefault ["site", "shop"]) != "tech"}) exitWith {};
private _make = {_this call PMCS_fnc_uiMake};
private _money = {[_this] call PMCS_fnc_money};
private _click = {
    params ["_ctrl", "_event", ["_args", []]];
    _ctrl setVariable ["PMCS_event", [_event, _args]];
    _ctrl ctrlAddEventHandler ["ButtonClick", {(_this select 0) getVariable "PMCS_event" call PMCS_fnc_uiTech}];
    _ctrl
};
private _weaponName = {
    private _shown = getText (configFile >> "CfgWeapons" >> _this >> "displayName");
    [_shown, _this] select (_shown == "")
};
switch (_event) do {
    case "build": {
        ["PMCS_Text", [0.6, 0.079, 0.22, 0.022], controlNull, "page", localize "STR_PMCS_PAY_WITH", 0.016, "navyText"] call _make;
        private _account = ["PMCS_Combo", [0.6, 0.103, 0.22, 0.032], controlNull, "page", "", 0.018] call _make;
        _account ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_row"];
            if (_row >= 0 && {(_ctrl lbData _row) != (PMCS_ui get "account")}) then {PMCS_ui set ["account", _ctrl lbData _row]; ["body"] call PMCS_fnc_uiTech};
        }];
        PMCS_ui set ["accountCtrl", _account];
        ["PMCS_Text", [0, 0.145, 0.3, 0.805], controlNull, "page", "", 0.02, "", "panel"] call _make;
        ["PMCS_Text", [0.3, 0.145, 0.7, 0.805], controlNull, "page", "", 0.02, "", "screen"] call _make;
        ["PMCS_Text", [0.299, 0.145, 0.001, 0.805], controlNull, "page", "", 0.02, "", "line"] call _make;
        PMCS_ui set ["techGroup", ["PMCS_Group", [0.3, 0.2, 0.7, 0.75], controlNull, "page"] call _make];
        (PMCS_ui get "address") ctrlSetText localize "STR_PMCS_ADDRESS_TECH";
        ["refresh"] call PMCS_fnc_uiTech;
    };
    case "refresh": {
        if !("market" in PMCS_ui) exitWith {};
        (PMCS_ui get "bank") params ["_personal", "_group", "_treasurer"];
        private _account = PMCS_ui get "accountCtrl";
        lbClear _account;
        _account lbSetData [_account lbAdd format [localize "STR_PMCS_ACCOUNT_PERSONAL", _personal call _money], "personal"];
        if (_treasurer) then {_account lbSetData [_account lbAdd format [localize "STR_PMCS_ACCOUNT_GROUP", _group call _money], "group"]};
        if (!_treasurer) then {PMCS_ui set ["account", "personal"]};
        _account lbSetCurSel ([0, 1] select ((PMCS_ui get "account") == "group"));
        ["body"] call PMCS_fnc_uiTech;
    };
    case "body": {
        ["tech"] call PMCS_fnc_uiClear;
        private _weapons = [primaryWeapon player, secondaryWeapon player, handgunWeapon player];
        if ((_weapons select (PMCS_ui getOrDefault ["techSlot", 0])) == "") then {
            PMCS_ui set ["techSlot", ((_weapons findIf {_x != "" && {([_x] call PMCS_fnc_upgradesFor) isNotEqualTo []}}) max (_weapons findIf {_x != ""})) max 0];
        };
        private _slot = PMCS_ui getOrDefault ["techSlot", 0];
        // The player's weapons.
        ["PMCS_TextBold", [0.015, 0.16, 0.27, 0.026], controlNull, "tech", localize "STR_PMCS_TECH_WEAPONS", 0.016, "grey"] call _make;
        {
            private _class = _x;
            private _y = 0.195 + _forEachIndex * 0.135;
            private _on = _forEachIndex == _slot && {_class != ""};
            if (_on) then {["PMCS_Text", [0.012, _y - 0.004, 0.276, 0.128], controlNull, "tech", "", 0.02, "", "orange"] call _make};
            ["PMCS_Text", [0.015, _y, 0.27, 0.12], controlNull, "tech", "", 0.02, "", "white"] call _make;
            ["PMCS_Text", [0.022, _y + 0.008, 0.25, 0.022], controlNull, "tech", localize (["STR_PMCS_SLOT_RIFLE", "STR_PMCS_SLOT_LAUNCHER", "STR_PMCS_SLOT_HANDGUN"] select _forEachIndex), 0.014, "grey"] call _make;
            if (_class == "") then {
                ["PMCS_Text", [0.022, _y + 0.045, 0.25, 0.03], controlNull, "tech", localize "STR_PMCS_SLOT_EMPTY", 0.018, "grey"] call _make;
            } else {
                private _picture = getText (configFile >> "CfgWeapons" >> _class >> "picture");
                ["PMCS_Picture", [0.022, _y + 0.032, 0.09, 0.08], controlNull, "tech", [_picture, "\pmc_shop\data\noimage_ca.paa"] select (_picture == "")] call _make;
                ["PMCS_TextBold", [0.118, _y + 0.034, 0.165, 0.028], controlNull, "tech", _class call _weaponName, 0.018] call _make;
                private _count = count ([_class] call PMCS_fnc_upgradesFor);
                ["PMCS_Text", [0.118, _y + 0.062, 0.165, 0.024], controlNull, "tech", [localize "STR_PMCS_TECH_NONE_SHORT", format [localize "STR_PMCS_TECH_COUNT", _count]] select (_count > 0),
                    0.015, ["grey", "green"] select (_count > 0)] call _make;
                ["PMCS_Text", [0.118, _y + 0.086, 0.165, 0.022], controlNull, "tech", _class, 0.013, "grey"] call _make;
                [["PMCS_ButtonClear", [0.015, _y, 0.27, 0.12], controlNull, "tech"] call _make, "slot", [_forEachIndex]] call _click;
            };
        } forEach _weapons;
        // The weapon parts in the inventory.
        private _items = items player;
        private _have = (call PMCS_fnc_parts) apply {private _c = _x; {_x == _c} count _items};
        ["PMCS_TextBold", [0.015, 0.615, 0.27, 0.026], controlNull, "tech", localize "STR_PMCS_TECH_PARTS", 0.016, "grey"] call _make;
        {
            private _y = 0.645 + _forEachIndex * 0.034;
            ["PMCS_Text", [0.015, _y, 0.2, 0.03], controlNull, "tech", localize _x, 0.018] call _make;
            ["PMCS_TextBoldRight", [0.2, _y, 0.085, 0.03], controlNull, "tech", str (_have select _forEachIndex), 0.02] call _make;
        } forEach ["STR_PMCS_PART_LOW", "STR_PMCS_PART_MED", "STR_PMCS_PART_HIGH"];
        ["PMCS_Text", [0.015, 0.76, 0.27, 0.15], controlNull, "tech", localize "STR_PMCS_TECH_NOTE", 0.014, "grey"] call _make;
        // The upgrades of the chosen weapon.
        private _weapon = _weapons select _slot;
        ["PMCS_TextBold", [0.315, 0.155, 0.67, 0.04], controlNull, "tech", [localize "STR_PMCS_TECH_TITLE", format [localize "STR_PMCS_TECH_TITLE_FOR", _weapon call _weaponName]] select (_weapon != ""),
            0.026] call _make;
        private _group = PMCS_ui get "techGroup";
        private _list = [_weapon] call PMCS_fnc_upgradesFor;
        if (_list isEqualTo []) exitWith {
            ["PMCS_Text", [0.315, 0.215, 0.67, 0.08], _group, "tech", localize (["STR_PMCS_TECH_NO_WEAPON", "STR_PMCS_TECH_NONE"] select (_weapon != "")), 0.019, "grey"] call _make;
        };
        (PMCS_ui get "bank") params ["_personal", "_group2"];
        private _balance = [_personal, _group2] select ((PMCS_ui get "account") == "group");
        private _armed = PMCS_ui getOrDefault ["techArmed", ["", -1]];
        private _busy = PMCS_ui getOrDefault ["techBusy", false];
        {
            _x params ["_upgrade", "_target"];
            _upgrade params ["_key", "", "", "_kind", "_op", "_price", "_parts"];
            private _y = 0.21 + _forEachIndex * 0.16;
            ["PMCS_Text", [0.315, _y, 0.67, 0.15], _group, "tech", "", 0.02, "", "white"] call _make;
            ["PMCS_Text", [0.322, _y + 0.01, 0.13, 0.13], _group, "tech", "", 0.02, "", "photo"] call _make;
            private _picture = getText (configFile >> "CfgWeapons" >> _target >> "picture");
            ["PMCS_Picture", [0.326, _y + 0.02, 0.122, 0.11], _group, "tech", [_picture, "\pmc_shop\data\noimage_ca.paa"] select (_picture == "")] call _make;
            ["PMCS_TextBold", [0.465, _y + 0.012, 0.33, 0.032], _group, "tech", _target call _weaponName, 0.021] call _make;
            ["PMCS_Text", [0.465, _y + 0.044, 0.33, 0.026], _group, "tech", format ["%1 · %2", localize (["STR_PMCS_KIND_UP", "STR_PMCS_KIND_GL"] select (_kind == "gl")), _op], 0.015,
                ["grey", "orangeDark"] select (_kind == "gl")] call _make;
            // Cost: money, then each part as have / need, red where something is missing.
            private _cost = [format ["<t font='RobotoCondensedBold' color='%1'>%2</t>", ["#2f5f2a", "#9e291f"] select (_price > _balance), _price call _money]];
            private _short = _price > _balance;
            {
                private _need = _parts param [_forEachIndex, 0];
                if (_need > 0) then {
                    private _missing = (_have select _forEachIndex) < _need;
                    if (_missing) then {_short = true};
                    _cost pushBack format ["<t color='%1'>%2 %3/%4</t>", ["#4a5056", "#9e291f"] select _missing, localize _x, _have select _forEachIndex, _need];
                };
            } forEach ["STR_PMCS_PART_SHORT_LOW", "STR_PMCS_PART_SHORT_MED", "STR_PMCS_PART_SHORT_HIGH"];
            ["PMCS_Struct", [0.465, _y + 0.072, 0.33, 0.035], _group, "tech", _cost joinString "   ", 0.017] call _make;
            private _next = count ([_target] call PMCS_fnc_upgradesFor);
            if (_next > 0) then {["PMCS_Text", [0.465, _y + 0.108, 0.33, 0.024], _group, "tech", format [localize "STR_PMCS_TECH_NEXT", _next], 0.014, "grey"] call _make};
            private _isArmed = (_armed select 0) == _key && {diag_tickTime - (_armed select 1) < 5};
            private _button = [["PMCS_Button", [0.81, _y + 0.05, 0.165, 0.05], _group, "tech",
                [localize "STR_PMCS_TECH_DO", format [localize "STR_PMCS_TECH_CONFIRM", _price call _money]] select _isArmed, 0.018, "white", ["orangeDark", "red"] select _isArmed] call _make,
                "upgrade", [_key]] call _click;
            _button ctrlEnable (!_short && {!_busy});
            if (_short) then {["PMCS_TextCenter", [0.81, _y + 0.104, 0.165, 0.024], _group, "tech", localize "STR_PMCS_TECH_SHORT", 0.014, "red"] call _make};
        } forEach _list;
    };
    case "slot": {
        PMCS_ui set ["techSlot", _args select 0];
        PMCS_ui set ["techArmed", ["", -1]];
        ["body"] call PMCS_fnc_uiTech;
    };
    // The first click arms the button for 5 seconds; the second sends the upgrade.
    case "upgrade": {
        _args params ["_key"];
        private _armed = PMCS_ui getOrDefault ["techArmed", ["", -1]];
        if ((_armed select 0) != _key || {diag_tickTime - (_armed select 1) >= 5}) exitWith {
            PMCS_ui set ["techArmed", [_key, diag_tickTime]];
            ["body"] call PMCS_fnc_uiTech;
        };
        PMCS_ui set ["techArmed", ["", -1]];
        PMCS_ui set ["techBusy", true];
        [player, PMCS_ui get "terminal", PMCS_ui get "account", PMCS_ui getOrDefault ["techSlot", 0], _key] remoteExecCall ["PMCS_fnc_upgrade", 2];
        ["toast", [localize "STR_PMCS_TECH_WORKING"]] call PMCS_fnc_ui;
        ["body"] call PMCS_fnc_uiTech;
    };
};
