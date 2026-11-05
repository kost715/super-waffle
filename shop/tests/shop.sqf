// PMC Shop checks in SQF-VM: class patterns, the catalog, prices and discounts, the cart
// quote, purchase on the server with PMC Bank's own functions (accounts, treasurers,
// journal), delivery into the point's box, stock, the Zeus management actions, the
// per-mission save, the shop's grid (weapons by category and calibre, ammunition by
// calibre) and the laptop's windows driven through their controls. The game's classes,
// players, network and controls are stand-ins; nothing is drawn here.
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
    ["Common", "marketPack"], ["Common", "marketUnpack"], ["Common", "money"], ["Common", "requestOwner"], ["Common", "itemName"], ["Common", "categoryName"],
    ["Server", "serverLoad"], ["Server", "save"], ["Server", "marketKey"], ["Server", "caller"], ["Server", "isZeus"], ["Server", "terminalNear"],
    ["Server", "registerTerminal"], ["Server", "registerPoint"], ["Server", "moduleShop"], ["Server", "modulePoint"], ["Server", "bankState"],
    ["Server", "push"], ["Server", "broadcast"], ["Server", "requestState"], ["Server", "closed"], ["Server", "log"], ["Server", "deliver"], ["Server", "buy"],
    ["Server", "admin"], ["Client", "uiShopList"], ["Client", "uiCalibreMags"]];
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
[_variants isEqualTo ["rhs_weap_ak74", "MMM_weap_AK74_H1S1", "MMM_weap_AK74_H2S1"] && {(_ak select 5) == 250} && {(_ak select 2) == "штурмовая винтовка"}
    && {(_ak select 3) == "5.45x39 АК"}
    && {(((_ak select 7) select 1) select 1) == "AK-74 (plum) (MMM_weap_AK74_H1S1)"} && {"rhs_weap_akm" in _items} && {"rhs_weap_pkm" in _items}
    && {!("rhs_weap_m4a1_carryhandle" in _items)} && {((_items get "rhs_weap_pkm") select 5) == 800} && {((_items get "rhs_weap_svds") select 5) == 450}
    && {((_items get "uk3cb_saiga12k") select 5) == 0} && {!("boxDiscount" in _catalog)}
    && {(_catalog get "categories") findIf {(_x select 0) == "единый пулемет"} >= 0}
    && {(["единый пулемет"] call PMCS_fnc_categoryName) == "Единые пулемёты"} && {(["ammo"] call PMCS_fnc_categoryName) == "STR_PMCS_TAB_AMMO"}
    && {((_catalog get "calibres") get "5.45x39 АК") isEqualTo ["MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L23_Plastic_7N6M", "MMM_mag_545x39_6L23_Plastic_7N22"]}
    && {((_items get "MMM_mag_545x39_6L23_Plastic_7N22") select 9) == "AP"} && {((_items get "MMM_mag_545x39_6L23_Plastic_7N22") select 8) == "30 патр. Полимер"},
    "catalog: the base weapons the game has, MMM patterns found and sorted (same names told apart), the table's category and calibre, prices by type (assault 250, MG 800, semi-auto 450, Saiga none), magazines by calibre with their magazine and ammo type"] call TEST_fnc_assert;

