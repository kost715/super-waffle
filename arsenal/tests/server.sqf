// Server-side arsenal checks in SQF-VM: stock, sessions, permissions, containers,
// persistence and disconnects. The shipped functions run unchanged through the
// opcode adapter in vm_compat.sqf; the arsenal display itself is not exercised.
call compile preprocessFileLineNumbers "tests/vm_compat.sqf";
TEST_count = 0;
TEST_fnc_assert = {
    params ["_ok", "_label"];
    if (!_ok) then {diag_log ("TEST_FAIL: " + _label); exitcode__ 1};
    TEST_count = TEST_count + 1;
    diag_log ("TEST_PASS: " + _label);
};
{
    missionNamespace setVariable ["PMCA_fnc_" + _x, ("pmc_arsenal/Server/fn_" + _x + ".sqf") call TEST_fnc_load];
} forEach ["serverInit", "serverLoad", "registerStorage", "storageAdd", "storageItems", "storageList", "allowedTabs",
    "itemKey", "loadoutItems", "cargoItems", "broadcast", "preview", "commit", "restoreCargo", "save", "requestOwner",
    "unlock", "boxCargo", "boxRestore", "boxScan", "boxLoad", "debugLoad", "moduleStorage", "stockFile", "exportStock",
    "stockRows", "zeusCaller", "zeusStock", "zeusStockId", "zeusEdit"];
PMCA_fnc_moduleZeusStock = "pmc_arsenal/Client/fn_moduleZeusStock.sqf" call TEST_fnc_load;
PMCA_fnc_stockReceive = "pmc_arsenal/Client/fn_stockReceive.sqf" call TEST_fnc_load;
PMCA_fnc_stockUi = {TEST_stockDraws = (missionNamespace getVariable ["TEST_stockDraws", 0]) + 1};
PMCA_fnc_moduleDebugLoad = "pmc_arsenal/Client/fn_moduleDebugLoad.sqf" call TEST_fnc_load;
PMCA_fnc_settings = "pmc_arsenal/Init/fn_settings.sqf" call TEST_fnc_load;
{
    missionNamespace setVariable ["PMCA_fnc_" + _x, ("pmc_arsenal/JNA/fn_" + _x + ".sqf") call TEST_fnc_load];
} forEach ["arsenal_itemType", "arsenal_requestOpen", "arsenal_requestClose", "arsenal_cargoToArsenal"];

// Engine library functions that need the full game config.
BIS_fnc_itemType = {["Weapon", getText (configFile >> "CfgWeapons" >> _this >> "TEST_itemType")]};
BIS_fnc_baseWeapon = {
    private _base = getText (configFile >> "CfgWeapons" >> _this >> "baseWeapon");
    if (_base == "") then {_this} else {_base}
};
BIS_fnc_basicBackpack = {_this};
// CBA settings: record each setting and apply its default, as CBA does on a fresh server.
TEST_settings = [];
CBA_fnc_addSetting = {
    params ["_name", "_type", "_title", "_category", "_value", ["_global", 0], ["_script", {}]];
    TEST_settings pushBack [_name, _type, _category, _value, _global, _script];
    missionNamespace setVariable [_name, if (_type == "LIST") then {(_value select 0) select (_value select 2)} else {_value}];
};
// The display is client-side; the server only messages it. Class lists are preset
// so itemType never needs the Virtual Arsenal preload.
PMCA_fnc_arsenal = {};
bis_fnc_arsenal_data = [];
for "_i" from 0 to 26 do {bis_fnc_arsenal_data pushBack []};

TEST_mag = "30Rnd_65x39_caseless_mag";
TEST_emptyLoadout = {[[], [], [], ["U_B_CombatUniform_mcam", [["FirstAidKit", 1]]], [], [], "", "", [], ["ItemMap", "", "", "ItemCompass", "ItemWatch", ""]]};
TEST_rifleLoadout = {
    params [["_rounds", 30], ["_spare", []]];
    private _l = call TEST_emptyLoadout;
    _l set [0, ["arifle_MX_F", "", "", "", [TEST_mag, _rounds], [], ""]];
    ((_l select 3) select 1) append _spare;
    _l
};
TEST_fnc_unit = {
    params ["_owner", "_pos"];
    private _u = "B_Soldier_F" createVehicle _pos;
    _u setPos _pos;
    _u setVariable ["TEST_class", "B_Soldier_F"];
    _u setVariable ["TEST_owner", _owner];
    _u setVariable ["TEST_loadout", call TEST_emptyLoadout];
    _u
};
TEST_fnc_crate = {
    params ["_pos", ["_class", "Box_NATO_Ammo_F"]];
    private _c = _class createVehicle _pos;
    _c setPos _pos;
    _c setVariable ["TEST_class", _class];
    _c
};
TEST_fnc_as = {TEST_isRemoteExecuted = true; TEST_remoteOwner = _this};
TEST_fnc_stock = {
    params ["_class", ["_id", "base"]];
    private _row = ([_id] call PMCA_fnc_storageItems) select {(_x select 0) == _class};
    if (_row isEqualTo []) then {0} else {(_row select 0) select 1}
};
TEST_fnc_sent = {
    params ["_fn", ["_mode", ""], ["_target", -1]];
    TEST_messages select {
        private _remote = _x select 1;
        (_remote select 0) == _fn && {_target == -1 || {(_remote select 1) isEqualTo _target}} && {
            _mode == "" || {((_x select 0) param [0, ""]) isEqualTo _mode}}
    }
};
TEST_fnc_open = {
    params ["_unit", "_owner", ["_kind", "arsenal"], ["_container", objNull], ["_object", TEST_box]];
    _owner call TEST_fnc_as;
    [_unit, _object, _kind, _container, _unit getVariable ["TEST_loadout", []]] call PMCA_fnc_arsenal_requestOpen;
};
TEST_fnc_close = {
    params ["_owner", "_claim"];
    _owner call TEST_fnc_as;
    [_claim] call PMCA_fnc_arsenal_requestClose;
};
TEST_fnc_fresh = {
    PMCA_storages = nil;
    PMCA_ready = nil;
    PMCA_debugMode = false;
    PMCA_unlockThreshold = 0;
    PMCA_accessMode = 0;
    profileNamespace setVariable ["PMCA_boxes_v1", nil];
    PMCA_sessions = nil;
    PMCA_accessHandler = nil;
    PMCA_itemTypes = nil;
    profileNamespace setVariable ["PMCA_storages_v1", nil];
    TEST_isRemoteExecuted = false;
    TEST_remoteOwner = 2;
    TEST_messages = [];
    TEST_onSleep = {};
    TEST_box = [[0, 0, 0]] call TEST_fnc_crate;
    TEST_unit = [3, [2, 0, 0]] call TEST_fnc_unit;
    TEST_other = [5, [0, 2, 0]] call TEST_fnc_unit;
    [TEST_box, "base", [["items", [["arifle_MX_F", 2], [TEST_mag, 3], ["HandGrenade", 2], ["U_B_CombatUniform_mcam", -1],
        ["optic_Aco", 1], ["launch_RPG32_F", 1]]]]] call PMCA_fnc_registerStorage;
    TEST_messages = [];
};

