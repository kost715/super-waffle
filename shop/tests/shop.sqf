// PMC Shop checks in SQF-VM: class patterns, the catalog, prices and discounts, the cart
// quote, purchase on the server with PMC Bank's own functions (accounts, treasurers,
// journal), delivery into the point's box, stock, the Zeus management actions, the
// per-mission save and the shop's grid list. The game's classes, players, network and
// windows are stand-ins; the laptop's windows are not drawn here.
call compile preprocessFileLineNumbers "tests/vm_compat.sqf";
TEST_count = 0;
TEST_fnc_assert = {
    params ["_ok", "_label"];
    if (!_ok) then {diag_log ("TEST_FAIL: " + _label); exitcode__ 1};
    TEST_count = TEST_count + 1;
    diag_log ("TEST_PASS: " + _label);
};
{
    missionNamespace setVariable ["PMCS_fnc_" + (_x select 1), (format ["pmc_shop/%1/fn_%2.sqf", _x select 0, _x select 1]) call TEST_fnc_load];
} forEach [["Common", "match"], ["Common", "catalog"], ["Common", "itemInfo"], ["Common", "price"], ["Common", "quote"], ["Common", "marketNew"],
    ["Common", "marketPack"], ["Common", "marketUnpack"], ["Common", "money"], ["Common", "requestOwner"], ["Common", "itemName"],
    ["Server", "serverLoad"], ["Server", "save"], ["Server", "marketKey"], ["Server", "caller"], ["Server", "isZeus"], ["Server", "terminalNear"],
    ["Server", "registerTerminal"], ["Server", "registerPoint"], ["Server", "moduleShop"], ["Server", "modulePoint"], ["Server", "bankState"],
    ["Server", "push"], ["Server", "broadcast"], ["Server", "requestState"], ["Server", "closed"], ["Server", "log"], ["Server", "deliver"], ["Server", "buy"],
    ["Server", "admin"], ["Client", "uiShopList"]];
// PMC Bank's real server functions: accounts, treasurers, journal.
{
    missionNamespace setVariable ["PMCB_fnc_" + _x, (format ["pmc_bank/Server/fn_%1.sqf", _x]) call TEST_fnc_load];
} forEach ["serverLoad", "ensure", "apply", "log"];
TEST_isServer = true;
TEST_near = {params ["_a", "_b", ["_eps", 0.001]]; abs (_a - _b) <= _eps};
TEST_sent = {params ["_fn"]; TEST_messages select {((_x select 1) param [0, ""]) == _fn}};
TEST_lastOf = {params ["_list"]; _list select (count _list - 1)};

// --- Class patterns --------------------------------------------------------------------------------
[["MMM_weap_AK74_H1S1", "MMM_weap_AK74_H*S*"] call PMCS_fnc_match && {["mmm_weap_ak74_h2s1", "MMM_weap_AK74_H*S*"] call PMCS_fnc_match}
    && {!(["MMM_weap_AK74N_H1S1", "MMM_weap_AK74_H*S*"] call PMCS_fnc_match)} && {["MMM_weap_AKMS_H3", "MMM_weap_AKMS_H*"] call PMCS_fnc_match}
    && {!(["MMM_weap_AKMS", "MMM_weap_AKMS_H*"] call PMCS_fnc_match)} && {["rhs_weap_ak74", "rhs_weap_ak74"] call PMCS_fnc_match}
    && {!(["rhs_weap_ak74n", "rhs_weap_ak74"] call PMCS_fnc_match)} && {!(["xMMM_weap_AK74_H1S1", "MMM_weap_AK74_H*S*"] call PMCS_fnc_match)},
    "class patterns: '*' is any run, the rest in order from the start, case ignored; no '*' means the exact class"] call TEST_fnc_assert;