// --- Prices: a box is the base, one piece costs more; discounts ------------------------------------------
private _market = call PMCS_fnc_marketNew;
private _p0 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
(_market get "items") set ["rhs_weap_ak74", [false, -1, 10, -1, -1]];
private _p1 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
(_market get "cats") set ["штурмовая винтовка", 20];
private _p2 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
_market set ["global", 30];
private _p3 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
private _mag = ["MMM_mag_545x39_6L20_7N6M", _market] call PMCS_fnc_price;
(_market get "items") set ["rhs_weap_akm", [true, -1, 0, -1, -1]];
(_market get "items") set ["rhs_weap_pkm", [false, 900, 0, 2, 0]];
private _hidden = (["rhs_weap_akm", _market] call PMCS_fnc_price) select 0;
private _soldout = ["rhs_weap_pkm", _market] call PMCS_fnc_price;
private _magMarket = call PMCS_fnc_marketNew;
(_magMarket get "items") set ["MMM_mag_545x39_6L20_7N6M", [false, 15, 0, -1, -1]];
private _magPrice = ["MMM_mag_545x39_6L20_7N6M", _magMarket] call PMCS_fnc_price;
(_magMarket get "cats") set ["ammo", 10];
private _magOff = ["MMM_mag_545x39_6L20_7N6M", _magMarket] call PMCS_fnc_price;
// The box sizes and the single-piece rules are CBA settings.
PMCS_weaponBoxUnits = 5; PMCS_weaponUnitShare = 50; PMCS_magBoxUnits = 20; PMCS_magUnitMarkup = 100;
private _cbaWeapon = ["rhs_weap_ak74", call PMCS_fnc_marketNew] call PMCS_fnc_price;
private _cbaMag = ["MMM_mag_545x39_6L20_7N6M", _magMarket] call PMCS_fnc_price;
PMCS_weaponBoxUnits = nil; PMCS_weaponUnitShare = nil; PMCS_magBoxUnits = nil; PMCS_magUnitMarkup = nil;
[_p0 isEqualTo ["ok", 400, 1000, 0, -1, 4] && {_p1 isEqualTo ["ok", 360, 900, 10, -1, 4]} && {_p2 isEqualTo ["ok", 320, 800, 20, -1, 4]}
    && {_p3 isEqualTo ["ok", 280, 700, 30, -1, 4]} && {(_mag select 0) == "noprice"} && {_hidden == "hidden"}
    && {_soldout isEqualTo ["soldout", 1008, 2520, 30, 0, 4]} && {_magPrice isEqualTo ["ok", 20, 450, 0, -1, 30]}
    && {_magOff isEqualTo ["ok", 18, 405, 10, -1, 30]} && {_cbaWeapon isEqualTo ["ok", 625, 1250, 0, -1, 5]} && {_cbaMag isEqualTo ["ok", 27, 270, 10, -1, 20]},
    "price: a box of 4 at the base price (4 x 250 = 1 000, no box discount), one weapon 40% of a box (400); a box of 30 magazines at the base (450), one magazine +30% (20); one discount - the largest of item 10, category 20, market 30; box sizes and single-piece rules from CBA; no price, hidden, sold out"] call TEST_fnc_assert;

// --- Cart quote -----------------------------------------------------------------------------------------
_market = call PMCS_fnc_marketNew;
(_market get "items") set ["rhs_weap_pkm", [false, -1, 0, 3, 3]];
private _q1 = [[["rhs_weap_ak74", "MMM_weap_AK74_H2S1", 1, true], ["rhs_weap_pkm", "rhs_weap_pkm", 2, false]], _market] call PMCS_fnc_quote;
private _q2 = [[["rhs_weap_ak74", "rhs_weap_akm", 1, false]], _market] call PMCS_fnc_quote;
private _q3 = [[["rhs_weap_pkm", "rhs_weap_pkm", 2, false], ["rhs_weap_pkm", "rhs_weap_pkm", 2, false]], _market] call PMCS_fnc_quote;
private _q4 = [[["rhs_weap_ak74", "rhs_weap_ak74", 0, false]], _market] call PMCS_fnc_quote;
private _q5 = [[["MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L20_7N6M", 5, false]], _market] call PMCS_fnc_quote;
private _q6 = [[["rhs_weap_pkm", "rhs_weap_pkm", 1, true]], _market] call PMCS_fnc_quote;
[(_q1 select 0) == 1000 + 2 * 1280 && {((_q1 select 1) get "rhs_weap_ak74") == 4} && {(_q1 select 2) == ""} && {(_q2 select 2) == "STR_PMCS_ERR_CART"}
    && {(_q3 select 2) == "STR_PMCS_ERR_STOCK"} && {(_q4 select 2) == "STR_PMCS_ERR_CART"} && {(_q5 select 2) == "STR_PMCS_ERR_UNAVAILABLE"}
    && {(_q6 select 2) == "STR_PMCS_ERR_STOCK"} && {(([[], _market] call PMCS_fnc_quote) select 2) == "STR_PMCS_ERR_CART"},
    "quote: a box (4 pieces) and single pieces priced; a box counts its 4 pieces against the stock (3 left); a class that is not the item's variant, zero, an empty cart, more than is left and an item without a price are refused"] call TEST_fnc_assert;

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
    && {_balance == 5000 - 1000 - 2560} && {({_x == "MMM_weap_AK74_H1S1"} count _weapons) == 4} && {({_x == "rhs_weap_pkm"} count _weapons) == 2}
    && {(_bankLog select 4) == "shop"} && {(_bankLog select 5) == 3560} && {(_bankLog select 8) == "Buyer"}
    && {([["PMCS_fnc_receive"] call TEST_sent] call TEST_lastOf) select 0 select 2 == "bought"} && {count (PMCS_market get "log") == 1},
    "purchase: the laptop and box from their modules (point 8Z8N), the personal account charged 3 560 for a box and two single machine guns (PMC Bank journal: shop), the box's 4 pieces of the chosen variant and the 2 single ones in the point's box, the client told"] call TEST_fnc_assert;

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
[(_poor select 0) == "STR_PMCS_ERR_FUNDS" && {(_notTreasurer select 0) == "STR_PMCS_ERR_NOT_TREASURER"} && {_groupAfter == 600}
    && {(_noBox select 0) == "STR_PMCS_ERR_NO_BOX"} && {(_far select 0) == "STR_PMCS_ERR_FAR"}
    && {((PMCB_accounts get "76561100000000001") select 0) == 1440} && {count (_box getVariable ["TEST_weapons", []]) == _before + 1},
    "refused: not enough money, the group's account without being a treasurer, no box standing at the point, too far from the laptop - nothing charged or delivered; a treasurer pays from the group's account"] call TEST_fnc_assert;