// --- Registration and stock API -------------------------------------------
call TEST_fnc_fresh;
[(TEST_box getVariable ["PMCA_storage", ""]) == "base", "registerStorage tags the object"] call TEST_fnc_assert;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2, "initial weapons are counted in pieces"] call TEST_fnc_assert;
[([TEST_mag] call TEST_fnc_stock) == 90, "initial magazines are stored as rounds"] call TEST_fnc_assert;
[(["U_B_CombatUniform_mcam"] call TEST_fnc_stock) == -1, "amount -1 is unlimited"] call TEST_fnc_assert;
[PMCA_dirty, "new stock marks the storages for saving"] call TEST_fnc_assert;
// SQF-VM config lookups are case-sensitive (Arma's are not), so only the preset mapping is checked.
[(["arifle_MX_ACO_F"] call PMCA_fnc_itemKey) == "arifle_MX_F", "preset weapons map to the base class"] call TEST_fnc_assert;
private _added = ["base", [["Nope_Item", 1], ["FirstAidKit", 1.5], ["FirstAidKit", 0], ["FirstAidKit", 2]]] call PMCA_fnc_storageAdd;
[_added == 1 && {(["FirstAidKit"] call TEST_fnc_stock) == 2}, "storageAdd skips unknown classes and bad amounts"] call TEST_fnc_assert;
[TEST_box, "base", [["items", [["arifle_MX_F", 50]]]]] call PMCA_fnc_registerStorage;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2, "initial items apply only to a new storage"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_box, "base"] call PMCA_fnc_registerStorage;
private _box2 = [[0, 1, 0]] call TEST_fnc_crate;
[_box2, "base"] call PMCA_fnc_registerStorage;
private _init = ["PMCA_fnc_arsenal_init"] call TEST_fnc_sent;
[count _init == 1 && {(((_init select 0) select 1) select 2) isEqualTo _box2}, "actions are sent once per object to every client with JIP"] call TEST_fnc_assert;
[(TEST_box getVariable "PMCA_boxKey") == "base#1" && {(_box2 getVariable "PMCA_boxKey") == "base#2"}, "objects of a storage are numbered in registration order"] call TEST_fnc_assert;

// --- Taking and returning --------------------------------------------------
call TEST_fnc_fresh;
[TEST_unit, 3] call TEST_fnc_open;
private _open = ["PMCA_fnc_arsenal", "Open", 3] call TEST_fnc_sent;
[count _open == 1, "open request answers the requesting client"] call TEST_fnc_assert;
private _list = (((_open select 0) select 0) select 1) select 0;
[((_list select 0) select {(_x select 0) == "arifle_MX_F"}) isEqualTo [["arifle_MX_F", 2]] && {
    ((_list select 26) select {(_x select 0) == TEST_mag}) isEqualTo [[TEST_mag, 90]]}, "open list carries stock per tab"] call TEST_fnc_assert;
private _session = PMCA_sessions get 3;
[!([_session, ["opening", false]] call TEST_fnc_getDefault) && {(_session get "kind") == "arsenal"}, "session is ready after the snapshot"] call TEST_fnc_assert;
TEST_unit setVariable ["TEST_loadout", [30, [[TEST_mag, 1, 30]]] call TEST_rifleLoadout];
[3, [30, [[TEST_mag, 1, 30]]] call TEST_rifleLoadout] call TEST_fnc_close;
[!(3 in PMCA_sessions), "close settles and ends the session"] call TEST_fnc_assert;
[(["arifle_MX_F"] call TEST_fnc_stock) == 1 && {([TEST_mag] call TEST_fnc_stock) == 30}, "taken rifle and two magazines leave stock"] call TEST_fnc_assert;
[(["PMCA_fnc_applyLoadout"] call TEST_fnc_sent) isEqualTo [], "a covered take keeps the loadout"] call TEST_fnc_assert;

// 13 rounds fired outside the arsenal; the spare magazine goes back first.
TEST_unit setVariable ["TEST_loadout", [17, [[TEST_mag, 1, 30]]] call TEST_rifleLoadout];
[TEST_unit, 3] call TEST_fnc_open;
TEST_unit setVariable ["TEST_loadout", [17] call TEST_rifleLoadout];
[3, [17] call TEST_rifleLoadout] call TEST_fnc_close;
[([TEST_mag] call TEST_fnc_stock) == 60, "a returned full magazine adds 30 rounds"] call TEST_fnc_assert;
[TEST_unit, 3] call TEST_fnc_open;
TEST_unit setVariable ["TEST_loadout", call TEST_emptyLoadout];
[3, call TEST_emptyLoadout] call TEST_fnc_close;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2 && {([TEST_mag] call TEST_fnc_stock) == 77}, "returned rifle and partial magazine go back by rounds"] call TEST_fnc_assert;

// Unlimited items stay unlimited both ways.
[TEST_unit, 3] call TEST_fnc_open;
private _two = call TEST_emptyLoadout;
_two set [4, []];
_two set [5, ["B_AssaultPack_rgr", [["U_B_CombatUniform_mcam", 1]]]];
["base", [["B_AssaultPack_rgr", 1]]] call PMCA_fnc_storageAdd;
TEST_unit setVariable ["TEST_loadout", _two];
[3, _two] call TEST_fnc_close;
[(["U_B_CombatUniform_mcam"] call TEST_fnc_stock) == -1 && {(["B_AssaultPack_rgr"] call TEST_fnc_stock) == 0}, "unlimited stock is not reduced; a limited one is"] call TEST_fnc_assert;

// --- Not enough stock or no permission: the loadout is restored -------------
call TEST_fnc_fresh;
[TEST_unit, 3] call TEST_fnc_open;
private _greedy = [30, [[TEST_mag, 3, 30]]] call TEST_rifleLoadout;
TEST_unit setVariable ["TEST_loadout", _greedy];
[3, _greedy] call TEST_fnc_close;
private _restore = ["PMCA_fnc_applyLoadout", "", 3] call TEST_fnc_sent;
[count _restore == 1 && {(((_restore select 0) select 0) select 0) isEqualTo (call TEST_emptyLoadout)}, "120 rounds against 90 in stock restores the opening loadout"] call TEST_fnc_assert;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2 && {([TEST_mag] call TEST_fnc_stock) == 90}, "a reverted session changes no stock"] call TEST_fnc_assert;
private _err = ["PMCA_fnc_notify", "STR_PMCA_ERR_STOCK", 3] call TEST_fnc_sent;
[count _err == 1 && {((((_err select 0) select 0) select 1) select 0) == "6.5 mm 30Rnd Mag"}, "the player is told which item ran out"] call TEST_fnc_assert;

call TEST_fnc_fresh;
PMCA_accessHandler = {params ["_unit", "_id"]; if (_unit isEqualTo TEST_other) then {false} else {["equipment"]}};
TEST_unit setVariable ["TEST_loadout", call TEST_emptyLoadout];
[TEST_unit, 3] call TEST_fnc_open;
private _tabsList = ((((["PMCA_fnc_arsenal", "Open", 3] call TEST_fnc_sent) select 0) select 0) select 1) select 0;
[(_tabsList select 0) isEqualTo [] && {(_tabsList select 3) isEqualTo [["U_B_CombatUniform_mcam", -1]]}, "the list shows only permitted categories"] call TEST_fnc_assert;
TEST_unit setVariable ["TEST_loadout", [30] call TEST_rifleLoadout];
[3, [30] call TEST_rifleLoadout] call TEST_fnc_close;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2 && {count (["PMCA_fnc_applyLoadout", "", 3] call TEST_fnc_sent) == 1}, "a weapon taken without the weapons category is reverted"] call TEST_fnc_assert;
// A rifle obtained elsewhere may still be returned.
TEST_messages = [];
TEST_unit setVariable ["TEST_loadout", [30] call TEST_rifleLoadout];
[TEST_unit, 3] call TEST_fnc_open;
TEST_unit setVariable ["TEST_loadout", call TEST_emptyLoadout];
[3, call TEST_emptyLoadout] call TEST_fnc_close;
[(["PMCA_fnc_applyLoadout"] call TEST_fnc_sent) isEqualTo [] && {(["arifle_MX_F"] call TEST_fnc_stock) == 3} && {
    ([TEST_mag] call TEST_fnc_stock) == 120}, "returning needs no category"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_other, 5] call TEST_fnc_open;