// --- Catalog -----------------------------------------------------------------------------------------
private _catalog = call PMCS_fnc_catalog;
private _items = _catalog get "items";
private _ak = if ("rhs_weap_ak74" in _items) then {_items get "rhs_weap_ak74"} else {[]};
private _variants = (_ak select 7) apply {_x select 0};
[_variants isEqualTo ["rhs_weap_ak74", "MMM_weap_AK74_H1S1", "MMM_weap_AK74_H2S1"] && {(_ak select 5) == 250} && {(_ak select 6) == 10}
    && {(((_ak select 7) select 1) select 1) == "AK-74 (plum) (MMM_weap_AK74_H1S1)"} && {"rhs_weap_akm" in _items} && {"rhs_weap_pkm" in _items}
    && {!("rhs_weap_m4a1_carryhandle" in _items)} && {((_items get "rhs_weap_pkm") select 5) == 800} && {((_items get "rhs_weap_svds") select 5) == 450}
    && {((_items get "uk3cb_saiga12k") select 5) == 0} && {(_catalog get "boxDiscount") == 25}
    && {((_catalog get "calibres") get "5.45x39 АК") isEqualTo ["MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L23_Plastic_7N6M", "MMM_mag_545x39_6L23_Plastic_7N22"]}
    && {((_items get "MMM_mag_545x39_6L23_Plastic_7N22") select 9) == "AP"},
    "catalog: the base weapons the game has, MMM patterns found and sorted (same names told apart), prices by type (assault 250 x10, MG 800, semi-auto 450, Saiga none), magazines by calibre"] call TEST_fnc_assert;

// --- Prices and discounts ------------------------------------------------------------------------------
private _market = call PMCS_fnc_marketNew;
private _p0 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
(_market get "items") set ["rhs_weap_ak74", [false, -1, 10, -1, -1]];
private _p1 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
(_market get "cats") set ["assault", 20];
private _p2 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
_market set ["global", 30];
private _p3 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
private _mag = ["MMM_mag_545x39_6L20_7N6M", _market] call PMCS_fnc_price;
(_market get "items") set ["rhs_weap_akm", [true, -1, 0, -1, -1]];
(_market get "items") set ["rhs_weap_pkm", [false, 900, 0, 2, 0]];
private _hidden = (["rhs_weap_akm", _market] call PMCS_fnc_price) select 0;
private _soldout = ["rhs_weap_pkm", _market] call PMCS_fnc_price;
[_p0 isEqualTo ["ok", 250, 1875, 0, -1, 10] && {_p1 isEqualTo ["ok", 225, 1875, 10, -1, 10]} && {_p2 isEqualTo ["ok", 200, 1875, 20, -1, 10]}
    && {_p3 isEqualTo ["ok", 175, 1750, 30, -1, 10]} && {(_mag select 0) == "noprice"} && {_hidden == "hidden"}
    && {_soldout isEqualTo ["soldout", 630, 1890, 30, 0, 3]},
    "price: catalog 250, box of 10 at -25%; one discount - the largest of item 10, category 20, market 30; a box takes its own when larger; no price, hidden, sold out"] call TEST_fnc_assert;

// --- Cart quote -----------------------------------------------------------------------------------------
_market = call PMCS_fnc_marketNew;
(_market get "items") set ["rhs_weap_pkm", [false, -1, 0, 3, 3]];
private _q1 = [[["rhs_weap_ak74", "MMM_weap_AK74_H2S1", 1, true], ["rhs_weap_pkm", "rhs_weap_pkm", 2, false]], _market] call PMCS_fnc_quote;
private _q2 = [[["rhs_weap_ak74", "rhs_weap_akm", 1, false]], _market] call PMCS_fnc_quote;
private _q3 = [[["rhs_weap_pkm", "rhs_weap_pkm", 2, false], ["rhs_weap_pkm", "rhs_weap_pkm", 2, false]], _market] call PMCS_fnc_quote;
private _q4 = [[["rhs_weap_ak74", "rhs_weap_ak74", 0, false]], _market] call PMCS_fnc_quote;
private _q5 = [[["MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L20_7N6M", 5, false]], _market] call PMCS_fnc_quote;
[(_q1 select 0) == 1875 + 1600 && {((_q1 select 1) get "rhs_weap_ak74") == 10} && {(_q1 select 2) == ""} && {(_q2 select 2) == "STR_PMCS_ERR_CART"}
    && {(_q3 select 2) == "STR_PMCS_ERR_STOCK"} && {(_q4 select 2) == "STR_PMCS_ERR_CART"} && {(_q5 select 2) == "STR_PMCS_ERR_UNAVAILABLE"}
    && {(([[], _market] call PMCS_fnc_quote) select 2) == "STR_PMCS_ERR_CART"},
    "quote: a box and units priced; a class that is not the item's variant, zero, an empty cart, more than is left and an item without a price are refused"] call TEST_fnc_assert;