// --- Zeus management ---------------------------------------------------------------------------------------
TEST_messages = [];
private _adminLaptop = "Land_Laptop_unfolded_F" createVehicle [2, 0, 0];
[_adminLaptop, "admin", ""] call PMCS_fnc_registerTerminal;
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 3]] call PMCS_fnc_admin;
private _refused = (((["PMCS_fnc_notify"] call TEST_sent) select 0) select 0) select 0;
_buyer setVariable ["TEST_curator", _buyer];
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 3]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "category", ["штурмовая винтовка", 15]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "category", ["assault", 15]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "category", ["ammo", 5]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "global", [95]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "box", [40]] call PMCS_fnc_admin;
[_buyer, _adminLaptop, "item", ["MMM_mag_545x39_6L23_Plastic_7N22", false, 12, 0, -1]] call PMCS_fnc_admin;
PMCB_accounts get "76561100000000001" set [0, 100000];
[_buyer, _laptop, "personal", [["rhs_weap_pkm", "rhs_weap_pkm", 2, false], ["MMM_mag_545x39_6L23_Plastic_7N22", "MMM_mag_545x39_6L23_Plastic_7N22", 10, false],
    ["MMM_mag_545x39_6L23_Plastic_7N22", "MMM_mag_545x39_6L23_Plastic_7N22", 1, true]]] call PMCS_fnc_buy;