[!(5 in PMCA_sessions) && {count (["PMCA_fnc_notify", "STR_PMCA_ERR_NO_ACCESS", 5] call TEST_fnc_sent) == 1} && {
    count (["PMCA_fnc_arsenal", "Abort", 5] call TEST_fnc_sent) == 1}, "a denied unit gets no session and the loading screen is closed"] call TEST_fnc_assert;

// --- What the client reports cannot create stock ---------------------------
// Opening: the snapshot is the server's view, whatever the client claims.
call TEST_fnc_fresh;
TEST_unit setVariable ["TEST_loadout", call TEST_emptyLoadout];
3 call TEST_fnc_as;
[TEST_unit, TEST_box, "arsenal", objNull, [30] call TEST_rifleLoadout] call PMCA_fnc_arsenal_requestOpen;
[((PMCA_sessions get 3) get "before") isEqualTo ([call TEST_emptyLoadout] call PMCA_fnc_loadoutItems) && {TEST_sleeps > 0},
    "the opening snapshot waits for the claim but records the server's view"] call TEST_fnc_assert;
// Closing with a claim of having returned a rifle the server still sees: no return.
TEST_unit setVariable ["TEST_loadout", [30] call TEST_rifleLoadout];
TEST_messages = [];
[3, call TEST_emptyLoadout] call TEST_fnc_close;
[(["arifle_MX_F"] call TEST_fnc_stock) == 1 && {([TEST_mag] call TEST_fnc_stock) == 60}, "a claimed return the server does not see is charged as taken"] call TEST_fnc_assert;
// Dropped before the server saw it: the claim still counts as taken.
[TEST_unit, 3] call TEST_fnc_open;
private _t0 = TEST_realTime;
[3, [30, [[TEST_mag, 1, 30]]] call TEST_rifleLoadout] call TEST_fnc_close;
[([TEST_mag] call TEST_fnc_stock) == 30 && {TEST_realTime - _t0 >= 5}, "an item the server never saw is charged after the 5 s wait"] call TEST_fnc_assert;
// Late network update: the server still sees the rifle when the close arrives.
[TEST_unit, 3] call TEST_fnc_open;
TEST_onSleep = {TEST_unit setVariable ["TEST_loadout", call TEST_emptyLoadout]};
private _t1 = TEST_realTime;
[3, call TEST_emptyLoadout] call TEST_fnc_close;
TEST_onSleep = {};
[(["arifle_MX_F"] call TEST_fnc_stock) == 2 && {([TEST_mag] call TEST_fnc_stock) == 60} && {TEST_realTime - _t1 < 1},
    "a return that reaches the server during the wait is credited"] call TEST_fnc_assert;

// --- Other players see picks at once; counts are corrected on settlement ----
call TEST_fnc_fresh;
[TEST_unit, 3] call TEST_fnc_open;
[TEST_other, 5] call TEST_fnc_open;
TEST_messages = [];
3 call TEST_fnc_as;
[[[0, "arifle_MX_F", 1]], false] call PMCA_fnc_preview;
private _seen = ["PMCA_fnc_arsenal", "UpdateItemRemove"] call TEST_fnc_sent;
[count _seen == 2 && {(((_seen select 0) select 0) select 1) isEqualTo [0, "arifle_MX_F", 1, true]}, "a pick is shown to every session of the storage"] call TEST_fnc_assert;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2, "a preview never changes stock"] call TEST_fnc_assert;
TEST_messages = [];
[3, call TEST_emptyLoadout] call TEST_fnc_close;
private _fix = ["PMCA_fnc_arsenal", "UpdateItemAdd", 5] call TEST_fnc_sent;
[count _fix == 1 && {(((_fix select 0) select 0) select 1) isEqualTo [0, "arifle_MX_F", 1, true]}, "a pick that was put back is corrected for the others"] call TEST_fnc_assert;
TEST_messages = [];
7 call TEST_fnc_as;
[[[0, "arifle_MX_F", 1]], false] call PMCA_fnc_preview;
[TEST_messages isEqualTo [], "a preview without a session is ignored"] call TEST_fnc_assert;
[TEST_other, 5] call TEST_fnc_open;
[(["PMCA_fnc_arsenal", "Open", 5] call TEST_fnc_sent) isNotEqualTo [] && {TEST_box getVariable ["PMCA_storage", ""] == "base"},
    "an unclosed session is settled when the same client opens again"] call TEST_fnc_assert;
// Restricted tabs are not shown in broadcasts either.
PMCA_accessHandler = {["equipment"]};
[TEST_unit, 3] call TEST_fnc_open;
TEST_messages = [];
["base", [["arifle_MX_F", 1], ["U_B_CombatUniform_mcam", 1]]] call PMCA_fnc_storageAdd;
private _toThree = ["PMCA_fnc_arsenal", "UpdateItemAdd", 3] call TEST_fnc_sent;
[count _toThree == 1 && {((((_toThree select 0) select 0) select 1) select 1) == "U_B_CombatUniform_mcam"}, "broadcasts skip tabs the session may not take from"] call TEST_fnc_assert;
PMCA_accessHandler = nil;

// --- Requests that must be refused -----------------------------------------
call TEST_fnc_fresh;
5 call TEST_fnc_as;
[TEST_unit, TEST_box, "arsenal", objNull, []] call PMCA_fnc_arsenal_requestOpen;
[count PMCA_sessions == 0 && {TEST_messages isEqualTo []}, "a client cannot open a session for someone else's unit"] call TEST_fnc_assert;
TEST_unit setPos [20, 0, 0];
[TEST_unit, 3] call TEST_fnc_open;
[!(3 in PMCA_sessions) && {count (["PMCA_fnc_notify", "STR_PMCA_ERR_TOO_FAR", 3] call TEST_fnc_sent) == 1}, "a unit farther than 6 m is refused"] call TEST_fnc_assert;
TEST_unit setPos [2, 0, 0];
private _plain = [[1, 1, 0], "Land_Wall_F"] call TEST_fnc_crate;
[TEST_unit, 3, "arsenal", objNull, _plain] call TEST_fnc_open;
[!(3 in PMCA_sessions) && {count (["PMCA_fnc_notify", "STR_PMCA_ERR_NO_STORAGE", 3] call TEST_fnc_sent) == 1}, "an object without storage is refused"] call TEST_fnc_assert;
3 call TEST_fnc_as;
[[]] call PMCA_fnc_arsenal_requestClose;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2, "closing without a session changes nothing"] call TEST_fnc_assert;

// --- Container sessions -------------------------------------------------------
call TEST_fnc_fresh;
TEST_crate = [[10, 0, 0]] call TEST_fnc_crate;
TEST_crate setVariable ["TEST_mags", [[TEST_mag, 30], [TEST_mag, 12]]];
TEST_crate setVariable ["TEST_items", [["FirstAidKit", 1]]];
[TEST_unit, 3, "container", TEST_crate] call TEST_fnc_open;
private _cOpen = ["PMCA_fnc_arsenal", "Open", 3] call TEST_fnc_sent;
[count _cOpen == 1 && {((((_cOpen select 0) select 0) select 1) select 2) == "container"} && {TEST_crate getVariable ["TEST_locked", false]},
    "a container session locks the container's inventory"] call TEST_fnc_assert;
