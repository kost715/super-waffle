// [event, arguments] -> nothing. Client. The gunsmith's page ("Техник") in the market
// laptop's browser: the player's weapons (rifle, launcher, handgun), the vest worn and the
// items the gunsmith takes (weapon parts, warbelts, old uniforms) on the left; the upgrades
// the chosen weapon or vest can take on the right, each with its cost in money and items
// (what the player has against what it needs). "Улучшить" asks for a
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
        // Four places the gunsmith works on: rifle, launcher, handgun and the vest worn.
        private _carried = [primaryWeapon player, secondaryWeapon player, handgunWeapon player, vest player];
        private _offersOf = {
            params ["_slot", "_class"];
            if (_slot == 3) then {[_class] call PMCS_fnc_gearUpgradesFor} else {[_class] call PMCS_fnc_upgradesFor}
        };
        if ((_carried select (PMCS_ui getOrDefault ["techSlot", 0])) == "") then {
            private _withOffers = -1;
            {if (_withOffers < 0 && {_x != ""} && {([_forEachIndex, _x] call _offersOf) isNotEqualTo []}) then {_withOffers = _forEachIndex}} forEach _carried;
            PMCS_ui set ["techSlot", (_withOffers max (_carried findIf {_x != ""})) max 0];
        };
        private _slot = PMCS_ui getOrDefault ["techSlot", 0];
        ["PMCS_TextBold", [0.015, 0.155, 0.27, 0.026], controlNull, "tech", localize "STR_PMCS_TECH_WEAPONS", 0.016, "grey"] call _make;
        {
            private _class = _x;
            private _y = 0.185 + _forEachIndex * 0.108;
            private _on = _forEachIndex == _slot && {_class != ""};
            if (_on) then {["PMCS_Text", [0.012, _y - 0.004, 0.276, 0.106], controlNull, "tech", "", 0.02, "", "orange"] call _make};
            ["PMCS_Text", [0.015, _y, 0.27, 0.098], controlNull, "tech", "", 0.02, "", "white"] call _make;
            ["PMCS_Text", [0.022, _y + 0.004, 0.25, 0.022], controlNull, "tech",
                localize (["STR_PMCS_SLOT_RIFLE", "STR_PMCS_SLOT_LAUNCHER", "STR_PMCS_SLOT_HANDGUN", "STR_PMCS_SLOT_VEST"] select _forEachIndex), 0.014, "grey"] call _make;
            if (_class == "") then {
                ["PMCS_Text", [0.022, _y + 0.036, 0.25, 0.03], controlNull, "tech", localize "STR_PMCS_SLOT_EMPTY", 0.018, "grey"] call _make;
            } else {
                private _picture = getText (configFile >> "CfgWeapons" >> _class >> "picture");
                ["PMCS_Picture", [0.022, _y + 0.026, 0.08, 0.066], controlNull, "tech", [_picture, "\pmc_shop\data\noimage_ca.paa"] select (_picture == "")] call _make;
                ["PMCS_TextBold", [0.108, _y + 0.026, 0.175, 0.026], controlNull, "tech", _class call _weaponName, 0.017] call _make;
                private _count = count ([_forEachIndex, _class] call _offersOf);
                ["PMCS_Text", [0.108, _y + 0.051, 0.175, 0.022], controlNull, "tech", [localize "STR_PMCS_TECH_NONE_SHORT", format [localize "STR_PMCS_TECH_COUNT", _count]] select (_count > 0),
                    0.014, ["grey", "green"] select (_count > 0)] call _make;
                ["PMCS_Text", [0.108, _y + 0.072, 0.175, 0.02], controlNull, "tech", _class, 0.012, "grey"] call _make;
                [["PMCS_ButtonClear", [0.015, _y, 0.27, 0.098], controlNull, "tech"] call _make, "slot", [_forEachIndex]] call _click;
            };
        } forEach _carried;
        // What the gunsmith takes from the inventory, and how much of it the player has.
        private _items = items player;
        private _haveOf = {private _c = _this; {_x == _c} count _items};
        ["PMCS_TextBold", [0.015, 0.625, 0.27, 0.026], controlNull, "tech", localize "STR_PMCS_TECH_PARTS", 0.016, "grey"] call _make;
        {
            _x params ["_label", "_class"];
            private _y = 0.652 + _forEachIndex * 0.03;
            ["PMCS_Text", [0.015, _y, 0.2, 0.028], controlNull, "tech", localize _label, 0.016] call _make;
            ["PMCS_TextBoldRight", [0.2, _y, 0.085, 0.028], controlNull, "tech", str (_class call _haveOf), 0.018] call _make;
        } forEach [["STR_PMCS_PART_LOW", (call PMCS_fnc_parts) select 0], ["STR_PMCS_PART_MED", (call PMCS_fnc_parts) select 1],
            ["STR_PMCS_PART_HIGH", (call PMCS_fnc_parts) select 2], ["STR_PMCS_ITEM_BELT", (call PMCS_fnc_gearItems) select 0],
            ["STR_PMCS_ITEM_UNIFORM", (call PMCS_fnc_gearItems) select 1]];
        ["PMCS_Text", [0.015, 0.81, 0.27, 0.13], controlNull, "tech", localize "STR_PMCS_TECH_NOTE", 0.013, "grey"] call _make;
        // The upgrades of the chosen weapon or vest, each as [key, target, kind, operation,
        // price, needs [[label, have, need], ...], upgrades after it].
        private _current = _carried select _slot;
        ["PMCS_TextBold", [0.315, 0.155, 0.67, 0.04], controlNull, "tech", [localize "STR_PMCS_TECH_TITLE", format [localize "STR_PMCS_TECH_TITLE_FOR", _current call _weaponName]] select (_current != ""),
            0.026] call _make;
        private _group = PMCS_ui get "techGroup";
        private _offers = [_slot, _current] call _offersOf;
        if (_offers isEqualTo []) exitWith {
            ["PMCS_Text", [0.315, 0.215, 0.67, 0.08], _group, "tech", localize (["STR_PMCS_TECH_NO_WEAPON", "STR_PMCS_TECH_NONE"] select (_current != "")), 0.019, "grey"] call _make;
        };
        private _entries = if (_slot == 3) then {
            _offers apply {
                _x params ["_upgrade", "_target"];
                [_upgrade select 0, _target, localize (["STR_PMCS_KIND_ROLE", "STR_PMCS_KIND_BELT"] select ((_upgrade select 5) == "belt")), _upgrade select 2, _upgrade select 6,
                    ([_upgrade] call PMCS_fnc_gearTake) apply {[(_x select 0) call PMCS_fnc_itemTitle, (_x select 0) call _haveOf, _x select 1]},
                    count ([_target] call PMCS_fnc_gearUpgradesFor), (_upgrade select 5) == "belt"]
            }
        } else {
            _offers apply {
                _x params ["_upgrade", "_target"];
                private _needs = [];
                {
                    private _need = (_upgrade select 6) param [_forEachIndex, 0];
                    if (_need > 0) then {_needs pushBack [localize (["STR_PMCS_PART_SHORT_LOW", "STR_PMCS_PART_SHORT_MED", "STR_PMCS_PART_SHORT_HIGH"] select _forEachIndex), _x call _haveOf, _need]};
                } forEach (call PMCS_fnc_parts);
                [_upgrade select 0, _target, localize (["STR_PMCS_KIND_UP", "STR_PMCS_KIND_GL"] select ((_upgrade select 3) == "gl")), _upgrade select 4, _upgrade select 5,
                    _needs, count ([_target] call PMCS_fnc_upgradesFor), (_upgrade select 3) == "gl"]
            }
        };
        (PMCS_ui get "bank") params ["_personal", "_group2"];
        private _balance = [_personal, _group2] select ((PMCS_ui get "account") == "group");
        private _armed = PMCS_ui getOrDefault ["techArmed", ["", -1]];
        private _busy = PMCS_ui getOrDefault ["techBusy", false];
        {
            _x params ["_key", "_target", "_kind", "_op", "_price", "_needs", "_next", "_accent"];
            private _y = 0.21 + _forEachIndex * 0.16;
            ["PMCS_Text", [0.315, _y, 0.67, 0.15], _group, "tech", "", 0.02, "", "white"] call _make;
            ["PMCS_Text", [0.322, _y + 0.01, 0.13, 0.13], _group, "tech", "", 0.02, "", "photo"] call _make;
            private _picture = getText (configFile >> "CfgWeapons" >> _target >> "picture");
            ["PMCS_Picture", [0.326, _y + 0.02, 0.122, 0.11], _group, "tech", [_picture, "\pmc_shop\data\noimage_ca.paa"] select (_picture == "")] call _make;
            ["PMCS_TextBold", [0.465, _y + 0.012, 0.33, 0.032], _group, "tech", _target call _weaponName, 0.021] call _make;
            ["PMCS_Text", [0.465, _y + 0.044, 0.33, 0.026], _group, "tech", format ["%1 · %2", _kind, _op], 0.015, ["grey", "orangeDark"] select _accent] call _make;
            // Cost: the money (when there is any), then each item as have / need, red where short.
            private _short = _price > _balance;
            private _cost = [];
            if (_price > 0 || {_needs isEqualTo []}) then {
                _cost pushBack format ["<t font='RobotoCondensedBold' color='%1'>%2</t>", ["#2f5f2a", "#9e291f"] select (_price > _balance), _price call _money];
            };
            {
                _x params ["_label", "_have", "_need"];
                private _missing = _have < _need;
                if (_missing) then {_short = true};
                _cost pushBack format ["<t color='%1'>%2 %3/%4</t>", ["#4a5056", "#9e291f"] select _missing, _label, _have, _need];
            } forEach _needs;
            ["PMCS_Struct", [0.465, _y + 0.072, 0.33, 0.035], _group, "tech", _cost joinString "   ", 0.017] call _make;
            if (_next > 0) then {["PMCS_Text", [0.465, _y + 0.108, 0.33, 0.024], _group, "tech", format [localize "STR_PMCS_TECH_NEXT", _next], 0.014, "grey"] call _make};
            private _isArmed = (_armed select 0) == _key && {diag_tickTime - (_armed select 1) < 5};
            private _button = [["PMCS_Button", [0.81, _y + 0.05, 0.165, 0.05], _group, "tech",
                [localize "STR_PMCS_TECH_DO", format [localize "STR_PMCS_TECH_CONFIRM", _price call _money]] select _isArmed, 0.018, "white", ["orangeDark", "red"] select _isArmed] call _make,
                "upgrade", [_key]] call _click;
            _button ctrlEnable (!_short && {!_busy});
            if (_short) then {["PMCS_TextCenter", [0.81, _y + 0.104, 0.165, 0.024], _group, "tech", localize "STR_PMCS_TECH_SHORT", 0.014, "red"] call _make};
        } forEach _entries;
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
        private _slot = PMCS_ui getOrDefault ["techSlot", 0];
        if (_slot == 3) then {
            [player, PMCS_ui get "terminal", PMCS_ui get "account", _key] remoteExecCall ["PMCS_fnc_gearUpgrade", 2];
        } else {
            [player, PMCS_ui get "terminal", PMCS_ui get "account", _slot, _key] remoteExecCall ["PMCS_fnc_upgrade", 2];
        };
        ["toast", [localize "STR_PMCS_TECH_WORKING"]] call PMCS_fnc_ui;
        ["body"] call PMCS_fnc_uiTech;
    };
};