private _paid = 100000 - ((PMCB_accounts get "76561100000000001") select 0);
private _left = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
private _mags = 0;
{if ((_x select 0) == "MMM_mag_545x39_6L23_Plastic_7N22") then {_mags = _mags + (_x select 1)}} forEach (_box getVariable ["TEST_mags", []]);
[_buyer, _laptop, "personal", [["rhs_weap_pkm", "rhs_weap_pkm", 2, false]]] call PMCS_fnc_buy;
private _stock = ([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0;
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 3]] call PMCS_fnc_admin;
private _kept = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 5]] call PMCS_fnc_admin;
private _restocked = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
[_refused == "STR_PMCS_ERR_ZEUS" && {_left == 1} && {(_stock select 0) == "STR_PMCS_ERR_STOCK"} && {_kept == 1} && {_restocked == 5}
    && {((PMCS_market get "cats") get "штурмовая винтовка") == 15} && {!("assault" in (PMCS_market get "cats"))} && {((PMCS_market get "cats") get "ammo") == 5}
    && {(PMCS_market get "global") == 0} && {!("box" in PMCS_market)} && {_mags == 10 + 30} && {_paid == 2 * 1280 + 10 * round (12 * 1.3 * 0.95) + round (12 * 30 * 0.95)},
    "Zeus only: a limited quantity sells down (3 -> 1, then not enough), stays when only the price changes, restocks when the quantity changes; discounts by the table's weapon category and on ammunition (a price type and the old box discount are refused); a price for a magazine puts it on sale, a box of it is 30; a 95% discount is refused"] call TEST_fnc_assert;

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
private _reloaded = ((PMCS_market get "items") get "rhs_weap_pkm") isEqualTo [false, -1, 0, 5, 5] && {((PMCS_market get "cats") get "ammo") == 5} && {count (PMCS_market get "log") == _log};
// A reload in the same session forgets the laptops (the game registers them once at start).
[_adminLaptop, "admin", ""] call PMCS_fnc_registerTerminal;
[_buyer, _adminLaptop, "reset", []] call PMCS_fnc_admin;
private _reset = count keys (PMCS_market get "items") == 0 && {count keys (PMCS_market get "cats") == 0} && {count (PMCS_market get "log") == _log + 1};
profileNamespace setVariable [_key, [1, "broken"]];
PMCS_market = nil;
call PMCS_fnc_serverLoad;
private _blocked = PMCS_saveBlocked && {!(call PMCS_fnc_save)} && {(profileNamespace getVariable _key) isEqualTo [1, "broken"]};
// Right shape, one bad entry (a 95% discount): refused as a whole.
private _badEntry = [[2, [["rhs_weap_ak74", [false, -1, 95, -1, -1]]], [], [], 0, []]] call PMCS_fnc_marketUnpack;
private _badCat = [[2, [], [], [["ammo", 95]], 0, []]] call PMCS_fnc_marketUnpack;
private _goodEntry = [[2, [["rhs_weap_ak74", [false, -1, 50, -1, -1]]], [], [["ammo", 10]], 0, []]] call PMCS_fnc_marketUnpack;
_blocked = _blocked && {isNil "_badEntry"} && {isNil "_badCat"} && {!isNil "_goodEntry"} && {((_goodEntry get "cats") get "ammo") == 10};
// A market saved by 0.1.0 under its own key: taken over without its box discount and price-type discounts.
profileNamespace setVariable [_key, nil];
private _oldKey = "PMCS_market_v1_" + (_key select [15]);
profileNamespace setVariable [_oldKey, [1, [["rhs_weap_ak74", [false, 300, 0, -1, -1]]], [], [["assault", 20]], 10, 25, [["t", "w", "x"]]]];
PMCS_market = nil;
call PMCS_fnc_serverLoad;
private _migrated = !PMCS_saveBlocked && {((PMCS_market get "items") get "rhs_weap_ak74") isEqualTo [false, 300, 0, -1, -1]} && {count keys (PMCS_market get "cats") == 0}
    && {(PMCS_market get "global") == 10} && {!("box" in PMCS_market)} && {count (PMCS_market get "log") == 1} && {(([PMCS_market] call PMCS_fnc_marketPack) select 0) == 2};
profileNamespace setVariable [_oldKey, nil];
[_reloaded && {_reset} && {_blocked} && {_migrated} && {_key find "PMCS_market_v2_" == 0} && {(_key find "TestMission") > 0},
    "saved per mission (key with mission and map): reloaded as it was, journal included; reset to the catalog keeps the journal; a damaged record is left on disk and nothing is saved over it; a 0.1.0 market is taken over without the box discount"] call TEST_fnc_assert;

// --- The shop's grid --------------------------------------------------------------------------------------
PMCS_market = call PMCS_fnc_marketNew;
(PMCS_market get "items") set ["rhs_weap_akm", [true, -1, 0, -1, -1]];
PMCS_ui = createHashMapFromArray [["market", PMCS_market], ["tab", "weapons"], ["search", ""], ["offTypes", []], ["offCals", []], ["sort", 1]];
([] call PMCS_fnc_uiShopList) params ["_shown", "_types", "_cals"];
PMCS_ui set ["offCals", ["5.45x39 АК"]];
private _noAk = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["offCals", []];
PMCS_ui set ["offTypes", ["единый пулемет"]];
private _noMg = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["offTypes", []];
PMCS_ui set ["search", "mmm_weap_ak74_h2"];
private _found = ([] call PMCS_fnc_uiShopList) select 0;
[(_shown select 0) == "rhs_weap_pkm" && {!("rhs_weap_akm" in _shown)} && {!("uk3cb_saiga12k" in _shown)} && {"rhs_weap_ak74" in _shown}
    && {!("rhs_weap_ak74" in _noAk)} && {!("rhs_weap_pkm" in _noMg)} && {"rhs_weap_ak74" in _noMg} && {_found isEqualTo ["rhs_weap_ak74"]}
    && {(_types get "штурмовая винтовка") == 2} && {(_types get "единый пулемет") == 1} && {(_cals get "5.45x39 АК") == 2} && {(_types get "dmr") == 1},
    "weapons grid: dearest box first, hidden and unpriced items left out, filters by the table's weapon category and by calibre, search by a variant's class, counts per category and calibre"] call TEST_fnc_assert;