[TEST_other, 5, "container", TEST_crate] call TEST_fnc_open;
[!(5 in PMCA_sessions) && {count (["PMCA_fnc_notify", "STR_PMCA_ERR_CONTAINER", 5] call TEST_fnc_sent) == 1}, "a container in use is refused"] call TEST_fnc_assert;
// The container arsenal swapped the partial magazine for a rifle.
TEST_crate setVariable ["TEST_mags", [[TEST_mag, 30]]];
TEST_crate setVariable ["TEST_weapons", [["arifle_MX_F", "", "", "", [], [], ""]]];
private _claim = [];
for "_i" from 0 to 26 do {_claim pushBack []};
(_claim select 0) pushBack ["arifle_MX_F", 1];
(_claim select 26) pushBack [TEST_mag, 30];
(_claim select 24) pushBack ["FirstAidKit", 1];
[3, _claim] call TEST_fnc_close;
[(["arifle_MX_F"] call TEST_fnc_stock) == 1 && {([TEST_mag] call TEST_fnc_stock) == 102} && {!(TEST_crate getVariable ["TEST_locked", true])},
    "a container session settles and unlocks"] call TEST_fnc_assert;
// Taking more than stock refills the container as it was at opening.
[TEST_unit, 3, "container", TEST_crate] call TEST_fnc_open;
// Three rifles in the crate: two more than before, with one in stock.
TEST_crate setVariable ["TEST_weapons", [0, 1, 2] apply {["arifle_MX_F", "", "", "", [], [], ""]}];
TEST_crate setVariable ["TEST_mags", []];
[3, nil] call TEST_fnc_close;
[(["arifle_MX_F"] call TEST_fnc_stock) == 1 && {(TEST_crate getVariable ["TEST_mags", []]) isEqualTo [[TEST_mag, 30]]} && {
    count (TEST_crate getVariable ["TEST_weapons", []]) == 1} && {!(TEST_crate getVariable ["TEST_locked", true])},
    "an uncovered container take restores the container"] call TEST_fnc_assert;
private _man = [8, [3, 0, 0]] call TEST_fnc_unit;
[TEST_unit, 3, "container", _man] call TEST_fnc_open;
[!(3 in PMCA_sessions), "a unit is not a container"] call TEST_fnc_assert;
private _far = [[70, 0, 0]] call TEST_fnc_crate;
[TEST_unit, 3, "container", _far] call TEST_fnc_open;
[!(3 in PMCA_sessions) && {!(_far getVariable ["TEST_locked", false])}, "a container farther than 50 m is refused"] call TEST_fnc_assert;

// --- Emptying a crate into the storage ----------------------------------------
call TEST_fnc_fresh;
private _loot = [[5, 0, 0]] call TEST_fnc_crate;
private _pack = "B_AssaultPack_rgr" createVehicle [5, 0, 0];
_pack setVariable ["TEST_items", [["optic_Aco", 2]]];
_loot setVariable ["TEST_mags", [[TEST_mag, 20], ["HandGrenade", 1]]];
_loot setVariable ["TEST_weapons", [["arifle_MX_ACO_F", "", "", "optic_Aco", [TEST_mag, 30], [], ""]]];
_loot setVariable ["TEST_packs", [["B_AssaultPack_rgr", 1]]];
_loot setVariable ["TEST_containers", [["B_AssaultPack_rgr", _pack]]];
3 call TEST_fnc_as;
[TEST_unit, TEST_box, _loot] call PMCA_fnc_arsenal_cargoToArsenal;
[(["arifle_MX_F"] call TEST_fnc_stock) == 3 && {(["optic_Aco"] call TEST_fnc_stock) == 4} && {([TEST_mag] call TEST_fnc_stock) == 140} && {
    (["HandGrenade"] call TEST_fnc_stock) == 3} && {(["B_AssaultPack_rgr"] call TEST_fnc_stock) == 1},
    "crate contents, attachments and backpack contents move into stock"] call TEST_fnc_assert;
[([_loot] call PMCA_fnc_cargoItems) isEqualTo createHashMap, "the crate is emptied"] call TEST_fnc_assert;
private _locked = [[5, 0, 0]] call TEST_fnc_crate;
_locked setVariable ["TEST_items", [["FirstAidKit", 3]]];
_locked setVariable ["TEST_locked", true];
[TEST_unit, TEST_box, _locked] call PMCA_fnc_arsenal_cargoToArsenal;
[(["FirstAidKit"] call TEST_fnc_stock) == 0 && {count (_locked getVariable ["TEST_items", []]) == 1}, "a crate locked by a session is not emptied"] call TEST_fnc_assert;

// --- Persistence ----------------------------------------------------------------
call TEST_fnc_fresh;
private _temp = [[0, 3, 0]] call TEST_fnc_crate;
[_temp, "mission", [["items", [["FirstAidKit", 5]]], ["persistent", false]]] call PMCA_fnc_registerStorage;
TEST_profilesSaved = 0;
[call PMCA_fnc_save && {TEST_profilesSaved == 1} && {!PMCA_dirty}, "save writes the profile"] call TEST_fnc_assert;
private _saved = profileNamespace getVariable ["PMCA_storages_v1", []];
[(_saved select 0) == 1 && {count (_saved select 1) == 1} && {((_saved select 1) select 0) select 0 == "base"}, "non-persistent storages are not saved"] call TEST_fnc_assert;
PMCA_storages = nil;
PMCA_sessions = nil;
call PMCA_fnc_serverLoad;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2 && {([TEST_mag] call TEST_fnc_stock) == 90} && {(["U_B_CombatUniform_mcam"] call TEST_fnc_stock) == -1} && {
    !("mission" in PMCA_storages)}, "stock survives a restart"] call TEST_fnc_assert;
[TEST_box, "base", [["items", [["arifle_MX_F", 9]]], ["categories", ["weapons"]]]] call PMCA_fnc_registerStorage;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2 && {((PMCA_storages get "base") get "categories") isEqualTo ["weapons"]}, "a loaded storage keeps its stock and takes mission categories"] call TEST_fnc_assert;
private _bad = [1, [["base", [["arifle_MX_F", 1.5]]]]];
profileNamespace setVariable ["PMCA_storages_v1", _bad];
PMCA_storages = nil;
call PMCA_fnc_serverLoad;
[PMCA_saveBlocked && {count PMCA_storages == 0}, "damaged saved data is not loaded"] call TEST_fnc_assert;
[TEST_box, "base", [["items", [["arifle_MX_F", 1]]]]] call PMCA_fnc_registerStorage;
[!(call PMCA_fnc_save) && {(profileNamespace getVariable "PMCA_storages_v1") isEqualTo _bad}, "damaged saved data is never overwritten"] call TEST_fnc_assert;
profileNamespace setVariable ["PMCA_storages_v1", nil];

// --- Disconnects and server init -------------------------------------------------
call TEST_fnc_fresh;
TEST_missionHandlers = [];
TEST_deferSpawn = true;
call PMCA_fnc_serverInit;
TEST_deferSpawn = false;
private _handler = {params ["_name"]; ((TEST_missionHandlers select {(_x select 0) == _name}) select 0) select 1};
[count TEST_missionHandlers == 3 && {count TEST_deferred == 1}, "server init installs disconnect, end and periodic save handlers"] call TEST_fnc_assert;
TEST_deferred = [];
[TEST_unit, 3] call TEST_fnc_open;
TEST_unit setVariable ["TEST_loadout", [30] call TEST_rifleLoadout];
TEST_isRemoteExecuted = false;
private _keep = [TEST_unit, 0, "uid", "name"] call (["HandleDisconnect"] call _handler);
[!_keep && {!(3 in PMCA_sessions)} && {(["arifle_MX_F"] call TEST_fnc_stock) == 1}, "a leaving player's take is settled from the server's view"] call TEST_fnc_assert;
TEST_crate = [[10, 0, 0]] call TEST_fnc_crate;
TEST_crate setVariable ["TEST_items", [["FirstAidKit", 2]]];
[TEST_unit, 3, "container", TEST_crate] call TEST_fnc_open;
TEST_crate setVariable ["TEST_items", []];
TEST_crate setVariable ["TEST_weapons", [["arifle_MX_F", "", "", "", [], [], ""]]];
TEST_isRemoteExecuted = false;
[0, "uid", "name", false, 3] call (["PlayerDisconnected"] call _handler);
[!(3 in PMCA_sessions) && {(["arifle_MX_F"] call TEST_fnc_stock) == 1} && {(TEST_crate getVariable ["TEST_items", []]) isEqualTo [["FirstAidKit", 2]]} && {
    (TEST_crate getVariable ["TEST_weapons", []]) isEqualTo []} && {!(TEST_crate getVariable ["TEST_locked", true])},
    "an open container session is undone when its player leaves"] call TEST_fnc_assert;