// --- Server: laptop, point, purchase through PMC Bank ----------------------------------------------
TEST_fresh = {
    PMCS_market = nil;
    PMCB_accounts = nil;
    TEST_messages = [];
    profileNamespace setVariable [call PMCS_fnc_marketKey, nil];
    profileNamespace setVariable ["PMCB_bank_v1", nil];
    call PMCB_fnc_serverLoad;
    call PMCS_fnc_serverLoad;
};
call TEST_fresh;
private _buyer = "B_Soldier_F" createVehicle [0, 0, 0];
_buyer setVariable ["TEST_uid", "76561100000000001"];
_buyer setVariable ["TEST_name", "Buyer"];
private _laptop = "Land_Laptop_unfolded_F" createVehicle [1, 0, 0];
private _box = "Box_NATO_Ammo_F" createVehicle [5, 0, 0];
private _shopModule = "Logic" createVehicle [0, 0, 0];
_shopModule setVariable ["PointID", "8Z8N"];
_shopModule setVariable ["TEST_synced", [_laptop]];
[_shopModule, [], true] call PMCS_fnc_moduleShop;
private _pointModule = "Logic" createVehicle [0, 0, 0];
_pointModule setVariable ["PointID", "8Z8N"];
_pointModule setVariable ["TEST_synced", [_box]];
[_pointModule, [], true] call PMCS_fnc_modulePoint;
[_buyer] call PMCB_fnc_ensure;
(PMCB_accounts get "76561100000000001") set [0, 5000];
private _jip = (["PMCS_fnc_terminalInit"] call TEST_sent) select 0;
[_buyer, _laptop, "personal", [["rhs_weap_ak74", "MMM_weap_AK74_H1S1", 1, true], ["rhs_weap_pkm", "rhs_weap_pkm", 2, false]]] call PMCS_fnc_buy;
private _balance = (PMCB_accounts get "76561100000000001") select 0;
private _weapons = (_box getVariable ["TEST_weapons", []]) apply {_x select 0};
private _bankLog = PMCB_log select (count PMCB_log - 1);
[(_laptop getVariable "PMCS_mode") == "shop" && {(_laptop getVariable "PMCS_point") == "8Z8N"} && {(_jip select 1) isEqualTo ["PMCS_fnc_terminalInit", 0, _laptop]}
    && {_balance == 5000 - 1875 - 1600} && {({_x == "MMM_weap_AK74_H1S1"} count _weapons) == 10} && {({_x == "rhs_weap_pkm"} count _weapons) == 2}
    && {(_bankLog select 4) == "shop"} && {(_bankLog select 5) == 3475} && {(_bankLog select 8) == "Buyer"}
    && {([["PMCS_fnc_receive"] call TEST_sent] call TEST_lastOf) select 0 select 2 == "bought"} && {count (PMCS_market get "log") == 1},
    "purchase: the laptop and box from their modules (point 8Z8N), the personal account charged 3 475 (PMC Bank journal: shop), the chosen variant and the units in the point's box, the client told"] call TEST_fnc_assert;