// Ammunition: the grid lists calibres; the filter is the ammo type.
(PMCS_market get "items") set ["MMM_mag_545x39_6L20_7N6M", [false, 15, 0, -1, -1]];
(PMCS_market get "items") set ["MMM_mag_545x39_6L23_Plastic_7N22", [false, 20, 0, -1, -1]];
PMCS_ui set ["tab", "ammo"];
PMCS_ui set ["search", ""];
([] call PMCS_fnc_uiShopList) params ["_calibres", "_ammoTypes"];
PMCS_ui set ["offTypes", ["Ball"]];
private _apOnly = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["offTypes", ["Ball", "AP"]];
private _none = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["offTypes", []];
PMCS_ui set ["search", "7n22"];
private _byClass = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["search", ""];
[_calibres isEqualTo ["5.45x39 АК"] && {(_ammoTypes get "Ball") == 1} && {(_ammoTypes get "AP") == 1} && {!("Trace" in _ammoTypes)}
    && {_apOnly isEqualTo ["5.45x39 АК"]} && {_none isEqualTo []} && {_byClass isEqualTo ["5.45x39 АК"]}
    && {(["5.45x39 АК"] call PMCS_fnc_uiCalibreMags) isEqualTo ["MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L23_Plastic_7N22"]}
    && {(["7.62x54R ПКМ"] call PMCS_fnc_uiCalibreMags) isEqualTo []},
    "ammunition grid: a calibre card when it has a priced magazine, the ammo type filter keeps a calibre while one of its types is ticked, search by a magazine's class; the calibre's magazines on sale"] call TEST_fnc_assert;

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

private _boxFirst = (PMCS_ui get "pack") == "box" && {(["pack", ["unit"]] call TEST_byEvent) isNotEqualTo []} && {(["1 000 $"] call TEST_byText) isNotEqualTo []};
[(["add"] call TEST_byEvent) select 0] call TEST_click;
[(["variant", ["MMM_weap_AK74_H2S1"]] call TEST_byEvent) select 0] call TEST_click;
[(["pack", ["unit"]] call TEST_byEvent) select 0] call TEST_click;
[(["qty", [1]] call TEST_byEvent) select 0] call TEST_click;
private _unitShown = ((["detail"] call TEST_region) select {"400 $" in (_x getVariable ["TEST_text", ""])}) isNotEqualTo [];
[(["add"] call TEST_byEvent) select 0] call TEST_click;
private _cart = +(PMCS_ui get "cart");
[(["checkout"] call TEST_byEvent) select 0] call TEST_click;
private _request = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_buy"}) select 0;
call TEST_serve;
private _inBox = (_shopBox getVariable ["TEST_weapons", []]) apply {_x select 0};
[_boxFirst && {_unitShown} && {_cart isEqualTo [["rhs_weap_ak74", "rhs_weap_ak74", 1, true], ["rhs_weap_ak74", "MMM_weap_AK74_H2S1", 2, false]]}
    && {((_request select 0) select 2) == "personal"} && {((PMCB_accounts get "76561100000000002") select 0) == 10000 - 1000 - 800}
    && {({_x == "rhs_weap_ak74"} count _inBox) == 4} && {({_x == "MMM_weap_AK74_H2S1"} count _inBox) == 2} && {(PMCS_ui get "cart") isEqualTo []},
    "shop: a box is the default (1 000 for 4); add a box, pick a variant, switch to single pieces (400 each), two of them; check out pays 1 800 from the personal account, the box gets 4 + 2 of the chosen variant, the cart empties"] call TEST_fnc_assert;

private _filterOf = {params ["_kind", "_key"]; (([] call TEST_live) select {(_x getVariable ["PMCS_filter", []]) isEqualTo [_kind, _key]}) select 0};
private _calCheck = ["cal", "5.45x39 АК"] call _filterOf;
[_calCheck, 0] call (_calCheck getVariable "TEST_eh_CheckedChanged");
private _without = PMCS_ui get "shown";
[_calCheck, 1] call (_calCheck getVariable "TEST_eh_CheckedChanged");
private _catCheck = ["type", "штурмовая винтовка"] call _filterOf;
[_catCheck, 0] call (_catCheck getVariable "TEST_eh_CheckedChanged");
private _noAssault = PMCS_ui get "shown";
[_catCheck, 1] call (_catCheck getVariable "TEST_eh_CheckedChanged");
{(PMCS_market get "items") set [_x select 0, [false, _x select 1, 0, -1, -1]]} forEach [["MMM_mag_545x39_6L20_7N6M", 15], ["MMM_mag_545x39_6L23_Plastic_7N6M", 16],
    ["MMM_mag_545x39_6L23_Plastic_7N22", 20]];