PMCA_dirty = true;
TEST_profilesSaved = 0;
[] call (["MPEnded"] call _handler);
[TEST_profilesSaved == 1, "mission end saves pending changes"] call TEST_fnc_assert;

// --- CBA settings ------------------------------------------------------------------
TEST_settings = [];
call PMCA_fnc_settings;
private _names = TEST_settings apply {_x select 0};
[count TEST_settings == 19 && {"PMCA_access_guer_launchers" in _names} && {(TEST_settings findIf {(_x select 4) != 1}) < 0},
    "settings: debug, threshold, access mode and 16 side checkboxes, all forced by the server"] call TEST_fnc_assert;
[!PMCA_debugMode && {PMCA_unlockThreshold == 0} && {PMCA_accessMode == 0} && {PMCA_access_east_explosives},
    "defaults: debug off, nothing turns unlimited, everyone may take everything"] call TEST_fnc_assert;
private _threshold = TEST_settings select {(_x select 0) == "PMCA_unlockThreshold"} select 0;
[((_threshold select 3) select 0) isEqualTo [0, 5, 20, 50], "threshold choices are never, 5, 20 and 50"] call TEST_fnc_assert;

// --- Items turn unlimited at the threshold -------------------------------------
call TEST_fnc_fresh;
PMCA_unlockThreshold = 5;
["base", [["FirstAidKit", 4]]] call PMCA_fnc_storageAdd;
[(["FirstAidKit"] call TEST_fnc_stock) == 4, "below the threshold an item stays limited"] call TEST_fnc_assert;
["base", [[TEST_mag, 1]]] call PMCA_fnc_storageAdd;
[([TEST_mag] call TEST_fnc_stock) == 120, "120 rounds are four magazines, below the threshold"] call TEST_fnc_assert;
[TEST_unit, 3] call TEST_fnc_open;
TEST_messages = [];
["base", [["FirstAidKit", 1], [TEST_mag, 1]]] call PMCA_fnc_storageAdd;
[(["FirstAidKit"] call TEST_fnc_stock) == -1 && {([TEST_mag] call TEST_fnc_stock) == -1}, "five pieces or five full magazines turn unlimited"] call TEST_fnc_assert;
[count (["PMCA_fnc_arsenal", "UpdateItemAdd", 3] call TEST_fnc_sent select {(((_x select 0) select 1) select 2) == -1}) == 2, "open arsenals are told the item is unlimited"] call TEST_fnc_assert;
[3, call TEST_emptyLoadout] call TEST_fnc_close;
["base", [["arifle_MX_F", 2]]] call PMCA_fnc_storageAdd;
TEST_unit setVariable ["TEST_loadout", [30] call TEST_rifleLoadout];
[TEST_unit, 3] call TEST_fnc_open;
TEST_unit setVariable ["TEST_loadout", call TEST_emptyLoadout];
[3, call TEST_emptyLoadout] call TEST_fnc_close;
[(["arifle_MX_F"] call TEST_fnc_stock) == -1, "a returned item that reaches the threshold turns unlimited"] call TEST_fnc_assert;
[TEST_unit, 3] call TEST_fnc_open;
TEST_unit setVariable ["TEST_loadout", [30] call TEST_rifleLoadout];
[3, [30] call TEST_rifleLoadout] call TEST_fnc_close;
[(["arifle_MX_F"] call TEST_fnc_stock) == -1, "taking an unlimited item leaves it unlimited"] call TEST_fnc_assert;
PMCA_unlockThreshold = 0;
["base", [["optic_Aco", 60]]] call PMCA_fnc_storageAdd;
[(["optic_Aco"] call TEST_fnc_stock) == 61, "threshold off: stock is never unlimited"] call TEST_fnc_assert;
PMCA_unlockThreshold = 50;
[PMCA_unlockThreshold] call (_threshold select 5);
[(["optic_Aco"] call TEST_fnc_stock) == -1 && {(["HandGrenade"] call TEST_fnc_stock) == 2}, "changing the setting applies it to existing stock"] call TEST_fnc_assert;

// --- Access by side ------------------------------------------------------------------
call TEST_fnc_fresh;
TEST_settings = [];
call PMCA_fnc_settings;
PMCA_accessMode = 1;
{missionNamespace setVariable ["PMCA_access_west_" + _x, false]} forEach ["weapons", "launchers", "explosives"];
[TEST_unit, 3] call TEST_fnc_open;
private _westList = ((((["PMCA_fnc_arsenal", "Open", 3] call TEST_fnc_sent) select 0) select 0) select 1) select 0;
[(_westList select 0) isEqualTo [] && {(_westList select 3) isEqualTo [["U_B_CombatUniform_mcam", -1]]}, "BLUFOR sees only the categories ticked for BLUFOR"] call TEST_fnc_assert;
TEST_unit setVariable ["TEST_loadout", [30] call TEST_rifleLoadout];
[3, [30] call TEST_rifleLoadout] call TEST_fnc_close;
[(["arifle_MX_F"] call TEST_fnc_stock) == 2 && {count (["PMCA_fnc_applyLoadout", "", 3] call TEST_fnc_sent) == 1}, "a category not ticked for the side cannot be taken"] call TEST_fnc_assert;
TEST_other setVariable ["TEST_side", east];
TEST_messages = [];
[TEST_other, 5] call TEST_fnc_open;
[(["PMCA_fnc_arsenal", "Open", 5] call TEST_fnc_sent) isNotEqualTo [], "OPFOR keeps its own (default) categories"] call TEST_fnc_assert;
[5, call TEST_emptyLoadout] call TEST_fnc_close;
{missionNamespace setVariable ["PMCA_access_east_" + _x, false]} forEach ["weapons", "launchers", "explosives", "equipment"];
TEST_messages = [];
[TEST_other, 5] call TEST_fnc_open;
[!(5 in PMCA_sessions) && {count (["PMCA_fnc_notify", "STR_PMCA_ERR_NO_ACCESS", 5] call TEST_fnc_sent) == 1}, "a side with no category ticked cannot open the arsenal"] call TEST_fnc_assert;
PMCA_accessMode = 0;
[TEST_other, 5] call TEST_fnc_open;
[5 in PMCA_sessions, "mode everyone ignores the side checkboxes"] call TEST_fnc_assert;