TEST_messages = [];
private _before = count (_box getVariable ["TEST_weapons", []]);
[_buyer, _laptop, "personal", [["rhs_weap_pkm", "rhs_weap_pkm", 3, false]]] call PMCS_fnc_buy;
private _poor = ((["PMCS_fnc_notify"] call TEST_sent) select 0) select 0;
[_buyer, _laptop, "group", [["rhs_weap_ak74", "rhs_weap_ak74", 1, false]]] call PMCS_fnc_buy;
private _notTreasurer = ((["PMCS_fnc_notify"] call TEST_sent) select 1) select 0;
PMCB_treasurers set ["76561100000000001", "Buyer"];
PMCB_group = 1000;
[_buyer, _laptop, "group", [["rhs_weap_ak74", "rhs_weap_ak74", 1, false]]] call PMCS_fnc_buy;
private _groupAfter = PMCB_group;
_box setDamage 1;
[_buyer, _laptop, "personal", [["rhs_weap_ak74", "rhs_weap_ak74", 1, false]]] call PMCS_fnc_buy;
private _noBox = ([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0;
_box setDamage 0;
_buyer setPos [40, 0, 0];
[_buyer, _laptop, "personal", [["rhs_weap_ak74", "rhs_weap_ak74", 1, false]]] call PMCS_fnc_buy;
private _far = ([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0;
_buyer setPos [0, 0, 0];
[(_poor select 0) == "STR_PMCS_ERR_FUNDS" && {(_notTreasurer select 0) == "STR_PMCS_ERR_NOT_TREASURER"} && {_groupAfter == 750}
    && {(_noBox select 0) == "STR_PMCS_ERR_NO_BOX"} && {(_far select 0) == "STR_PMCS_ERR_FAR"}
    && {((PMCB_accounts get "76561100000000001") select 0) == 1525} && {count (_box getVariable ["TEST_weapons", []]) == _before + 1},
    "refused: not enough money, the group's account without being a treasurer, no box standing at the point, too far from the laptop - nothing charged or delivered; a treasurer pays from the group's account"] call TEST_fnc_assert;

// --- Zeus management ---------------------------------------------------------------------------------------
TEST_messages = [];
private _adminLaptop = "Land_Laptop_unfolded_F" createVehicle [2, 0, 0];
[_adminLaptop, "admin", ""] call PMCS_fnc_registerTerminal;
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 3]] call PMCS_fnc_admin;
private _refused = (((["PMCS_fnc_notify"] call TEST_sent) select 0) select 0) select 0;
_buyer setVariable ["TEST_curator", _buyer];
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 3]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "category", ["assault", 15]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "global", [95]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "box", [40]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "item", ["MMM_mag_545x39_6L23_Plastic_7N22", false, 12, 0, -1]] call PMCS_fnc_admin;
PMCB_accounts get "76561100000000001" set [0, 100000];
[_buyer, _laptop, "personal", [["rhs_weap_pkm", "rhs_weap_pkm", 2, false], ["MMM_mag_545x39_6L23_Plastic_7N22", "MMM_mag_545x39_6L23_Plastic_7N22", 10, false]]] call PMCS_fnc_buy;
private _left = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
private _mags = _box getVariable ["TEST_mags", []];
[_buyer, _laptop, "personal", [["rhs_weap_pkm", "rhs_weap_pkm", 2, false]]] call PMCS_fnc_buy;
private _stock = ([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0;
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 3]] call PMCS_fnc_admin;
private _kept = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 5]] call PMCS_fnc_admin;
private _restocked = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
[_refused == "STR_PMCS_ERR_ZEUS" && {_left == 1} && {(_stock select 0) == "STR_PMCS_ERR_STOCK"} && {_kept == 1} && {_restocked == 5}
    && {((PMCS_market get "cats") get "assault") == 15} && {(PMCS_market get "global") == 0} && {(PMCS_market get "box") == 40}
    && {(_mags select {(_x select 0) == "MMM_mag_545x39_6L23_Plastic_7N22"}) isEqualTo [["MMM_mag_545x39_6L23_Plastic_7N22", 10]]},
    "Zeus only: a limited quantity sells down (3 -> 1, then not enough), stays when only the price changes, restocks when the quantity changes; category and box discounts; a price for a magazine puts it on sale; a 95% discount is refused"] call TEST_fnc_assert;