call PMCS_fnc_broadcast;
call TEST_serve;
[(["select", ["rhs_weap_ak74"]] call TEST_byEvent) select 0] call TEST_click;
// Step 1: the ammo types the calibre has on sale; step 2: the magazines of that type.
private _typeChips = [["Ball", "Trace", "AP"], {(["ammoType", [_x]] call TEST_byEvent) isNotEqualTo []}] call {params ["_t", "_f"]; _t apply _f};
private _ballMags = ["MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L23_Plastic_7N6M"] apply {count (["mag", [_x]] call TEST_byEvent)};
private _firstMag = PMCS_ui get "mag";
[(["ammoType", ["AP"]] call TEST_byEvent) select 0] call TEST_click;
private _apMag = PMCS_ui get "mag";
private _apChips = count ((["detail"] call TEST_region) select {((_x getVariable ["PMCS_event", []]) param [0, ""]) == "mag"});
[(["magPack", ["unit"]] call TEST_byEvent) select 0] call TEST_click;
[(["magQty", [1]] call TEST_byEvent) select 0] call TEST_click;
[(["magAdd"] call TEST_byEvent) select 0] call TEST_click;
[(["ammoType", ["Ball"]] call TEST_byEvent) select 0] call TEST_click;
[(["mag", ["MMM_mag_545x39_6L23_Plastic_7N6M"]] call TEST_byEvent) select 0] call TEST_click;
[(["magPack", ["box"]] call TEST_byEvent) select 0] call TEST_click;
[(["magAdd"] call TEST_byEvent) select 0] call TEST_click;
private _magCart = +(PMCS_ui get "cart");
[_typeChips isEqualTo [true, false, true] && {_ballMags isEqualTo [1, 1]} && {_firstMag == "MMM_mag_545x39_6L20_7N6M"} && {_apMag == "MMM_mag_545x39_6L23_Plastic_7N22"}
    && {_apChips == 1} && {(({"rhs_weap_ak74" == _x} count _without) == 0)} && {!("rhs_weap_ak74" in _noAssault)} && {"rhs_weap_pkm" in _noAssault}
    && {_magCart isEqualTo [["MMM_mag_545x39_6L23_Plastic_7N22", "MMM_mag_545x39_6L23_Plastic_7N22", 2, false], ["MMM_mag_545x39_6L23_Plastic_7N6M", "MMM_mag_545x39_6L23_Plastic_7N6M", 2, true]]},
    "shop: the calibre and category boxes hide the AK; the AK's card offers its calibre's ammunition: the types on sale (no tracers), then the magazines of the chosen type, then box or single pieces"] call TEST_fnc_assert;