// --- The arsenal object's own inventory is saved and restored --------------------
call TEST_fnc_fresh;
private _uniform = "U_B_CombatUniform_mcam";
TEST_box setVariable ["TEST_mags", [[TEST_mag, 30], [TEST_mag, 7]]];
TEST_box setVariable ["TEST_weapons", [["arifle_MX_F", "", "", "optic_Aco", [TEST_mag, 21], [], ""]]];
[TEST_box, ["FirstAidKit", 2]] call TEST_fnc_addItemCargo;
[TEST_box, [_uniform, 1]] call TEST_fnc_addItemCargo;
[TEST_box, ["B_AssaultPack_rgr", 1]] call TEST_fnc_addPackCargo;
private _inner = TEST_box getVariable "TEST_containers";
((_inner select 0) select 1) setVariable ["TEST_items", [["FirstAidKit", 1]]];
((_inner select 1) select 1) setVariable ["TEST_mags", [["HandGrenade", 1]]];
private _record = [TEST_box] call PMCA_fnc_boxCargo;
[(_record select 1) isEqualTo [["FirstAidKit", 2]] && {count (_record select 3) == 2}, "a uniform in the box is saved as a container, not as an item"] call TEST_fnc_assert;
[call PMCA_fnc_boxScan && {!(call PMCA_fnc_boxScan)}, "a changed inventory is detected once"] call TEST_fnc_assert;
call PMCA_fnc_save;
private _savedBoxes = profileNamespace getVariable ["PMCA_boxes_v1", []];
[(_savedBoxes select 1) isEqualTo [["base#1", _record]], "the inventory is saved under the storage key"] call TEST_fnc_assert;
// Restart: the mission box comes back with its Eden default inventory.
PMCA_storages = nil;
PMCA_ready = nil;
private _again = [[0, 0, 0]] call TEST_fnc_crate;
[_again, ["H_HelmetB", 3]] call TEST_fnc_addItemCargo;
[_again, "base"] call PMCA_fnc_registerStorage;
[(_again getVariable ["TEST_items", []]) isEqualTo [["H_HelmetB", 3]], "nothing is restored before mission objects are initialised"] call TEST_fnc_assert;
TEST_deferSpawn = true;
call PMCA_fnc_serverInit;
TEST_deferSpawn = false;
TEST_deferred = [];
[([_again] call PMCA_fnc_boxCargo) isEqualTo _record, "after init the box holds exactly what was saved: partial magazines, attachments, nested contents"] call TEST_fnc_assert;
private _late = [[0, 2, 0]] call TEST_fnc_crate;
PMCA_boxes set ["late#1", [[], [["FirstAidKit", 4]], [], []]];
[_late, "late"] call PMCA_fnc_registerStorage;
[(_late getVariable ["TEST_items", []]) isEqualTo [["FirstAidKit", 4]], "an object registered later is restored at once"] call TEST_fnc_assert;
[_late, "late"] call PMCA_fnc_registerStorage;
_late setVariable ["TEST_items", []];
[_late, "late"] call PMCA_fnc_registerStorage;
[(_late getVariable ["TEST_items", []]) isEqualTo [], "registering again does not restore twice"] call TEST_fnc_assert;
private _tempBox = [[0, 3, 0]] call TEST_fnc_crate;
[_tempBox, "mission", [["persistent", false]]] call PMCA_fnc_registerStorage;
[_tempBox, ["FirstAidKit", 1]] call TEST_fnc_addItemCargo;
call PMCA_fnc_boxScan;
[!("mission#1" in PMCA_boxes), "inventories of non-persistent storages are not saved"] call TEST_fnc_assert;
_again setDamage 1;
_again setVariable ["TEST_items", []];
[!(call PMCA_fnc_boxScan) && {(PMCA_boxes get "base#1") isEqualTo _record}, "a destroyed box keeps its last saved inventory"] call TEST_fnc_assert;
profileNamespace setVariable ["PMCA_boxes_v1", [1, [["base#1", [[["x", "bad"]], [], [], []]]]]];
PMCA_storages = nil;
call PMCA_fnc_serverLoad;
[PMCA_saveBlocked && {count PMCA_boxes == 0}, "damaged inventory records block saving like damaged stock"] call TEST_fnc_assert;
profileNamespace setVariable ["PMCA_boxes_v1", nil];

// --- Debug mode and the Zeus module ----------------------------------------------
call TEST_fnc_fresh;
PMCA_storages = nil;
PMCA_debugMode = true;
[TEST_box, "base", [["items", [["arifle_MX_F", 2]]]]] call PMCA_fnc_registerStorage;
[(["base"] call PMCA_fnc_storageItems) isEqualTo [], "in debug mode a new storage starts empty"] call TEST_fnc_assert;
private _depot = [[300, 0, 0]] call TEST_fnc_crate;
[_depot, "depot"] call PMCA_fnc_registerStorage;
private _source = [[60, 0, 0]] call TEST_fnc_crate;
_source setVariable ["TEST_weapons", [["arifle_MX_ACO_F", "", "", "optic_Aco", [TEST_mag, 30], [], ""]]];
[_source, ["B_AssaultPack_rgr", 1]] call TEST_fnc_addPackCargo;
(((_source getVariable "TEST_containers") select 0) select 1) setVariable ["TEST_mags", [["HandGrenade", 1]]];
private _before = [_source] call PMCA_fnc_boxCargo;
TEST_unit setVariable ["TEST_curator", TEST_box];
TEST_messages = [];
3 call TEST_fnc_as;
[TEST_unit, _source] call PMCA_fnc_debugLoad;
[(["arifle_MX_F"] call TEST_fnc_stock) == -1 && {(["optic_Aco"] call TEST_fnc_stock) == -1} && {([TEST_mag] call TEST_fnc_stock) == -1} && {
    (["HandGrenade"] call TEST_fnc_stock) == -1} && {(["B_AssaultPack_rgr"] call TEST_fnc_stock) == -1}, "everything in the box becomes unlimited in the nearest arsenal"] call TEST_fnc_assert;
[(["depot"] call PMCA_fnc_storageItems) isEqualTo [] && {([_source] call PMCA_fnc_boxCargo) isEqualTo _before} && {PMCA_dirty},
    "other arsenals and the box itself are untouched; the change is saved"] call TEST_fnc_assert;
private _loaded = ["PMCA_fnc_notify", "STR_PMCA_DEBUG_LOADED", 3] call TEST_fnc_sent;
[count _loaded == 1 && {(((_loaded select 0) select 0) select 1) isEqualTo [5, "base"]}, "Zeus is told how many items were loaded and where"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_unit, [[150, 0, 0]] call TEST_fnc_crate] call PMCA_fnc_debugLoad;
[count (["PMCA_fnc_notify", "STR_PMCA_ERR_DEBUG_FAR", 3] call TEST_fnc_sent) == 1, "a box farther than 100 m from any arsenal is refused"] call TEST_fnc_assert;
TEST_unit setVariable ["TEST_curator", objNull];
TEST_messages = [];
[TEST_unit, _source] call PMCA_fnc_debugLoad;
[TEST_messages isEqualTo [], "only a Zeus may load"] call TEST_fnc_assert;
TEST_unit setVariable ["TEST_curator", TEST_box];
PMCA_debugMode = false;
[TEST_unit, _source] call PMCA_fnc_debugLoad;
[count (["PMCA_fnc_notify", "STR_PMCA_ERR_DEBUG_OFF", 3] call TEST_fnc_sent) == 1, "the module does nothing while debug mode is off"] call TEST_fnc_assert;
// The Zeus side of the module: the box it was placed on goes to the server.
private _zeusLogic = "Logic" createVehicle [60, 0, 0];
_zeusLogic setVariable ["bis_fnc_curatorAttachObject_object", _source];
TEST_messages = [];
[_zeusLogic, [], true] call PMCA_fnc_moduleDebugLoad;
private _request = ["PMCA_fnc_debugLoad", "", 2] call TEST_fnc_sent;
[count _request == 1 && {((_request select 0) select 0) isEqualTo [player, _source]} && {isNull _zeusLogic}, "the placed module sends its box to the server and removes itself"] call TEST_fnc_assert;
private _remoteLogic = "Logic" createVehicle [60, 0, 0];
_remoteLogic setVariable ["TEST_local", false];
TEST_messages = [];
[_remoteLogic, [], true] call PMCA_fnc_moduleDebugLoad;
[TEST_messages isEqualTo [], "other machines ignore the module"] call TEST_fnc_assert;