TEST_messages = [];
[_buyer, _adminLaptop, "add", ["rhs_weap_asval", 900, 1]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "add", ["MMM_weap_AK74_H2S1", 100, -1]] call PMCS_fnc_admin;
private _inCatalog = (([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0) select 0;
[_buyer, _adminLaptop, "add", ["B_AssaultPack_rgr", 120, -1]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "add", ["ItemGPS", 50, -1]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "add", ["NoSuchThing", 50, -1]] call PMCS_fnc_admin;
private _noClass = (([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0) select 0;
[_buyer, _laptop, "personal", [["x_rhs_weap_asval", "rhs_weap_asval", 1, false], ["x_B_AssaultPack_rgr", "B_AssaultPack_rgr", 2, false], ["x_ItemGPS", "ItemGPS", 1, false]]] call PMCS_fnc_buy;
private _val = ({(_x select 0) == "rhs_weap_asval"} count (_box getVariable ["TEST_weapons", []])) == 1;
private _packs = _box getVariable ["TEST_packs", []];
private _gps = _box getVariable ["TEST_items", []];
private _valState = (["x_rhs_weap_asval", PMCS_market] call PMCS_fnc_price) select 0;
[_buyer, _adminLaptop, "remove", ["x_ItemGPS"]] call PMCS_fnc_admin;
[_val && {_packs isEqualTo [["B_AssaultPack_rgr", 2]]} && {_gps isEqualTo [["ItemGPS", 1]]} && {_valState == "soldout"}
    && {_inCatalog == "STR_PMCS_ERR_IN_CATALOG"} && {_noClass == "STR_PMCS_ERR_CLASS"} && {!("x_ItemGPS" in (PMCS_market get "custom"))}
    && {((PMCS_market get "custom") get "x_B_AssaultPack_rgr") isEqualTo ["backpack", "B_AssaultPack_rgr", "Assault Pack", "\a3\pack_ca.paa"]},
    "added from the game: a weapon (1 in stock, then sold out), a backpack and an item, each delivered its own way; a catalog variant and an unknown class refused; an added item removed"] call TEST_fnc_assert;

// --- Saved per mission ---------------------------------------------------------------------------------------
call PMCS_fnc_save;
private _key = call PMCS_fnc_marketKey;
private _log = count (PMCS_market get "log");
PMCS_market = nil;
call PMCS_fnc_serverLoad;
private _reloaded = ((PMCS_market get "items") get "rhs_weap_pkm") isEqualTo [false, -1, 0, 5, 5] && {(PMCS_market get "box") == 40} && {count (PMCS_market get "log") == _log};
// A reload in the same session forgets the laptops (the game registers them once at start).
[_adminLaptop, "admin", ""] call PMCS_fnc_registerTerminal;
[_buyer, _adminLaptop, "reset", []] call PMCS_fnc_admin;
private _reset = count keys (PMCS_market get "items") == 0 && {(PMCS_market get "box") == 25} && {count (PMCS_market get "log") == _log + 1};
profileNamespace setVariable [_key, [1, "broken"]];
PMCS_market = nil;
call PMCS_fnc_serverLoad;
private _blocked = PMCS_saveBlocked && {!(call PMCS_fnc_save)} && {(profileNamespace getVariable _key) isEqualTo [1, "broken"]};
// Right shape, one bad entry (a 95% discount): refused as a whole.
private _badEntry = [[1, [["rhs_weap_ak74", [false, -1, 95, -1, -1]]], [], [], 0, 25, []]] call PMCS_fnc_marketUnpack;
private _goodEntry = [[1, [["rhs_weap_ak74", [false, -1, 50, -1, -1]]], [], [], 0, 25, []]] call PMCS_fnc_marketUnpack;
_blocked = _blocked && {isNil "_badEntry"} && {!isNil "_goodEntry"};
[_reloaded && {_reset} && {_blocked} && {_key find "PMCS_market_v1_" == 0} && {(_key find "TestMission") > 0},
    "saved per mission (key with mission and map): reloaded as it was, journal included; reset to the catalog keeps the journal; a damaged record is left on disk and nothing is saved over it"] call TEST_fnc_assert;

// --- The shop's grid --------------------------------------------------------------------------------------
PMCS_market = call PMCS_fnc_marketNew;
(PMCS_market get "items") set ["rhs_weap_akm", [true, -1, 0, -1, -1]];
PMCS_ui = createHashMapFromArray [["market", PMCS_market], ["tab", "weapons"], ["search", ""], ["offTypes", []], ["offCals", []], ["sort", 1]];
([] call PMCS_fnc_uiShopList) params ["_shown", "_types", "_cals"];
PMCS_ui set ["offCals", ["5.45x39 АК"]];
private _noAk = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["offCals", []];
PMCS_ui set ["search", "mmm_weap_ak74_h2"];
private _found = ([] call PMCS_fnc_uiShopList) select 0;
[(_shown select 0) == "rhs_weap_pkm" && {!("rhs_weap_akm" in _shown)} && {!("uk3cb_saiga12k" in _shown)} && {"rhs_weap_ak74" in _shown}
    && {!("rhs_weap_ak74" in _noAk)} && {_found isEqualTo ["rhs_weap_ak74"]} && {(_types get "штурмовая винтовка") == 2},
    "grid: dearest first, hidden and unpriced items left out, the calibre filter, search by a variant's class, counts per type"] call TEST_fnc_assert;


// --- The laptop on screen: desktop, shop, cart, purchase, management ------------------------------------
{
    missionNamespace setVariable ["PMCS_fnc_" + _x, (format ["pmc_shop/Client/fn_%1.sqf", _x]) call TEST_fnc_load];
} forEach ["ui", "uiMake", "uiClear", "uiColor", "uiShop", "uiCartLine", "uiCartAdd", "uiAdmin", "open", "receive", "notify"];
TEST_deferSpawn = true;
PMCS_ui = nil;
call TEST_fresh;
private _shopLaptop = "Land_Laptop_unfolded_F" createVehicle [100, 0, 0];
private _shopBox = "Box_NATO_Ammo_F" createVehicle [104, 0, 0];
[_shopLaptop, "shop", "8Z8N"] call PMCS_fnc_registerTerminal;
[_shopBox, "8Z8N"] call PMCS_fnc_registerPoint;
player setVariable ["TEST_uid", "76561100000000002"];
player setVariable ["TEST_name", "Player"];
player setPos [100, 1, 0];
[player] call PMCB_fnc_ensure;
(PMCB_accounts get "76561100000000002") set [0, 10000];
TEST_live = {TEST_ctrls select {!(_x getVariable ["TEST_deleted", false])}};
// [event, arguments]: the control a click on which sends that event (no arguments: []).
TEST_byEvent = {
    private _event = +_this;
    if (count _event == 1) then {_event pushBack []};
    ([] call TEST_live) select {(_x getVariable ["PMCS_event", []]) isEqualTo _event}
};
TEST_byText = {params ["_text"]; ([] call TEST_live) select {(_x getVariable ["TEST_text", ""]) isEqualTo _text}};
TEST_region = {
    params ["_name"];
    private _all = PMCS_ui get "regions";
    (if (_name in _all) then {_all get _name} else {[]}) select {!(_x getVariable ["TEST_deleted", false])}
};
TEST_click = {params ["_ctrl"]; [_ctrl] call (_ctrl getVariable "TEST_eh_ButtonClick")};
// Requests and answers go round: server functions for the client's requests, client ones for the answers.
TEST_serve = {
    private _guard = 0;
    while {TEST_messages isNotEqualTo [] && {_guard < 50}} do {
        _guard = _guard + 1;
        (TEST_messages deleteAt 0) params ["_args", "_target"];
        private _fn = _target select 0;
        if (_fn in ["PMCS_fnc_requestState", "PMCS_fnc_buy", "PMCS_fnc_admin", "PMCS_fnc_closed", "PMCS_fnc_receive", "PMCS_fnc_notify"]) then {
            _args call (missionNamespace getVariable _fn);
        };
    };
};
TEST_messages = [];
[_shopLaptop] call PMCS_fnc_open;
private _display = "Logic" createVehicle [0, 0, 0];
["onLoad", [_display]] call PMCS_fnc_ui;
private _icon = (["desk"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_ButtonClear"};
private _deskLabel = ["STR_PMCS_DESK_SHOP"] call TEST_byText;
[_icon select 0] call TEST_click;
private _asked = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_requestState"}) isNotEqualTo [];
call TEST_serve;
private _cards = (["grid"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_ButtonClear"};
private _sel = PMCS_ui get "sel";
[("PMCS_RscLaptop" in TEST_dialogs) && {count _icon == 2} && {_deskLabel isNotEqualTo []} && {_asked} && {(PMCS_ui get "view") == "browser"}
    && {count _cards == count (PMCS_ui get "shown")} && {count _cards >= 4} && {_sel == "rhs_weap_ak74"}
    && {(["АК-74"] call TEST_byText) isNotEqualTo []} && {(["detail"] call TEST_region) isNotEqualTo []},
    "laptop: the desktop with the ION Market icon, the browser asks the server, the grid has a card per item, the cheapest is chosen and shown in the card"] call TEST_fnc_assert;

[(["add", [false]] call TEST_byEvent) select 0] call TEST_click;
[(["variant", ["MMM_weap_AK74_H2S1"]] call TEST_byEvent) select 0] call TEST_click;
[(["add", [true]] call TEST_byEvent) select 0] call TEST_click;
private _cart = +(PMCS_ui get "cart");
[(["checkout"] call TEST_byEvent) select 0] call TEST_click;
private _request = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_buy"}) select 0;
call TEST_serve;
private _inBox = (_shopBox getVariable ["TEST_weapons", []]) apply {_x select 0};
[_cart isEqualTo [["rhs_weap_ak74", "rhs_weap_ak74", 1, false], ["rhs_weap_ak74", "MMM_weap_AK74_H2S1", 1, true]]
    && {((_request select 0) select 2) == "personal"} && {((PMCB_accounts get "76561100000000002") select 0) == 10000 - 250 - 1875}
    && {({_x == "MMM_weap_AK74_H2S1"} count _inBox) == 10} && {({_x == "rhs_weap_ak74"} count _inBox) == 1} && {(PMCS_ui get "cart") isEqualTo []},
    "shop: add one, pick a variant, add a box; check out pays 2 125 from the personal account, the box gets 1 + 10 of the chosen variant, the cart empties"] call TEST_fnc_assert;

private _calCheck = (([] call TEST_live) select {(_x getVariable ["PMCS_filter", []]) isEqualTo ["cal", "5.45x39 АК"]}) select 0;
[_calCheck, 0] call (_calCheck getVariable "TEST_eh_CheckedChanged");
private _without = PMCS_ui get "shown";
[_calCheck, 1] call (_calCheck getVariable "TEST_eh_CheckedChanged");
(PMCS_market get "items") set ["MMM_mag_545x39_6L20_7N6M", [false, 15, 0, -1, -1]];
call PMCS_fnc_broadcast;
call TEST_serve;
[(["select", ["rhs_weap_ak74"]] call TEST_byEvent) select 0] call TEST_click;
private _chips = ["mag", ["MMM_mag_545x39_6L20_7N6M"]] call TEST_byEvent;
[(["magQty", [1]] call TEST_byEvent) select 0] call TEST_click;
[(["magAdd"] call TEST_byEvent) select 0] call TEST_click;
[PMCS_ui get "tabAmmo"] call TEST_click;
private _ammoCards = (["grid"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_ButtonClear"};
[(["cartOpen"] call TEST_byEvent) select 0] call TEST_click;
private _rows = count (((["overlay"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0 getVariable ["TEST_rows", []]);
[(["cartQty", [1]] call TEST_byEvent) select 0] call TEST_click;
private _two = ((PMCS_ui get "cart") select 0) select 2;
[(["cartRemove", []] call TEST_byEvent) select 0] call TEST_click;
[(["add", [false]] call TEST_byEvent) select 0] call TEST_click;
private _beforeClear = count (PMCS_ui get "cart");
[(["cartClear", []] call TEST_byEvent) select 0] call TEST_click;
_two = [_two, -1] select (_beforeClear != 1);
[(({"rhs_weap_ak74" == _x} count _without) == 0) && {count _chips == 1} && {_rows == 1} && {_two == 3} && {(PMCS_ui get "cart") isEqualTo []}
    && {count _ammoCards == 1} && {(PMCS_ui get "shown") isEqualTo ["MMM_mag_545x39_6L20_7N6M"]},
    "shop: the calibre box hides the AK, a magazine priced by a Zeus shows up as a chip in the AK's card and as a card on the ammunition tab; the cart window changes and removes lines"] call TEST_fnc_assert;

TEST_messages = [];
[(["×"] call TEST_byText) select 0] call TEST_click;
private _back = (PMCS_ui get "view") == "desk" && {(["grid"] call TEST_region) isEqualTo []};
["onUnload", []] call PMCS_fnc_ui;
private _closed = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_closed"}) isNotEqualTo [];
call TEST_serve;
[_back && {_closed} && {isNil "PMCS_ui"} && {count keys PMCS_viewers == 0}, "closing the browser goes back to the desktop; closing the laptop tells the server, which stops sending"] call TEST_fnc_assert;

// Management by a Zeus.
private _adminPc = "Land_Laptop_unfolded_F" createVehicle [100, 2, 0];
[_adminPc, "admin", ""] call PMCS_fnc_registerTerminal;
player setVariable ["TEST_curator", player];
TEST_messages = [];
[_adminPc] call PMCS_fnc_open;
["onLoad", ["Logic" createVehicle [0, 0, 0]]] call PMCS_fnc_ui;
[((["desk"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_ButtonClear"}) select 0] call TEST_click;
call TEST_serve;
private _table = ((["table"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0;
private _tableRows = count (_table getVariable ["TEST_rows", []]);
[_table, 1] call (_table getVariable "TEST_eh_LBSelChanged");
private _picked = PMCS_ui get "asel";
(PMCS_ui get "afields") params ["", "_priceEdit", "_discountEdit", "_modeCombo", "_qtyEdit"];
_priceEdit setVariable ["TEST_text", "300"];
_discountEdit setVariable ["TEST_text", "10"];
_modeCombo setVariable ["TEST_cur", 1];
_qtyEdit setVariable ["TEST_text", "4"];
[(["apply"] call TEST_byEvent) select 0] call TEST_click;
call TEST_serve;
private _set = if (_picked in (PMCS_market get "items")) then {(PMCS_market get "items") get _picked} else {[]};
[(["page", ["discounts"]] call TEST_byEvent) select 0] call TEST_click;
private _globalOk = (["discount", ["global", []]] call TEST_byEvent) select 0;
(_globalOk getVariable "PMCS_edit") setVariable ["TEST_text", "12"];
[_globalOk] call TEST_click;
call TEST_serve;
[(["page", ["items"]] call TEST_byEvent) select 0] call TEST_click;
[(["addOpen"] call TEST_byEvent) select 0] call TEST_click;
(PMCS_ui get "aaddFields") params ["_classEdit"];
_classEdit setVariable ["TEST_text", " rhs_weap_asval "];
[(["addFind"] call TEST_byEvent) select 0] call TEST_click;
private _foundVal = PMCS_ui get "aaddFound";
(PMCS_ui get "aaddFields") params ["", "_addPrice", "_addQty"];
_addPrice setVariable ["TEST_text", "700"];
_addQty setVariable ["TEST_text", "2"];
[(["addConfirm"] call TEST_byEvent) select 0] call TEST_click;
call TEST_serve;
[(["reset"] call TEST_byEvent) select 0] call TEST_click;
private _armed = count (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_admin"});
[(["page", ["log"]] call TEST_byEvent) select 0] call TEST_click;
private _log = ((["table"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0;
// A header and the six weapons the stand-in game has.
[_tableRows == 7 && {_picked == "rhs_weap_ak74"} && {_set isEqualTo [false, 300, 10, 4, 4]} && {(PMCS_market get "global") == 12}
    && {(_foundVal select 0) == "AS Val"} && {((PMCS_market get "items") get "x_rhs_weap_asval") isEqualTo [false, 700, 0, 2, 2]} && {_armed == 0}
    && {count (_log getVariable ["TEST_rows", []]) == 1 + count (PMCS_market get "log")},
    "management: the table lists the goods, the chosen one gets price, discount and a limited quantity; a market discount; a class found in the game and added; reset waits for a second click; the journal lists every change"] call TEST_fnc_assert;
["onUnload", []] call PMCS_fnc_ui;

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];