[PMCS_ui get "tabAmmo"] call TEST_click;
private _ammoCards = (["grid"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_ButtonClear"};
private _ammoShown = +(PMCS_ui get "shown");
private _fits = (((["detail"] call TEST_region) select {(_x getVariable ["TEST_text", ""]) == "5.45x39 АК"}) isNotEqualTo []) && {(["STR_PMCS_FITS"] call TEST_byText) isNotEqualTo []};
private _typeCheck = ["type", "AP"] call _filterOf;
[_typeCheck, 0] call (_typeCheck getVariable "TEST_eh_CheckedChanged");
private _stillThere = +(PMCS_ui get "shown");
[_typeCheck, 1] call (_typeCheck getVariable "TEST_eh_CheckedChanged");
[(["magAdd"] call TEST_byEvent) select 0] call TEST_click;
[(["cartOpen"] call TEST_byEvent) select 0] call TEST_click;
private _rows = count (((["overlay"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0 getVariable ["TEST_rows", []]);
[(["cartQty", [1]] call TEST_byEvent) select 0] call TEST_click;
private _three = ((PMCS_ui get "cart") select 0) select 2;
[(["cartRemove", []] call TEST_byEvent) select 0] call TEST_click;
private _afterRemove = (PMCS_ui get "cart") apply {_x select 0};
[(["checkout"] call TEST_byEvent) select 0] call TEST_click;
call TEST_serve;
private _boxMags = createHashMap;
{_boxMags set [_x select 0, (if ((_x select 0) in _boxMags) then {_boxMags get (_x select 0)} else {0}) + (_x select 1)]} forEach (_shopBox getVariable ["TEST_mags", []]);
[(["select", [_ammoShown select 0]] call TEST_byEvent) select 0] call TEST_click;
[(["magAdd"] call TEST_byEvent) select 0] call TEST_click;
private _beforeClear = count (PMCS_ui get "cart");
[(["cartClear", []] call TEST_byEvent) select 0] call TEST_click;
[count _ammoCards == 1 && {_ammoShown isEqualTo ["5.45x39 АК"]} && {_fits} && {_stillThere isEqualTo ["5.45x39 АК"]} && {_rows == 3} && {_three == 3}
    && {_afterRemove isEqualTo ["MMM_mag_545x39_6L23_Plastic_7N6M", "MMM_mag_545x39_6L20_7N6M"]}
    && {(_boxMags get "MMM_mag_545x39_6L23_Plastic_7N6M") == 60} && {(_boxMags get "MMM_mag_545x39_6L20_7N6M") == 60}
    && {((PMCB_accounts get "76561100000000002") select 0) == 8200 - 2 * 480 - 2 * 450} && {_beforeClear == 1} && {(PMCS_ui get "cart") isEqualTo []},
    "ammunition tab: a card per calibre, what it fits; the type filter; a box of magazines from the calibre's card; the cart window changes and removes lines; two boxes each give 60 magazines for 1 860"] call TEST_fnc_assert;

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
TEST_tableRows = {(((["table"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0) getVariable ["TEST_rows", []]};
["set", ["acal", "7.62x54R ПКМ"]] call PMCS_fnc_uiAdmin;
private _pkmRows = [] call TEST_tableRows;
["set", ["asection", "mag"]] call PMCS_fnc_uiAdmin;
private _magRows = [] call TEST_tableRows;
["set", ["acal", "5.45x39 АК"]] call PMCS_fnc_uiAdmin;
private _magRows545 = [] call TEST_tableRows;
["set", ["asection", "weapon"]] call PMCS_fnc_uiAdmin;
_table = ((["table"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0;
private _calColumns = count _pkmRows == 2 && {"7.62x54R ПКМ" in ((_pkmRows select 1) select 0)} && {"Единые пулемёты" in ((_pkmRows select 1) select 0)}
    && {count _magRows == 5} && {count _magRows545 == 4} && {(_magRows545 findIf {"STR_PMCS_AMMO_AP" in (_x select 0) && {"5.45x39 АК" in (_x select 0)}}) > 0};
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
PMCS_ui set ["acat", "штурмовая винтовка"];
["refresh"] call PMCS_fnc_uiAdmin;
private _catOk = (["discount", ["category", ["штурмовая винтовка"]]] call TEST_byEvent) select 0;
(_catOk getVariable "PMCS_edit") setVariable ["TEST_text", "7"];
[_catOk] call TEST_click;
call TEST_serve;
private _catRows = [] call TEST_tableRows;
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
[_tableRows == 7 && {_calColumns} && {((PMCS_market get "cats") get "штурмовая винтовка") == 7} && {count _catRows == 1 + count ((call PMCS_fnc_catalog) get "categories") + 2}
    && {_picked == "rhs_weap_ak74"} && {_set isEqualTo [false, 300, 10, 4, 4]} && {(PMCS_market get "global") == 12}
    && {(_foundVal select 0) == "AS Val"} && {((PMCS_market get "items") get "x_rhs_weap_asval") isEqualTo [false, 700, 0, 2, 2]} && {_armed == 0}
    && {count (_log getVariable ["TEST_rows", []]) == 1 + count (PMCS_market get "log")},
    "management: the table lists the goods with category and calibre columns, filtered by calibre (weapons and magazines with their ammo type); the chosen one gets price, discount and a limited quantity; a market discount and one for a weapon category of the table; a class found in the game and added; reset waits for a second click; the journal lists every change"] call TEST_fnc_assert;
["onUnload", []] call PMCS_fnc_ui;

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];