// --- Eden module --------------------------------------------------------------------
call TEST_fnc_fresh;
private _logic = "Logic" createVehicle [0, 0, 0];
_logic setVariable ["TEST_class", "Logic"];
_logic setVariable ["StorageID", "depot"];
private _crateA = [[5, 5, 0]] call TEST_fnc_crate;
private _crateB = [[6, 5, 0]] call TEST_fnc_crate;
private _otherLogic = "Logic" createVehicle [0, 0, 0];
_otherLogic setVariable ["TEST_class", "Logic"];
_logic setVariable ["TEST_synced", [_crateA, TEST_unit, _crateB, _otherLogic]];
[_logic, [], true] call PMCA_fnc_moduleStorage;
[(_crateA getVariable ["PMCA_storage", ""]) == "depot" && {(_crateB getVariable ["PMCA_storage", ""]) == "depot"} && {"depot" in PMCA_storages},
    "objects synchronised with the module become arsenals of its storage"] call TEST_fnc_assert;
[(TEST_unit getVariable ["PMCA_storage", ""]) == "" && {(_otherLogic getVariable ["PMCA_storage", ""]) == ""}, "units and logics are not made arsenals"] call TEST_fnc_assert;
private _blank = "Logic" createVehicle [0, 0, 0];
_blank setVariable ["TEST_class", "Logic"];
_blank setVariable ["TEST_synced", [[[7, 5, 0]] call TEST_fnc_crate]];
private _count = count PMCA_storageObjects;
[_blank, [], true] call PMCA_fnc_moduleStorage;
[count PMCA_storageObjects == _count, "a module without a storage ID registers nothing"] call TEST_fnc_assert;

// --- Editable stock file -------------------------------------------------------------
call TEST_fnc_fresh;
profileNamespace setVariable ["PMCA_stockFile_v1", nil];
TEST_files = createHashMap;
TEST_filePatching = false;
private _c = toString [47, 47];
private _nl = toString [10];
private _fileText = _c + " Склад арсенала" + _nl + "[" + _nl
    + "  [""base"", [[""arifle_MX_F"", 5], " + _c + " пять винтовок" + _nl
    + "    [""30Rnd_65x39_caseless_mag"", 2, 10], [""FirstAidKit"", -1], [""Nope_Item"", 3], [""optic_Aco"", 1.5]]]," + _nl
    + "  [""depot"", [[""optic_Aco"", 3]]]" + _nl + "]";
TEST_filePatching = true;
TEST_missingReads = [];
[!(call PMCA_fnc_stockFile) && {TEST_missingReads isEqualTo []}, "no stock file: nothing is read, so Arma shows no error"] call TEST_fnc_assert;
TEST_filePatching = false;
// Notepad may start the file with a byte order mark.
TEST_files set ["pmc_arsenal_stock.txt", toString [65279] + _fileText];
PMCA_dirty = false;
[call PMCA_fnc_stockFile, "the mission's stock file is applied"] call TEST_fnc_assert;
[(["arifle_MX_F"] call TEST_fnc_stock) == 5 && {([TEST_mag] call TEST_fnc_stock) == 70} && {(["FirstAidKit"] call TEST_fnc_stock) == -1} && {
    (["HandGrenade"] call TEST_fnc_stock) == 0} && {(["optic_Aco"] call TEST_fnc_stock) == 0},
    "a listed storage gets exactly the file's stock; magazines plus extra rounds; bad rows are skipped"] call TEST_fnc_assert;
[(["optic_Aco", "depot"] call TEST_fnc_stock) == 3 && {PMCA_dirty} && {(profileNamespace getVariable ["PMCA_stockFile_v1", ""]) isEqualTo (toString [65279] + _fileText)},
    "a storage named only in the file is created; the change is saved"] call TEST_fnc_assert;
["base", [["arifle_MX_F", 1]]] call PMCA_fnc_storageAdd;
[!(call PMCA_fnc_stockFile) && {(["arifle_MX_F"] call TEST_fnc_stock) == 6}, "an unchanged file is not applied again; changes from play stay"] call TEST_fnc_assert;
TEST_filePatching = true;
TEST_files set ["userconfig\pmc_arsenal_stock.txt", "[[""base"", [[""arifle_MX_F"", 9]]]]"];
[call PMCA_fnc_stockFile && {(["arifle_MX_F"] call TEST_fnc_stock) == 9} && {(["optic_Aco", "depot"] call TEST_fnc_stock) == 3},
    "with -filePatching the userconfig file comes first; unlisted storages stay"] call TEST_fnc_assert;
TEST_files set ["userconfig\pmc_arsenal_stock.txt", "[[""base"", [[""arifle_MX_F"", 4]]]"];
TEST_parseFails = true;
[!(call PMCA_fnc_stockFile) && {(["arifle_MX_F"] call TEST_fnc_stock) == 9}, "a file that does not parse changes nothing"] call TEST_fnc_assert;
TEST_parseFails = false;
TEST_files set ["userconfig\pmc_arsenal_stock.txt", "[[""base"", 5]]"];
[!(call PMCA_fnc_stockFile) && {(["arifle_MX_F"] call TEST_fnc_stock) == 9}, "a file of the wrong shape changes nothing"] call TEST_fnc_assert;
TEST_filePatching = false;
// Export: what the server writes can be read back unchanged.
((PMCA_storages get "base") get "items") set [TEST_mag, 100];
private _expected = (["base"] call PMCA_fnc_storageItems) + (["depot"] call PMCA_fnc_storageItems);
private _export = [false] call PMCA_fnc_exportStock;
[(_export find "[""30Rnd_65x39_caseless_mag"", 3, 10]") >= 0, "export writes magazines as magazines plus extra rounds"] call TEST_fnc_assert;
((PMCA_storages get "base") get "items") set ["arifle_MX_F", 1];
((PMCA_storages get "depot") get "items") set ["optic_Aco", 1];
TEST_files set ["pmc_arsenal_stock.txt", _export];
call PMCA_fnc_stockFile;
private _back = (["base"] call PMCA_fnc_storageItems) + (["depot"] call PMCA_fnc_storageItems);
[count _back == count _expected && {(_expected findIf {!(_x in _back)}) < 0}, "an exported file applies back to the same stock"] call TEST_fnc_assert;
PMCA_saveBlocked = true;
TEST_files set ["pmc_arsenal_stock.txt", "[]"];
[!(call PMCA_fnc_stockFile), "no file is applied while saving is blocked"] call TEST_fnc_assert;
PMCA_saveBlocked = false;
// Server init applies it after restoring the arsenal objects.
TEST_files set ["pmc_arsenal_stock.txt", "[[""base"", [[""launch_RPG32_F"", 7]]]]"];
TEST_deferSpawn = true;
call PMCA_fnc_serverInit;
TEST_deferSpawn = false;
TEST_deferred = [];
[(["base"] call PMCA_fnc_storageItems) isEqualTo [["launch_RPG32_F", 7]], "server init applies an edited stock file"] call TEST_fnc_assert;
// The template shipped with the mod is only comments and an empty list.
private _template = loadFile "userconfig/pmc_arsenal_stock.txt";
TEST_files set ["pmc_arsenal_stock.txt", _template];
[_template != "" && {call PMCA_fnc_stockFile} && {(["base"] call PMCA_fnc_storageItems) isEqualTo [["launch_RPG32_F", 7]]},
    "the shipped template parses and changes nothing"] call TEST_fnc_assert;
profileNamespace setVariable ["PMCA_stockFile_v1", nil];
TEST_files = createHashMap;

// --- Zeus stock window ------------------------------------------------------------------
call TEST_fnc_fresh;
TEST_zeus = [4, [400, 0, 0]] call TEST_fnc_unit;
TEST_zeus setVariable ["TEST_curator", TEST_box];
[TEST_unit, 3] call TEST_fnc_open;
TEST_messages = [];
3 call TEST_fnc_as;
[TEST_unit, TEST_box] call PMCA_fnc_zeusStock;
[TEST_messages isEqualTo [], "only a Zeus opens the stock window"] call TEST_fnc_assert;
4 call TEST_fnc_as;
private _wall = [[3, 3, 0], "Land_Wall_F"] call TEST_fnc_crate;
[TEST_zeus, _wall] call PMCA_fnc_zeusStock;
[count (["PMCA_fnc_notify", "STR_PMCA_ERR_STOCK_OBJECT", 4] call TEST_fnc_sent) == 1, "the module must be placed on an arsenal"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_zeus, TEST_box] call PMCA_fnc_zeusStock;
private _sent = ["PMCA_fnc_stockReceive", "base", 4] call TEST_fnc_sent;
private _rows = ((_sent select 0) select 0) select 1;
[count _sent == 1 && {count _rows == count (["base"] call PMCA_fnc_storageItems)} && {(_rows select {(_x select 0) == "arifle_MX_F"}) isEqualTo [["arifle_MX_F", 2, 0]]},
    "Zeus gets the storage's items with their counts and arsenal tabs"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_zeus, "base", TEST_mag, "remove", 2] call PMCA_fnc_zeusEdit;
private _seen = (["PMCA_fnc_arsenal", "", 3] call TEST_fnc_sent) apply {_x select 0};
[([TEST_mag] call TEST_fnc_stock) == 30 && {PMCA_dirty} && {_seen isEqualTo [["UpdateItemRemove", [26, TEST_mag, -1, true]], ["UpdateItemAdd", [26, TEST_mag, 30, true]]]},
    "removing 2 magazines takes 60 rounds; open arsenals show the new count"] call TEST_fnc_assert;
[count (["PMCA_fnc_stockReceive", "base", 4] call TEST_fnc_sent) == 1, "the window gets the new stock"] call TEST_fnc_assert;
[TEST_zeus, "base", TEST_mag, "remove", 5] call PMCA_fnc_zeusEdit;
[!(TEST_mag in ((PMCA_storages get "base") get "items")), "removing more than there is removes the item"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_zeus, "base", "U_B_CombatUniform_mcam", "remove", 1] call PMCA_fnc_zeusEdit;
[count (["PMCA_fnc_notify", "STR_PMCA_ERR_STOCK_UNLIMITED", 4] call TEST_fnc_sent) == 1 && {(["U_B_CombatUniform_mcam"] call TEST_fnc_stock) == -1}, "nothing is counted off an unlimited item"] call TEST_fnc_assert;
PMCA_unlockThreshold = 5;
[TEST_zeus, "base", "arifle_MX_F", "set", 50] call PMCA_fnc_zeusEdit;
[(["arifle_MX_F"] call TEST_fnc_stock) == 50, "Zeus sets an exact count; the unlimited threshold does not apply"] call TEST_fnc_assert;
PMCA_unlockThreshold = 0;
[TEST_zeus, "base", "U_B_CombatUniform_mcam", "set", 3] call PMCA_fnc_zeusEdit;
[TEST_zeus, "base", "optic_Aco", "unlimited", 0] call PMCA_fnc_zeusEdit;
[TEST_zeus, "base", "HandGrenade", "clear", 0] call PMCA_fnc_zeusEdit;
[(["U_B_CombatUniform_mcam"] call TEST_fnc_stock) == 3 && {(["optic_Aco"] call TEST_fnc_stock) == -1} && {!("HandGrenade" in ((PMCA_storages get "base") get "items"))},
    "an unlimited item can be made limited, a limited one unlimited, and an item removed"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_zeus, "base", "launch_RPG32_F", "set", 0] call PMCA_fnc_zeusEdit;
[!("launch_RPG32_F" in ((PMCA_storages get "base") get "items")), "setting 0 removes the item"] call TEST_fnc_assert;
{
    TEST_messages = [];
    [TEST_zeus, "base", "arifle_MX_F", _x select 0, _x select 1] call PMCA_fnc_zeusEdit;
    [count (["PMCA_fnc_notify", "STR_PMCA_ERR_STOCK_AMOUNT", 4] call TEST_fnc_sent) == 1 && {(["arifle_MX_F"] call TEST_fnc_stock) == 50}, format ["a bad count is refused: %1", _x]] call TEST_fnc_assert;
} forEach [["remove", 0], ["set", 1.5], ["set", -3]];
TEST_messages = [];
[TEST_zeus, "base", "HandGrenade", "set", 4] call PMCA_fnc_zeusEdit;
[count (["PMCA_fnc_notify", "STR_PMCA_ERR_STOCK_ITEM", 4] call TEST_fnc_sent) == 1, "only items in stock can be changed"] call TEST_fnc_assert;
[TEST_zeus, "base", "arifle_MX_F", "explode", 1] call PMCA_fnc_zeusEdit;
[(["arifle_MX_F"] call TEST_fnc_stock) == 50, "an unknown action changes nothing"] call TEST_fnc_assert;
3 call TEST_fnc_as;
[TEST_unit, "base", "arifle_MX_F", "clear", 0] call PMCA_fnc_zeusEdit;
[TEST_zeus, "base", "arifle_MX_F", "clear", 0] call PMCA_fnc_zeusEdit;
[(["arifle_MX_F"] call TEST_fnc_stock) == 50, "players cannot change the stock, nor act as a Zeus"] call TEST_fnc_assert;
4 call TEST_fnc_as;
TEST_messages = [];
[TEST_zeus, "base"] call PMCA_fnc_zeusStockId;
[count (["PMCA_fnc_stockReceive", "base", 4] call TEST_fnc_sent) == 1, "the window can ask for the stock again"] call TEST_fnc_assert;
// Zeus client side.
TEST_hasInterface = true;
TEST_isRemoteExecuted = true;
TEST_remoteOwner = 2;
PMCA_stockUi = nil;
TEST_dialogs = [];
["base", [["arifle_MX_F", 50, 0]]] call PMCA_fnc_stockReceive;
[TEST_dialogs isEqualTo ["PMCA_RscStock"] && {(PMCA_stockUi get "rows") isEqualTo [["arifle_MX_F", 50, 0]]}, "the stock arrives in a new window"] call TEST_fnc_assert;
TEST_remoteOwner = 9;
PMCA_stockUi = nil;
["base", []] call PMCA_fnc_stockReceive;
[isNil "PMCA_stockUi", "only the server opens the stock window"] call TEST_fnc_assert;
TEST_isRemoteExecuted = false;
TEST_messages = [];
private _stockLogic = "Logic" createVehicle [0, 0, 0];
_stockLogic setVariable ["bis_fnc_curatorAttachObject_object", TEST_box];
[_stockLogic, [], true] call PMCA_fnc_moduleZeusStock;
private _ask = ["PMCA_fnc_zeusStock", "", 2] call TEST_fnc_sent;
[count _ask == 1 && {((_ask select 0) select 0) isEqualTo [player, TEST_box]} && {isNull _stockLogic}, "the module sends its arsenal to the server and removes itself"] call TEST_fnc_assert;
TEST_hasInterface = false;

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];
