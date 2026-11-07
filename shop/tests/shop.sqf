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
    ["Common", "matchCaptures"], ["Common", "ownerPattern"], ["Common", "parts"], ["Common", "upgrades"], ["Common", "upgradesFor"], ["Common", "upgradeTarget"],
    ["Server", "upgrade"], ["Server", "upgradeDone"], ["Client", "upgradeApply"],
    ["Common", "gearItems"], ["Common", "gearTake"], ["Common", "gearUpgrades"], ["Common", "gearUpgradesFor"], ["Common", "itemTitle"],
    ["Server", "gearUpgrade"], ["Client", "gearApply"],
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
private _variants = _ak select 7;
private _bake = if ("rhs_30Rnd_762x39mm_bakelite_89" in _items) then {_items get "rhs_30Rnd_762x39mm_bakelite_89"} else {[]};
private _poly = if ("rhs_30Rnd_762x39mm_polymer_89" in _items) then {_items get "rhs_30Rnd_762x39mm_polymer_89"} else {[]};
private _rpgTypes = getArray (configFile >> "CfgPMCShop" >> "Magazines" >> "rhs_rpg7_PG7VM_mag" >> "types");
[(_variants apply {[_x select 0, _x select 1, _x select 3]}) isEqualTo [["rhs_weap_ak74", "AK-74", ["rhs_weap_ak74"]], ["MMM_weap_AK74_H*S*", "MMM", ["MMM_weap_AK74_H1S1", "MMM_weap_AK74_H2S1"]]]
    && {(_ak select 5) == 250} && {(_ak select 2) == "штурмовая винтовка"} && {(_ak select 3) == "5.45x39 АК"}
    && {"rhs_weap_akm" in _items} && {!("rhs_weap_m4a1_carryhandle" in _items)} && {((_items get "rhs_weap_pkm") select 5) == 450}
    && {((_items get "rhs_weap_svds") select 5) == 500} && {((_items get "uk3cb_saiga12k") select 5) == 250}
    && {(((_items get "rhs_weap_ak74n") select 7) apply {_x select 0}) isEqualTo ["MMM_weap_AK74N_H*S*"]}
    && {getText (configFile >> "CfgPMCShop" >> "Weapons" >> "MMM_weap_RPG18" >> "caliber") == ""}
    && {(_catalog get "categories") findIf {(_x select 0) == "единый пулемет"} >= 0}
    && {(["единый пулемет"] call PMCS_fnc_categoryName) == "Единые пулемёты"} && {(["ammo"] call PMCS_fnc_categoryName) == "STR_PMCS_TAB_AMMO"}
    && {((_catalog get "calibres") get "7.62x39 АК") isEqualTo ["rhs_30Rnd_762x39mm_bakelite_89", "rhs_30Rnd_762x39mm_polymer_89"]}
    && {((_catalog get "calibres") get "5.45x39 АК") isEqualTo ["MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L23_Plastic_7N6M"]}
    && {(_bake select 5) == 15} && {(_bake select 8) == "30 патр. Бакелит"} && {(_bake select 1) == "7.62x39 АК 30 патр. Бакелит"}
    && {((_bake select 7) apply {[_x select 0, _x select 1, _x select 4]}) isEqualTo [
        ["rhs_30Rnd_762x39mm_bakelite_89", "STR_PMCS_AMMO_Ball", 1], ["rhs_30Rnd_762x39mm_bakelite_tracer", "STR_PMCS_AMMO_Trace", 1.1],
        ["rhs_30Rnd_762x39mm_bakelite_U", "STR_PMCS_AMMO_special", 4]]}
    && {((_poly select 7) apply {_x select 0}) isEqualTo ["rhs_30Rnd_762x39mm_polymer_89"]} && {((_items get "rhs_100Rnd_762x54mmR") select 5) == 170}
    && {(_rpgTypes findIf {(_x select 2) == "82mm"}) >= 0},
    "catalog: the base weapons the game has with the table's price, category and calibre, an MMM pattern one 'MMM' version with every class that fits; single-use launchers without a calibre; a magazine row per calibre and magazine, its price, its ammo types (classes the game has) with the table's factors; the RPG-7's '82mm' is a class and is kept"] call TEST_fnc_assert;

// --- Prices: a box is the base, one piece costs more; ammo types cost more; discounts ------------------
private _market = call PMCS_fnc_marketNew;
private _p0 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
private _pVar = ["rhs_weap_ak74", _market, "rhs_weap_ak74"] call PMCS_fnc_price;
(_market get "items") set ["rhs_weap_ak74", [false, -1, 10, -1, -1]];
private _p1 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
(_market get "cats") set ["штурмовая винтовка", 20];
private _p2 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
_market set ["global", 30];
private _p3 = ["rhs_weap_ak74", _market] call PMCS_fnc_price;
(_market get "items") set ["rhs_weap_akm", [true, -1, 0, -1, -1]];
(_market get "items") set ["rhs_weap_pkm", [false, 900, 0, 2, 0]];
private _hidden = (["rhs_weap_akm", _market] call PMCS_fnc_price) select 0;
private _soldout = ["rhs_weap_pkm", _market] call PMCS_fnc_price;
private _magMarket = call PMCS_fnc_marketNew;
private _bakeKey = "rhs_30Rnd_762x39mm_bakelite_89";
private _magPrice = [_bakeKey, _magMarket] call PMCS_fnc_price;
private _magTrace = [_bakeKey, _magMarket, "rhs_30Rnd_762x39mm_bakelite_tracer"] call PMCS_fnc_price;
private _magSpecial = [_bakeKey, _magMarket, "rhs_30Rnd_762x39mm_bakelite_U"] call PMCS_fnc_price;
(_magMarket get "items") set [_bakeKey, [false, 20, 0, -1, -1]];
private _magOwn = [_bakeKey, _magMarket, "rhs_30Rnd_762x39mm_bakelite_U"] call PMCS_fnc_price;
(_magMarket get "items") deleteAt _bakeKey;
(_magMarket get "cats") set ["ammo", 10];
private _magOff = [_bakeKey, _magMarket] call PMCS_fnc_price;
// The box sizes and the single-piece rules are CBA settings.
PMCS_weaponBoxUnits = 5; PMCS_weaponUnitMarkup = 100; PMCS_magBoxUnits = 20; PMCS_magUnitMarkup = 100;
private _cbaWeapon = ["uk3cb_saiga12k", call PMCS_fnc_marketNew] call PMCS_fnc_price;
private _cbaAk = ["rhs_weap_ak74", call PMCS_fnc_marketNew] call PMCS_fnc_price;
private _cbaMag = [_bakeKey, _magMarket] call PMCS_fnc_price;
PMCS_weaponBoxUnits = nil; PMCS_weaponUnitMarkup = nil; PMCS_magBoxUnits = nil; PMCS_magUnitMarkup = nil;
private _boxes = ["rhs_weap_ak74", "rhs_weap_pkm", "rhs_weap_svds", "uk3cb_saiga12k", "rhs_6b23_ML"] apply {(([_x, call PMCS_fnc_marketNew] call PMCS_fnc_price) select 5)};
[_p0 isEqualTo ["ok", 400, 3000, 0, -1, 12] && {_pVar isEqualTo _p0} && {_p1 isEqualTo ["ok", 360, 2700, 10, -1, 12]} && {_p2 isEqualTo ["ok", 320, 2400, 20, -1, 12]}
    && {_p3 isEqualTo ["ok", 280, 2100, 30, -1, 12]} && {_boxes isEqualTo [12, 4, 4, 4, 4]} && {_hidden == "hidden"} && {_soldout isEqualTo ["soldout", 1008, 2520, 30, 0, 4]}
    && {_magPrice isEqualTo ["ok", 20, 450, 0, -1, 30]} && {_magTrace isEqualTo ["ok", 21, 495, 0, -1, 30]}
    && {_magSpecial isEqualTo ["ok", 78, 1800, 0, -1, 30]} && {(_magOwn select 2) == 20 * 4 * 30}
    && {_magOff isEqualTo ["ok", 18, 405, 10, -1, 30]} && {_cbaWeapon isEqualTo ["ok", 500, 1250, 0, -1, 5]} && {(_cbaAk select 5) == 12} && {(_cbaAk select 1) == 500} && {_cbaMag isEqualTo ["ok", 27, 270, 10, -1, 20]},
    "price: a box at the base price, its size by category (assault rifles 12: 12 x 250 = 3 000, GPMG, DMR, vests 4, no box discount), one weapon or vest +60% (400); box sizes for other categories and markups from CBA; a magazine row's box of 30 at its price (15: 450), one +30% (20); a tracer x1.1 (495), special x4 (1 800), also on a Zeus's own price; one discount - the largest of item 10, category 20, market 30; box sizes and single-piece rules from CBA; hidden, sold out"] call TEST_fnc_assert;

// --- Cart quote -----------------------------------------------------------------------------------------
_market = call PMCS_fnc_marketNew;
(_market get "items") set ["rhs_weap_pkm", [false, -1, 0, 3, 3]];
(_market get "items") set ["rhs_weap_akm", [true, -1, 0, -1, -1]];
private _q1 = [[["rhs_weap_ak74", "rhs_weap_ak74", 1, true], ["rhs_weap_pkm", "rhs_weap_pkm", 2, false]], _market] call PMCS_fnc_quote;
private _q2 = [[["rhs_weap_ak74", "rhs_weap_akm", 1, false]], _market] call PMCS_fnc_quote;
private _q3 = [[["rhs_weap_pkm", "rhs_weap_pkm", 2, false], ["rhs_weap_pkm", "rhs_weap_pkm", 2, false]], _market] call PMCS_fnc_quote;
private _q4 = [[["rhs_weap_ak74", "rhs_weap_ak74", 0, false]], _market] call PMCS_fnc_quote;
private _q5 = [[["rhs_weap_akm", "rhs_weap_akm", 1, false]], _market] call PMCS_fnc_quote;
private _q6 = [[["rhs_weap_pkm", "rhs_weap_pkm", 1, true]], _market] call PMCS_fnc_quote;
private _q7 = [[["rhs_weap_ak74", "MMM_weap_AK74_H1S1", 1, true]], _market] call PMCS_fnc_quote;
private _q8 = [[[_bakeKey, "rhs_30Rnd_762x39mm_bakelite_U", 1, true], [_bakeKey, _bakeKey, 2, false]], _market] call PMCS_fnc_quote;
[(_q1 select 0) == 3000 + 2 * 720 && {((_q1 select 1) get "rhs_weap_ak74") == 12} && {(_q1 select 2) == ""} && {(_q2 select 2) == "STR_PMCS_ERR_CART"}
    && {(_q3 select 2) == "STR_PMCS_ERR_STOCK"} && {(_q4 select 2) == "STR_PMCS_ERR_CART"} && {(_q5 select 2) == "STR_PMCS_ERR_UNAVAILABLE"}
    && {(_q6 select 2) == "STR_PMCS_ERR_STOCK"} && {(_q7 select 2) == "STR_PMCS_ERR_CART"} && {(_q8 select 0) == 1800 + 2 * 20}
    && {((_q8 select 1) get _bakeKey) == 32} && {(([[], _market] call PMCS_fnc_quote) select 2) == "STR_PMCS_ERR_CART"},
    "quote: a box (12 assault rifles) and single pieces priced; a special-ammo box (x4) and two ball magazines; a box counts its pieces against the stock (3 left); another item's class (an MMM one included), zero, an empty cart, more than is left and a hidden item are refused"] call TEST_fnc_assert;

// --- Gunsmith: class mapping and undo ------------------------------------------------------------------
private _byKey = {params ["_k"]; ((call PMCS_fnc_upgrades) select {(_x select 0) == _k}) param [0, []]};
private _gp = ["rhs_weap_ak74__rhs_weap_ak74_gp25"] call _byKey;
private _mr = ["rhs_weap_ak74__rhs_weap_ak74mr"] call _byKey;
private _mrGp = ["rhs_weap_ak74_gp25__rhs_weap_ak74mr_gp25"] call _byKey;
private _undo = ["rev:rhs_weap_ak74__rhs_weap_ak74mr"] call _byKey;
private _for = ["rhs_weap_ak74"] call PMCS_fnc_upgradesFor;
private _forMr = (["rhs_weap_ak74mr"] call PMCS_fnc_upgradesFor) apply {[(_x select 0) select 0, _x select 1]};
// Patterns (none left in the table once MMM is gone) still work: a test pattern list.
PMCS_owners = createHashMap;
PMCS_patterns = ["X_weap_AK74_H*S*_GP25", "X_weap_AK74_H*S*"];
private _pairs = [["X_weap_AK74_H*S*", "rhs_weap_ak74mr"]];
private _patternOwner = (["X_weap_AK74_H1S1_GP25"] call PMCS_fnc_ownerPattern) == "x_weap_ak74_h*s*_gp25" && {(["X_weap_AK74_H1S1"] call PMCS_fnc_ownerPattern) == "x_weap_ak74_h*s*"};
private _patternTarget = (["X_weap_AK74_H1S1_GP25", _pairs] call PMCS_fnc_upgradeTarget) == "" && {(["X_weap_AK74_H1S1", _pairs] call PMCS_fnc_upgradeTarget) == "rhs_weap_ak74mr"};
PMCS_owners = nil;
PMCS_patterns = nil;
[(["MMM_weap_AK74_H2S1", "MMM_weap_AK74_H*S*"] call PMCS_fnc_matchCaptures) isEqualTo [true, ["2", "1"]]
    && {(["mmm_weap_ak74_h2s1_gp25", "MMM_weap_AK74_H*S*_GP25"] call PMCS_fnc_matchCaptures) isEqualTo [true, ["2", "1"]]}
    && {((["MMM_weap_AK74N_H1S1", "MMM_weap_AK74_H*S*"] call PMCS_fnc_matchCaptures) select 0) isEqualTo false}
    && {((["MMM_weap_AKS74_H1_Long", "MMM_weap_AKS74_H*_GP25"] call PMCS_fnc_matchCaptures) select 0) isEqualTo false}
    && {_patternOwner} && {_patternTarget}
    && {(_gp select 7) isEqualTo [["rhs_weap_ak74", "rhs_weap_ak74_gp25"], ["MMM_weap_AK74_H*S*", "MMM_weap_AK74_H*S*_GP25"]]} && {(_gp select 6) isEqualTo [0, 1, 0]}
    && {(["MMM_weap_AK74_H1S1_GP25"] call PMCS_fnc_ownerPattern) == "mmm_weap_ak74_h*s*_gp25"}
    && {(["MMM_weap_AK74_H2S1", _gp select 7] call PMCS_fnc_upgradeTarget) == "MMM_weap_AK74_H2S1_GP25"} && {(["MMM_weap_AK74_H1S1", _gp select 7] call PMCS_fnc_upgradeTarget) == ""}
    && {(["MMM_weap_AK74_H1S1", _mr select 7] call PMCS_fnc_upgradeTarget) == "rhs_weap_ak74mr"} && {(["MMM_weap_AK74_H2S1_GP25", _mr select 7] call PMCS_fnc_upgradeTarget) == ""}
    && {(["MMM_weap_AK74_H2S1_GP25", (["rev:rhs_weap_ak74__rhs_weap_ak74_gp25"] call _byKey) select 7] call PMCS_fnc_upgradeTarget) == "MMM_weap_AK74_H2S1"}
    && {(_mr select 5) == 300} && {(_mr select 6) isEqualTo [1, 3, 0]} && {(_mrGp select 5) == 300} && {(_mrGp select 6) isEqualTo [1, 3, 0]}
    && {(["rhs_weap_ak74", _mr select 7] call PMCS_fnc_upgradeTarget) == "rhs_weap_ak74mr"} && {(["rhs_weap_akm", _mr select 7] call PMCS_fnc_upgradeTarget) == ""}
    && {(_undo select 3) == "rev"} && {(_undo select 5) == 0} && {(_undo select 6) isEqualTo [0, 0, 0]} && {(_undo select 2) == "АК-74"}
    && {(_for apply {(_x select 0) select 0}) isEqualTo ["rhs_weap_ak74__rhs_weap_ak74_gp25", "rhs_weap_ak74__rhs_weap_ak74mr"]}
    && {_forMr isEqualTo [["rhs_weap_ak74mr__rhs_weap_ak74mr_gp25", "rhs_weap_ak74mr_gp25"], ["rev:rhs_weap_ak74__rhs_weap_ak74mr", "rhs_weap_ak74"]]}
    && {(["rhs_weap_pkm"] call PMCS_fnc_upgradesFor) isEqualTo []} && {count ((call PMCS_fnc_upgrades) select {(_x select 3) != "rev"}) == 72}
    && {count ((call PMCS_fnc_upgrades) select {(_x select 3) == "rev"}) == 72}
    && {!("MMM_weap_AK74_H2S1_GP25" in ((((call PMCS_fnc_catalog) get "items") get "rhs_weap_ak74") select 7 select 1 select 3))},
    "gunsmith classes: what each '*' stood for, the most specific pattern owns a class; AK-74 -> AK-74MR and AK-74 GP-25 -> AK-74MR GP-25 both 300 $ + 1 low + 3 medium; an MMM AK-74 gets its own GP-25 version and back, the GP-25 version is not in the plain AK-74's pool; every upgrade has a free undo (the AK-74MR offers its next upgrade and the way back to the AK-74, not to the AKS-74 the game lacks); 72 upgrades"] call TEST_fnc_assert;

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
[_buyer, _laptop, "personal", [["rhs_weap_ak74", "rhs_weap_ak74", 1, true], ["rhs_weap_pkm", "rhs_weap_pkm", 2, false]]] call PMCS_fnc_buy;
private _balance = (PMCB_accounts get "76561100000000001") select 0;
private _weapons = (_box getVariable ["TEST_weapons", []]) apply {_x select 0};
private _bankLog = PMCB_log select (count PMCB_log - 1);
[(_laptop getVariable "PMCS_mode") == "shop" && {(_laptop getVariable "PMCS_point") == "8Z8N"} && {(_jip select 1) isEqualTo ["PMCS_fnc_terminalInit", 0, _laptop]}
    && {_balance == 5000 - 3000 - 1440} && {({_x == "rhs_weap_ak74"} count _weapons) == 12} && {({_x == "rhs_weap_pkm"} count _weapons) == 2}
    && {(_bankLog select 4) == "shop"} && {(_bankLog select 5) == 4440} && {(_bankLog select 8) == "Buyer"}
    && {([["PMCS_fnc_receive"] call TEST_sent] call TEST_lastOf) select 0 select 2 == "bought"} && {count (PMCS_market get "log") == 1},
    "purchase: the laptop and box from their modules (point 8Z8N), the personal account charged 4 440 for a box and two single machine guns (PMC Bank journal: shop), the box holds 12 AK-74, the 2 single ones in the point's box, the client told"] call TEST_fnc_assert;

TEST_messages = [];
private _before = count (_box getVariable ["TEST_weapons", []]);
[_buyer, _laptop, "personal", [["rhs_weap_pkm", "rhs_weap_pkm", 4, false]]] call PMCS_fnc_buy;
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
    && {((PMCB_accounts get "76561100000000001") select 0) == 560} && {count (_box getVariable ["TEST_weapons", []]) == _before + 1},
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
[_buyer, _adminLaptop, "item", [_bakeKey, false, 12, 0, -1]] call PMCS_fnc_admin;
PMCB_accounts get "76561100000000001" set [0, 100000];
[_buyer, _laptop, "personal", [["rhs_weap_pkm", "rhs_weap_pkm", 2, false], [_bakeKey, "rhs_30Rnd_762x39mm_bakelite_U", 10, false],
    [_bakeKey, "rhs_30Rnd_762x39mm_bakelite_U", 1, true]]] call PMCS_fnc_buy;
private _paid = 100000 - ((PMCB_accounts get "76561100000000001") select 0);
private _left = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
private _mags = 0;
{if ((_x select 0) == "rhs_30Rnd_762x39mm_bakelite_U") then {_mags = _mags + (_x select 1)}} forEach (_box getVariable ["TEST_mags", []]);
// Five MMM boxes: each holds 4 of one class drawn for it.
private _mmmOf = {params ["_c"]; {_x select 0 == _c} count (_box getVariable ["TEST_weapons", []])};
private _h1Before = ["MMM_weap_AK74_H1S1"] call _mmmOf;
private _h2Before = ["MMM_weap_AK74_H2S1"] call _mmmOf;
TEST_randomDraws = 0;
[_buyer, _laptop, "personal", [["rhs_weap_ak74", "MMM_weap_AK74_H*S*", 5, true]]] call PMCS_fnc_buy;
private _draws = TEST_randomDraws;
private _h1Added = (["MMM_weap_AK74_H1S1"] call _mmmOf) - _h1Before;
private _akAdded = _h1Added + (["MMM_weap_AK74_H2S1"] call _mmmOf) - _h2Before;
[_buyer, _laptop, "personal", [["rhs_weap_pkm", "rhs_weap_pkm", 2, false]]] call PMCS_fnc_buy;
private _stock = ([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0;
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 3]] call PMCS_fnc_admin;
private _kept = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
[_buyer, _adminLaptop, "item", ["rhs_weap_pkm", false, -1, 0, 5]] call PMCS_fnc_admin;
private _restocked = ((PMCS_market get "items") get "rhs_weap_pkm") select 4;
[_refused == "STR_PMCS_ERR_ZEUS" && {_left == 1} && {(_stock select 0) == "STR_PMCS_ERR_STOCK"} && {_kept == 1} && {_restocked == 5}
    && {((PMCS_market get "cats") get "штурмовая винтовка") == 15} && {!("assault" in (PMCS_market get "cats"))} && {((PMCS_market get "cats") get "ammo") == 5}
    && {(PMCS_market get "global") == 0} && {!("box" in PMCS_market)} && {_mags == 10 + 30} && {_paid == 2 * 720 + 10 * round (48 * 1.3 * 0.95) + round (48 * 30 * 0.95)} && {_akAdded == 60} && {_draws == 5} && {_h1Added == 36},
    "Zeus only: a limited quantity sells down (3 -> 1, then not enough), stays when only the price changes, restocks when the quantity changes; discounts by the table's weapon category and on ammunition (a price type and the old box discount are refused); a price for a magazine row (special x4), a box of it is 30; five MMM boxes of 12, a class drawn per box; a 95% discount is refused"] call TEST_fnc_assert;

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
// An item a Zeus added: no calibre.
(PMCS_market get "custom") set ["x_ItemGPS", ["item", "ItemGPS", "GPS", ""]];
(PMCS_market get "items") set ["x_ItemGPS", [false, 50, 0, -1, -1]];
PMCS_ui = createHashMapFromArray [["market", PMCS_market], ["tab", "weapons"], ["search", ""], ["selTypes", []], ["selCals", []], ["sort", 1]];
([] call PMCS_fnc_uiShopList) params ["_shown", "_types", "_cals"];
// Selected rows are what stays.
PMCS_ui set ["selCals", ["5.45x39 АК"]];
private _onlyAk = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["selCals", []];
PMCS_ui set ["selTypes", ["единый пулемет", "dmr"]];
private _mgDmr = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["selTypes", ["штурмовая винтовка"]];
PMCS_ui set ["selCals", ["7.62x54R ПКМ"]];
private _both = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["selTypes", []];
PMCS_ui set ["selCals", keys _cals];
private _allCals = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["selCals", []];
PMCS_ui set ["search", "rhs_weap_ak"];
private _found = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["search", ""];
[(_shown select 0) == "rhs_weap_ak74n" && {!("rhs_weap_akm" in _shown)} && {"uk3cb_saiga12k" in _shown} && {"rhs_weap_ak74" in _shown} && {"x_ItemGPS" in _shown}
    && {_onlyAk isEqualTo ["rhs_weap_ak74n", "rhs_weap_ak74"]} && {_mgDmr isEqualTo ["rhs_weap_svds", "rhs_weap_pkm"]} && {_both isEqualTo []}
    && {count _allCals == count _shown} && {_found isEqualTo ["rhs_weap_ak74"]}
    && {(_types get "штурмовая винтовка") == 2} && {(_types get "единый пулемет") == 1} && {(_cals get "5.45x39 АК") == 2} && {(_types get "dmr") == 1}
    && {!("" in _cals)} && {!("-" in _cals)} && {(_types get "custom") == 1},
    "weapons grid: dearest box first, hidden items left out; only the selected categories and calibres stay (both sections must match), nothing selected shows all, every calibre selected keeps the goods without one; search by class; counts per category and calibre, no row for goods without a calibre"] call TEST_fnc_assert;

// Equipment: base vests and their items; filter: the vest type.
PMCS_ui set ["tab", "gear"];
PMCS_ui set ["sort", 0];
([] call PMCS_fnc_uiShopList) params ["_gearRows", "_gearTypes", "_gearCals"];
[_gearRows isEqualTo ["rhs_6sh92_vsr", "USP_CRYE_BELT_PACK_MC", "rhs_6b23_ML"] && {(_gearTypes get "общевойсковой бж") == 1} && {(_gearTypes get "разгрузка") == 1}
    && {(_gearTypes get "боевой пояс") == 1} && {count _gearCals == 0} && {!("x_ItemGPS" in _gearRows)}
    && {(((call PMCS_fnc_catalog) get "items") get "rhs_6b23_ML") select 0 == "gear"} && {(["rhs_6b23_ML", PMCS_market] call PMCS_fnc_price) isEqualTo ["ok", 1120, 2800, 0, -1, 4]},
    "equipment grid: the base vests and the warbelt the game has (6B23 box of 4 at 700 = 2 800, one 1 120), cheapest first, counted by vest type, no calibre"] call TEST_fnc_assert;

// Ammunition: a card per magazine row of the table; the filter is the calibre.
PMCS_ui set ["tab", "ammo"];
PMCS_ui set ["sort", 0];
([] call PMCS_fnc_uiShopList) params ["_ammoRows", "", "_ammoCals"];
PMCS_ui set ["selCals", ["7.62x39 АК"]];
private _onlyAkm = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["selCals", []];
PMCS_ui set ["search", "bakelite_u"];
private _byClass = ([] call PMCS_fnc_uiShopList) select 0;
PMCS_ui set ["search", ""];
(PMCS_market get "items") set [_bakeKey, [true, -1, 0, -1, -1]];
private _hiddenRow = ([] call PMCS_fnc_uiShopList) select 0;
[_ammoRows isEqualTo [_bakeKey, "rhs_30Rnd_762x39mm_polymer_89", "MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L23_Plastic_7N6M", "rhs_100Rnd_762x54mmR"]
    && {(_ammoCals get "7.62x39 АК") == 2} && {(_ammoCals get "5.45x39 АК") == 2}
    && {(_ammoCals get "7.62x54R ПКМ") == 1} && {_onlyAkm isEqualTo [_bakeKey, "rhs_30Rnd_762x39mm_polymer_89"]}
    && {_byClass isEqualTo [_bakeKey]} && {_hiddenRow isEqualTo ["rhs_30Rnd_762x39mm_polymer_89", "MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L23_Plastic_7N6M", "rhs_100Rnd_762x54mmR"]}
    && {(["7.62x39 АК"] call PMCS_fnc_uiCalibreMags) isEqualTo ["rhs_30Rnd_762x39mm_polymer_89"]} && {(["7.62x54R СВД"] call PMCS_fnc_uiCalibreMags) isEqualTo []},
    "ammunition grid: a card per magazine row, cheapest box of its first type first, only the selected calibre stays, search by a type's class, a hidden row left out; a calibre's rows on sale"] call TEST_fnc_assert;

// --- The laptop on screen: desktop, shop, cart, purchase, management ------------------------------------
{
    missionNamespace setVariable ["PMCS_fnc_" + _x, (format ["pmc_shop/Client/fn_%1.sqf", _x]) call TEST_fnc_load];
} forEach ["ui", "uiMake", "uiClear", "uiColor", "uiShop", "uiCartLine", "uiCartAdd", "uiAdmin", "open", "receive", "notify", "uiTech"];
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
        if (_fn in ["PMCS_fnc_requestState", "PMCS_fnc_buy", "PMCS_fnc_admin", "PMCS_fnc_closed", "PMCS_fnc_receive", "PMCS_fnc_notify",
            "PMCS_fnc_upgrade", "PMCS_fnc_upgradeApply", "PMCS_fnc_upgradeDone", "PMCS_fnc_gearUpgrade", "PMCS_fnc_gearApply"]) then {
            _args call (missionNamespace getVariable _fn);
        };
    };
};
TEST_messages = [];
TEST_strings = createHashMapFromArray [["STR_PMCS_CARD_TITLE", "%1 x%2"], ["STR_PMCS_ADD_BOX", "box x%1"], ["STR_PMCS_ADD_UNIT", "single %1"]];
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
    && {count _cards == count (PMCS_ui get "shown")} && {count _cards >= 4} && {_sel == "uk3cb_saiga12k"}
    && {(["Сайга 12К"] call TEST_byText) isNotEqualTo []} && {(["detail"] call TEST_region) isNotEqualTo []},
    "laptop: the desktop with the ION Market icon, the browser asks the server, the grid has a card per item, the cheapest is chosen and shown in the card"] call TEST_fnc_assert;

[(["select", ["rhs_weap_ak74"]] call TEST_byEvent) select 0] call TEST_click;
private _cardTitle = (["АК-74 x12"] call TEST_byText) isNotEqualTo [] && {(["3 000 $"] call TEST_byText) isNotEqualTo []};
private _buttons = (["box x12"] call TEST_byText) isNotEqualTo [] && {(["single 400 $"] call TEST_byText) isNotEqualTo []}
    && {(["add", ["box"]] call TEST_byEvent) isNotEqualTo []} && {(["add", ["unit"]] call TEST_byEvent) isNotEqualTo []};
private _initial = +(PMCS_ui get "shown");
[(["add", ["box"]] call TEST_byEvent) select 0] call TEST_click;
private _mmmChip = ["variant", ["MMM_weap_AK74_H*S*"]] call TEST_byEvent;
[_mmmChip select 0] call TEST_click;
private _randomNote = (["STR_PMCS_RANDOM_LINE"] call TEST_byText) isNotEqualTo [];
[(["qty", [1]] call TEST_byEvent) select 0] call TEST_click;
[(["add", ["unit"]] call TEST_byEvent) select 0] call TEST_click;
private _cart = +(PMCS_ui get "cart");
[(["checkout"] call TEST_byEvent) select 0] call TEST_click;
private _request = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_buy"}) select 0;
private _drawsBefore = TEST_randomDraws;
call TEST_serve;
private _inBox = (_shopBox getVariable ["TEST_weapons", []]) apply {_x select 0};
[_cardTitle && {_buttons} && {count _mmmChip == 1} && {(_mmmChip select 0) getVariable ["TEST_text", ""] == "MMM"} && {_randomNote}
    && {_cart isEqualTo [["rhs_weap_ak74", "rhs_weap_ak74", 1, true], ["rhs_weap_ak74", "MMM_weap_AK74_H*S*", 2, false]]}
    && {((_request select 0) select 2) == "personal"} && {((PMCB_accounts get "76561100000000002") select 0) == 10000 - 3000 - 800}
    && {({_x == "rhs_weap_ak74"} count _inBox) == 12} && {({_x in ["MMM_weap_AK74_H1S1", "MMM_weap_AK74_H2S1"]} count _inBox) == 2}
    && {({_x == "MMM_weap_AK74_H1S1"} count _inBox) == 1} && {TEST_randomDraws - _drawsBefore == 1 + 2} && {(PMCS_ui get "cart") isEqualTo []},
    "shop: the card reads 'АК-74 x12' and the box price; the main button adds a box, the second one single pieces (400 each); one 'MMM' version, two single pieces of it drawn one by one; check out pays 3 800, the box gets 12 + 2, the cart empties"] call TEST_fnc_assert;

// Filters: a click on a row selects it (only selected rows stay), another click lets it go.
private _toggle = {params ["_kind", "_key", "_on"]; [((["filter", [_kind, _key, _on]] call TEST_byEvent)) select 0] call TEST_click};
["cal", "5.45x39 АК", true] call _toggle;
private _onlyAk = +(PMCS_ui get "shown");
private _selRow = (["filter", ["cal", "5.45x39 АК", false]] call TEST_byEvent) isNotEqualTo [];
["cal", "5.45x39 АК", false] call _toggle;
["type", "единый пулемет", true] call _toggle;
private _onlyMg = +(PMCS_ui get "shown");
["type", "единый пулемет", false] call _toggle;
private _allBack = (PMCS_ui get "shown") isEqualTo _initial;
// "Select all" ticks every row (everything stays); a click then lets one go; "Clear" shows all again.
[(["filterAll"] call TEST_byEvent) select 0] call TEST_click;
private _allTicked = (PMCS_ui get "shown") isEqualTo _initial && {(["filter", ["type", "штурмовая винтовка", false]] call TEST_byEvent) isNotEqualTo []}
    && {(["filter", ["cal", "7.62x54R ПКМ", false]] call TEST_byEvent) isNotEqualTo []};
["type", "штурмовая винтовка", false] call _toggle;
private _noAssault = +(PMCS_ui get "shown");
[(["filterNone"] call TEST_byEvent) select 0] call TEST_click;
private _cleared = (PMCS_ui get "shown") isEqualTo _initial && {(PMCS_ui get "selTypes") isEqualTo []} && {(PMCS_ui get "selCals") isEqualTo []};
// The equipment section button shows the vests; the weapons button brings the weapons back.
[(["tab", ["gear"]] call TEST_byEvent) select 0] call TEST_click;
private _gearShown = +(PMCS_ui get "shown");
[(["tab", ["weapons"]] call TEST_byEvent) select 0] call TEST_click;
private _sections = "rhs_6b23_ML" in _gearShown && {!("rhs_weap_ak74" in _gearShown)} && {(PMCS_ui get "shown") isEqualTo _initial};
{(PMCS_market get "items") set [_x select 0, [false, _x select 1, 0, -1, -1]]} forEach [[_bakeKey, 15], ["rhs_30Rnd_762x39mm_polymer_89", 20]];
call PMCS_fnc_broadcast;
call TEST_serve;
[(["select", ["rhs_weap_akm"]] call TEST_byEvent) select 0] call TEST_click;
// The weapon's card: the magazine rows of its calibre, then the ammo types of the chosen row.
private _polyKey = "rhs_30Rnd_762x39mm_polymer_89";
private _rowChips = [_bakeKey, _polyKey] apply {count (["mag", [_x]] call TEST_byEvent)};
private _firstRow = PMCS_ui get "mag";
private _bakeTypes = [_bakeKey, "rhs_30Rnd_762x39mm_bakelite_tracer", "rhs_30Rnd_762x39mm_bakelite_U", _polyKey] apply {count (["ammoType", [_x]] call TEST_byEvent)};
[(["ammoType", ["rhs_30Rnd_762x39mm_bakelite_U"]] call TEST_byEvent) select 0] call TEST_click;
private _specialPrice = (["detail"] call TEST_region) select {"1 800 $" in (_x getVariable ["TEST_text", ""])};
[(["magQty", [1]] call TEST_byEvent) select 0] call TEST_click;
[(["magAdd", ["unit"]] call TEST_byEvent) select 0] call TEST_click;
[(["mag", [_polyKey]] call TEST_byEvent) select 0] call TEST_click;
private _polyType = PMCS_ui get "ammoType";
[(["magAdd", ["box"]] call TEST_byEvent) select 0] call TEST_click;
private _magCart = +(PMCS_ui get "cart");
// A row hidden by a Zeus while the card is open: the card moves on to one still on sale.
[(["mag", [_bakeKey]] call TEST_byEvent) select 0] call TEST_click;
(PMCS_market get "items") set [_bakeKey, [true, 15, 0, -1, -1]];
call PMCS_fnc_broadcast;
call TEST_serve;
private _movedOn = PMCS_ui get "mag";
(PMCS_market get "items") set [_bakeKey, [false, 15, 0, -1, -1]];
call PMCS_fnc_broadcast;
call TEST_serve;
[_selRow && {_onlyAk isEqualTo ["rhs_weap_ak74", "rhs_weap_ak74n"]} && {_onlyMg isEqualTo ["rhs_weap_pkm"]} && {_allBack} && {_allTicked} && {_cleared} && {_sections}
    && {!("rhs_weap_ak74" in _noAssault)} && {"rhs_weap_pkm" in _noAssault}
    && {_rowChips isEqualTo [1, 1]} && {_firstRow == _bakeKey} && {_movedOn == _polyKey} && {_bakeTypes isEqualTo [1, 1, 1, 0]} && {_polyType == _polyKey}
    && {_specialPrice isNotEqualTo []}
    && {_magCart isEqualTo [[_bakeKey, "rhs_30Rnd_762x39mm_bakelite_U", 2, false], [_polyKey, _polyKey, 2, true]]},
    "shop: a filter row keeps only what is selected (AK by calibre, PKM by category), a second click lets it go; 'select all' ticks every row and a click then drops one, 'clear' shows all; the AKM's card offers its calibre's magazine rows, then the chosen row's ammo types (special x4: 1 800 a box), then a box or single magazines; a row hidden meanwhile is replaced"] call TEST_fnc_assert;

[PMCS_ui get "tabAmmo"] call TEST_click;
private _ammoCards = (["grid"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_ButtonClear"};
private _ammoShown = +(PMCS_ui get "shown");
private _ammoTitle = (["30 патр. Бакелит x30"] call TEST_byText) isNotEqualTo [] && {(["450 $"] call TEST_byText) isNotEqualTo []};
["cal", "7.62x39 АК", true] call _toggle;
private _onlyAkmRows = +(PMCS_ui get "shown");
["cal", "7.62x39 АК", false] call _toggle;
[(["select", [_bakeKey]] call TEST_byEvent) select 0] call TEST_click;
private _fits = (((["detail"] call TEST_region) select {(_x getVariable ["TEST_text", ""]) == "7.62x39 АК"}) isNotEqualTo []) && {(["STR_PMCS_FITS"] call TEST_byText) isNotEqualTo []};
[(["ammoType", ["rhs_30Rnd_762x39mm_bakelite_tracer"]] call TEST_byEvent) select 0] call TEST_click;
private _tracePrice = ((["detail"] call TEST_region) select {"495 $" in (_x getVariable ["TEST_text", ""])}) isNotEqualTo [];
[(["add", ["box"]] call TEST_byEvent) select 0] call TEST_click;
[(["cartOpen"] call TEST_byEvent) select 0] call TEST_click;
private _rows = count (((["overlay"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0 getVariable ["TEST_rows", []]);
[(["cartQty", [1]] call TEST_byEvent) select 0] call TEST_click;
private _three = ((PMCS_ui get "cart") select 0) select 2;
[(["cartRemove", []] call TEST_byEvent) select 0] call TEST_click;
private _afterRemove = (PMCS_ui get "cart") apply {_x select 1};
[(["checkout"] call TEST_byEvent) select 0] call TEST_click;
call TEST_serve;
private _boxMags = createHashMap;
{_boxMags set [_x select 0, (if ((_x select 0) in _boxMags) then {_boxMags get (_x select 0)} else {0}) + (_x select 1)]} forEach (_shopBox getVariable ["TEST_mags", []]);
[(["select", [_polyKey]] call TEST_byEvent) select 0] call TEST_click;
[(["add", ["box"]] call TEST_byEvent) select 0] call TEST_click;
private _beforeClear = +(PMCS_ui get "cart");
[(["cartClear", []] call TEST_byEvent) select 0] call TEST_click;
[count _ammoCards == 5 && {_ammoShown isEqualTo [_bakeKey, _polyKey, "MMM_mag_545x39_6L20_7N6M", "MMM_mag_545x39_6L23_Plastic_7N6M", "rhs_100Rnd_762x54mmR"]} && {_ammoTitle}
    && {_onlyAkmRows isEqualTo [_bakeKey, _polyKey]} && {_fits} && {_tracePrice} && {_rows == 3} && {_three == 3}
    && {_afterRemove isEqualTo [_polyKey, "rhs_30Rnd_762x39mm_bakelite_tracer"]}
    && {(_boxMags get _polyKey) == 60} && {(_boxMags get "rhs_30Rnd_762x39mm_bakelite_tracer") == 30}
    && {((PMCB_accounts get "76561100000000002") select 0) == 6200 - 2 * 600 - 495}
    && {_beforeClear isEqualTo [[_polyKey, _polyKey, 1, true]]} && {(PMCS_ui get "cart") isEqualTo []},
    "ammunition tab: a card per magazine row ('30 патр. Бакелит x30', the ball box price), the calibre filter, the row's card with what it fits and its ammo types (tracer x1.1: 495 a box); the cart window changes and removes lines; check out delivers boxes of 30"] call TEST_fnc_assert;

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
["set", ["acal", "7.62x39 АК"]] call PMCS_fnc_uiAdmin;
private _magRows762 = [] call TEST_tableRows;
["set", ["asection", "gear"]] call PMCS_fnc_uiAdmin;
private _gearAdminRows = [] call TEST_tableRows;
["set", ["asection", "weapon"]] call PMCS_fnc_uiAdmin;
_table = ((["table"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0;
private _calColumns = count _pkmRows == 2 && {"7.62x54R ПКМ" in ((_pkmRows select 1) select 0)} && {"Единые пулемёты" in ((_pkmRows select 1) select 0)}
    && {count _magRows == 6} && {count _magRows762 == 3} && {count _gearAdminRows == 4}
    && {(_gearAdminRows findIf {"rhs_6b23_ML" in (_x select 0) && {"Общевойсковые бронежилеты" in (_x select 0)} && {"4 × 2 800 $" in (_x select 0)}}) > 0}
    && {(_magRows762 findIf {"7.62x39 АК" in (_x select 0) && {((_x select 0) findIf {"STR_PMCS_AMMO_special" in _x}) >= 0} && {"30 патр. Бакелит" in (_x select 0)}}) > 0};
private _akRow = -1;
private _cellData = _table getVariable ["TEST_cells", createHashMap];
{if ((_cellData get _x) == "rhs_weap_ak74") then {_akRow = parseNumber (((_x select [1, count _x - 2]) splitString ",") select 0)}} forEach keys _cellData;
[_table, _akRow] call (_table getVariable "TEST_eh_LBSelChanged");
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
// A header and the five catalog weapons the stand-in game has.
[_tableRows == 7 && {_calColumns} && {((PMCS_market get "cats") get "штурмовая винтовка") == 7} && {count _catRows == 1 + count ((call PMCS_fnc_catalog) get "categories") + 2}
    && {_picked == "rhs_weap_ak74"} && {_set isEqualTo [false, 300, 10, 4, 4]} && {(PMCS_market get "global") == 12}
    && {(_foundVal select 0) == "AS Val"} && {((PMCS_market get "items") get "x_rhs_weap_asval") isEqualTo [false, 700, 0, 2, 2]} && {_armed == 0}
    && {count (_log getVariable ["TEST_rows", []]) == 1 + count (PMCS_market get "log")},
    "management: the table lists the goods with category and calibre columns, filtered by calibre (weapons and magazines with their ammo type); the chosen one gets price, discount and a limited quantity; a market discount and one for a weapon category of the table; a class found in the game and added; reset waits for a second click; the journal lists every change"] call TEST_fnc_assert;
["onUnload", []] call PMCS_fnc_ui;

// --- The gunsmith ("Техник"): the player's weapon, parts and money -----------------------------------
private _uid = "76561100000000002";
player setVariable ["TEST_wslots", [["rhs_weap_ak74", "rhs_acc_dtk", "", "rhs_acc_1p29", ["rhs_30Rnd_545x39_7N10_AK", 25], [], ""], [], []]];
player setVariable ["TEST_inv", ["ar_things_weapon_parts_low", "ar_things_weapon_parts_low", "ar_things_weapon_parts_med", "ar_things_weapon_parts_med", "ar_things_weapon_parts_med", "FirstAidKit"]];
TEST_noFit = ["rhs_acc_dtk"];
(PMCB_accounts get _uid) set [0, 1000];
player setPos [100, 1, 0];
TEST_messages = [];
[_shopLaptop] call PMCS_fnc_open;
["onLoad", ["Logic" createVehicle [0, 0, 0]]] call PMCS_fnc_ui;
[((["desk"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_ButtonClear"}) select 0] call TEST_click;
call TEST_serve;
private _nav = ([] call TEST_live) select {(_x getVariable ["PMCS_site", ""]) == "tech"};
[_nav select 0] call TEST_click;
call TEST_serve;
private _onTech = (PMCS_ui get "site") == "tech" && {(["grid"] call TEST_region) isEqualTo []};
private _offers = (["tech"] call TEST_region) select {((_x getVariable ["PMCS_event", []]) param [0, ""]) == "upgrade"};
private _offerKeys = _offers apply {((_x getVariable "PMCS_event") select 1) select 0};
private _bothOn = (_offers findIf {!(_x getVariable ["TEST_enabled", true])}) < 0;
// First click arms the button, the second sends the upgrade.
private _mrButton = {(["upgrade", ["rhs_weap_ak74__rhs_weap_ak74mr"]] call TEST_byEvent) select 0};
[[] call _mrButton] call TEST_click;
private _armedFirst = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_upgrade"}) isEqualTo [];
[[] call _mrButton] call TEST_click;
private _sent = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_upgrade"}) isNotEqualTo [];
call TEST_serve;
private _after = (player getVariable "TEST_wslots") select 0;
private _inv = player getVariable ["TEST_inv", []];
private _bankUp = PMCB_log select (count PMCB_log - 1);
[_onTech && {_offerKeys isEqualTo ["rhs_weap_ak74__rhs_weap_ak74_gp25", "rhs_weap_ak74__rhs_weap_ak74mr"]} && {_bothOn} && {_armedFirst} && {_sent}
    && {(_after select 0) == "rhs_weap_ak74mr"} && {"rhs_acc_1p29" in _after} && {(_after select 4) isEqualTo ["rhs_30Rnd_545x39_7N10_AK", 25]}
    && {"rhs_acc_dtk" in _inv} && {({_x == "ar_things_weapon_parts_low"} count _inv) == 1} && {({_x == "ar_things_weapon_parts_med"} count _inv) == 0}
    && {"FirstAidKit" in _inv} && {((PMCB_accounts get _uid) select 0) == 700} && {(_bankUp select 4) == "upgrade"} && {(_bankUp select 5) == 300}
    && {((PMCS_market get "log") select (count (PMCS_market get "log") - 1)) select 2 find "STR_PMCS_LOG_UPGRADE" == 0}
    && {!(PMCS_ui get "techBusy")} && {(["upgrade", ["rhs_weap_ak74mr__rhs_weap_ak74mr_gp25"]] call TEST_byEvent) isNotEqualTo []},
    "gunsmith: the page lists the AK-74's two upgrades, the second click upgrades it to the AK-74MR: 300 from the account (PMC Bank journal: upgrade), 1 low and 3 medium parts taken, the optic and the loaded magazine stay on, the muzzle device that does not fit goes to the inventory; the next upgrade is offered"] call TEST_fnc_assert;

// Refused and refunded.
TEST_messages = [];
player setVariable ["TEST_inv", []];
["body"] call PMCS_fnc_uiTech;
private _blocked = !((((["upgrade", ["rhs_weap_ak74mr__rhs_weap_ak74mr_gp25"]] call TEST_byEvent) select 0) getVariable ["TEST_enabled", true]))
    && {(["STR_PMCS_TECH_SHORT"] call TEST_byText) isNotEqualTo []};
[player, _shopLaptop, "personal", 0, "rhs_weap_ak74mr__rhs_weap_ak74mr_gp25"] call PMCS_fnc_upgrade;
private _noParts = (((["PMCS_fnc_notify"] call TEST_sent) select 0) select 0) select 0;
player setVariable ["TEST_inv", ["ar_things_weapon_parts_low"]];
[player, _shopLaptop, "personal", 0, "rhs_weap_ak74__rhs_weap_ak74_gp25"] call PMCS_fnc_upgrade;
private _wrongWeapon = (([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0) select 0;
(PMCB_accounts get _uid) set [0, 100];
[player, _shopLaptop, "personal", 0, "rhs_weap_ak74mr__rhs_weap_ak74mr_gp25"] call PMCS_fnc_upgrade;
private _poorTech = (([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0) select 0;
(PMCB_accounts get _uid) set [0, 1000];
player setPos [140, 1, 0];
[player, _shopLaptop, "personal", 0, "rhs_weap_ak74mr__rhs_weap_ak74mr_gp25"] call PMCS_fnc_upgrade;
private _farTech = (([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0) select 0;
player setPos [100, 1, 0];
private _untouched = ((PMCB_accounts get _uid) select 0) == 1000 && {(TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_upgradeApply"}) isEqualTo []};
// Paid, but the weapon is gone before the swap: the money comes back.
TEST_messages = [];
[player, _shopLaptop, "personal", 0, "rhs_weap_ak74mr__rhs_weap_ak74mr_gp25"] call PMCS_fnc_upgrade;
private _charged = ((PMCB_accounts get _uid) select 0) == 750;
private _apply = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_upgradeApply"}) select 0;
player setVariable ["TEST_wslots", [[], [], []]];
(_apply select 0) call PMCS_fnc_upgradeApply;
call TEST_serve;
private _refunded = ((PMCB_accounts get _uid) select 0) == 1000 && {(PMCB_log select (count PMCB_log - 1)) select 4 == "upgradeRefund"}
    && {"ar_things_weapon_parts_low" in (player getVariable ["TEST_inv", []])};
// An answer for an upgrade the server does not know, or a second answer, changes nothing.
[player, "made-up", false] call PMCS_fnc_upgradeDone;
[player, (_apply select 0) select 0, false] call PMCS_fnc_upgradeDone;
[_blocked && {_noParts == "STR_PMCS_ERR_PARTS"} && {_wrongWeapon == "STR_PMCS_ERR_UPGRADE"} && {_poorTech == "STR_PMCS_ERR_FUNDS"} && {_farTech == "STR_PMCS_ERR_FAR"} && {_untouched}
    && {_charged} && {_refunded} && {((PMCB_accounts get _uid) select 0) == 1000},
    "gunsmith refuses: without parts the button is off; no parts, a weapon the upgrade does not take, not enough money, too far from the laptop - nothing charged; paid but the weapon was gone before the swap: refunded (journal: upgradeRefund), parts kept; a made-up answer changes nothing"] call TEST_fnc_assert;

// Undo on a weapon: the AK-74MR goes back to the AK-74 for free; the parts stay used up.
player setVariable ["TEST_wslots", [["rhs_weap_ak74mr", "", "", "rhs_acc_1p29", [], [], ""], [], []]];
player setVariable ["TEST_inv", ["ar_things_weapon_parts_med"]];
PMCS_ui set ["techSlot", 0];
["body"] call PMCS_fnc_uiTech;
private _undoKey = "rev:rhs_weap_ak74__rhs_weap_ak74mr";
private _undoOn = ((["upgrade", [_undoKey]] call TEST_byEvent) select 0) getVariable ["TEST_enabled", true];
private _undoLabel = (["STR_PMCS_TECH_UNDO"] call TEST_byText) isNotEqualTo [];
[(["upgrade", [_undoKey]] call TEST_byEvent) select 0] call TEST_click;
[(["upgrade", [_undoKey]] call TEST_byEvent) select 0] call TEST_click;
call TEST_serve;
private _back = (player getVariable "TEST_wslots") select 0;
[_undoOn && {_undoLabel} && {(_back select 0) == "rhs_weap_ak74"} && {"rhs_acc_1p29" in _back} && {((PMCB_accounts get _uid) select 0) == 1000}
    && {(player getVariable ["TEST_inv", []]) isEqualTo ["ar_things_weapon_parts_med"]},
    "gunsmith weapon undo: the AK-74MR offers 'undo' (free, always on); two clicks give the AK-74 back with its optic, no money taken, no parts given back or taken"] call TEST_fnc_assert;

// The upgrade tree window: families on the left, the chosen family drawn as cards and lines.
[(["tree", [true]] call TEST_byEvent) select 0] call TEST_click;
private _treeList = {((["treeWin"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_List"}) select 0};
private _treeTexts = {((["treeWin"] call TEST_region) apply {_x getVariable ["TEST_text", ""]}) select {_x != ""}};
private _familyRows = ([] call _treeList) getVariable ["TEST_rows", []];
private _akFamily = PMCS_ui get "treeFamily";
private _akCards = [] call _treeTexts;
private _cardX = {params ["_name"]; ((((["treeWin"] call TEST_region) select {(_x getVariable ["TEST_text", ""]) == _name && {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_TextBold"}}) select 0) getVariable ["TEST_pos", [0]]) select 0};
private _columnsOk = (["АК-74"] call _cardX) < (["АК-74 + ГП-25"] call _cardX) && {(["АК-74 + ГП-25"] call _cardX) < (["АК-74МР + ГП-25"] call _cardX)}
    && {(["АК-74"] call _cardX) == (["АКС-74"] call _cardX)};
private _akListRow = ([] call _treeList) getVariable ["TEST_cur", -1];
private _akListOk = ([[] call _treeList, [_akListRow, 0]] call TEST_fnc_lnbData) == "АК-74";
private _lines = count ((["treeWin"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_Text" && {((_x getVariable ["TEST_pos", [0, 0, 0, 0]]) select 3) < 0.004}});
// Another family from the list.
private _list = [] call _treeList;
private _cellData = _list getVariable ["TEST_cells", createHashMap];
private _m249Row = -1;
{if ((_cellData get _x) == "M249") then {_m249Row = parseNumber (((_x select [1, count _x - 2]) splitString ",") select 0)}} forEach keys _cellData;
[_list, _m249Row] call (_list getVariable "TEST_eh_LBSelChanged");
private _m249Cards = [] call _treeTexts;
[(["treeSide", [true]] call TEST_byEvent) select 0] call TEST_click;
private _vestFamily = PMCS_ui get "treeFamily";
private _vestCards = [] call _treeTexts;
// One cost line per upgrade into a card of the family; undo entries are not drawn.
private _gearNames = (call PMCS_fnc_gearUpgrades) apply {_x select 1};
private _vestNames = (((["treeWin"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_TextBold"}) apply {_x getVariable ["TEST_text", ""]}) select {_x in _gearNames};
private _vestLines = {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_Struct"} count (["treeWin"] call TEST_region);
private _vestWant = {(_x select 5) != "rev" && {(_x select 1) in _vestNames}} count (call PMCS_fnc_gearUpgrades);
[(["tree", [false]] call TEST_byEvent) select 0] call TEST_click;
[_akFamily == "АК-74" && {"АК-74МР + ГП-25" in _akCards} && {"АК-74 + ГП-25" in _akCards} && {"АКС-74" in _akCards} && {_lines >= 3 * 4} && {_columnsOk} && {_akListOk}
    && {(_familyRows findIf {((_x select 0) select 0) == "  АК-74"}) >= 0} && {(((_familyRows select 0) select 0) select 0) == "Штурмовые винтовки"}
    && {_m249Row > 0} && {"M249 PIP LCBA" in _m249Cards} && {!("АК-74МР" in _m249Cards)}
    && {_vestFamily != ""} && {_vestWant > 0} && {_vestLines == _vestWant} && {_vestCards findIf {"IOTV" in _x || {"6Б" in _x} || {"CPC" in _x} || {"JPC" in _x} || {"MBAV" in _x} || {"Лифчик" in _x} || {"SPCS" in _x} || {"6Ш92" in _x}} >= 0}
    && {(["treeWin"] call TEST_region) isEqualTo []},
    "upgrade tree: the families by category on the left (the chosen AK-74's first), the family drawn as cards (AK-74, AKS-74, the GP-25 and AK-74MR versions) in columns by step, joined by lines, the family picked in the list; another family from the list (M249); the vests, one cost line per upgrade and no undo lines; it closes"] call TEST_fnc_assert;

// --- The gunsmith: the vest worn --------------------------------------------------------------------
private _gearKeys = (["rhs_6b23_ML"] call PMCS_fnc_gearUpgradesFor) apply {(_x select 0) select 0};
private _medic = ((call PMCS_fnc_gearUpgrades) select {(_x select 0) == "rhs_6b23_ML__rhs_6b23_ML_medic"}) select 0;
private _rifle = ((call PMCS_fnc_gearUpgrades) select {(_x select 0) == "rhs_6b23_ML__rhs_6b23_ML_6sh92"}) select 0;
private _beltUp = ((call PMCS_fnc_gearUpgrades) select {(_x select 0) == "USP_CRYE_CPC_WEAPON_RGR__USP_CRYE_CPC_WEAPON_BELT_RGR"}) select 0;
private _gearData = (_gearKeys isEqualTo ["rhs_6b23_ML__rhs_6b23_ML_6sh92", "rhs_6b23_ML__rhs_6b23_ML_medic"] || {_gearKeys isEqualTo ["rhs_6b23_ML__rhs_6b23_ML_medic", "rhs_6b23_ML__rhs_6b23_ML_6sh92"]})
    && {(_medic select 6) == 50} && {([_medic] call PMCS_fnc_gearTake) isEqualTo []} && {([_rifle] call PMCS_fnc_gearTake) isEqualTo [["rhs_6sh92_vsr", 1]]}
    && {([_beltUp] call PMCS_fnc_gearTake) isEqualTo [["USP_CRYE_BELT_PACK_MC", 1]]} && {count ((call PMCS_fnc_gearUpgrades) select {(_x select 5) != "rev"}) == 70}
    && {count ((call PMCS_fnc_gearUpgrades) select {(_x select 5) == "rev"}) == 70}
    && {([((call PMCS_fnc_gearUpgrades) select {(_x select 0) == "rhs_lifchik__rhs_lifchik_vog"}) select 0] call PMCS_fnc_gearTake) isEqualTo [["ar_clothes_olduniform", 4]]}
    && {([((call PMCS_fnc_gearUpgrades) select {(_x select 0) == "rhs_6sh92_vsr__rhs_6sh92_vsr_vog"}) select 0] call PMCS_fnc_gearTake) isEqualTo [["ar_clothes_olduniform", 4]]}
    && {((call PMCS_fnc_gearUpgrades) findIf {"mmm_" in toLower (_x select 9)}) < 0}
    && {(["USP_CRYE_BELT_PACK_MC"] call PMCS_fnc_itemTitle) == "STR_PMCS_ITEM_BELT"} && {(["rhs_6sh92_vsr"] call PMCS_fnc_itemTitle) == "6Sh92 (VSR)"};
player setVariable ["TEST_vest", ["rhs_6b23_ML", [["FirstAidKit", 2], ["rhs_30Rnd_545x39_7N10_AK", 3, 30]]]];
player setVariable ["TEST_inv", []];
(PMCB_accounts get _uid) set [0, 1000];
TEST_messages = [];
[_shopLaptop] call PMCS_fnc_open;
["onLoad", ["Logic" createVehicle [0, 0, 0]]] call PMCS_fnc_ui;
[((["desk"] call TEST_region) select {(_x getVariable ["TEST_ctrlClass", ""]) == "PMCS_ButtonClear"}) select 0] call TEST_click;
call TEST_serve;
[(([] call TEST_live) select {(_x getVariable ["PMCS_site", ""]) == "tech"}) select 0] call TEST_click;
call TEST_serve;
[(["slot", [3]] call TEST_byEvent) select 0] call TEST_click;
private _vestOffers = ((["tech"] call TEST_region) select {((_x getVariable ["PMCS_event", []]) param [0, ""]) == "upgrade"}) apply {((_x getVariable "PMCS_event") select 1) select 0};
private _upButton = {params ["_k"]; (["upgrade", [_k]] call TEST_byEvent) select 0};
private _rifleOff = !((["rhs_6b23_ML__rhs_6b23_ML_6sh92"] call _upButton) getVariable ["TEST_enabled", true]);
private _medicOn = (["rhs_6b23_ML__rhs_6b23_ML_medic"] call _upButton) getVariable ["TEST_enabled", true];
// With a 6Sh92 in the inventory the rifleman version is offered; two clicks put it on.
player setVariable ["TEST_inv", ["rhs_6sh92_vsr", "USP_CRYE_BELT_PACK_MC"]];
["body"] call PMCS_fnc_uiTech;
[["rhs_6b23_ML__rhs_6b23_ML_6sh92"] call _upButton] call TEST_click;
[["rhs_6b23_ML__rhs_6b23_ML_6sh92"] call _upButton] call TEST_click;
call TEST_serve;
private _worn = player getVariable ["TEST_vest", []];
private _logGear = (PMCS_market get "log") select (count (PMCS_market get "log") - 1);
[_gearData && {_vestOffers isEqualTo _gearKeys} && {_rifleOff} && {_medicOn} && {(_worn select 0) == "rhs_6b23_ML_6sh92"}
    && {(_worn select 1) isEqualTo [["FirstAidKit", 2], ["rhs_30Rnd_545x39_7N10_AK", 3, 30]]} && {(player getVariable ["TEST_inv", []]) isEqualTo ["USP_CRYE_BELT_PACK_MC"]}
    && {((PMCB_accounts get _uid) select 0) == 1000} && {(_logGear select 2) == "STR_PMCS_LOG_GEAR"} && {!(PMCS_ui get "techBusy")},
    "gunsmith vest: 70 vest upgrades from the table (6B23 medic 50 $ without a medic bag, rifleman takes a 6Sh92, belts take a warbelt, 4 old uniforms instead of the MMM 6Sh48), each with an undo; the vest card lists the worn vest's upgrades, the rifleman one is off without a 6Sh92; with it two clicks put on the new vest with the old one's contents, the 6Sh92 is taken, no money (journal entry)"] call TEST_fnc_assert;

// Undo: the vest goes back and the 6Sh92 comes back to the inventory, for free.
private _undoOffer = (["upgrade", ["rev:rhs_6b23_ML__rhs_6b23_ML_6sh92"]] call TEST_byEvent) isNotEqualTo [];
[["rev:rhs_6b23_ML__rhs_6b23_ML_6sh92"] call _upButton] call TEST_click;
[["rev:rhs_6b23_ML__rhs_6b23_ML_6sh92"] call _upButton] call TEST_click;
call TEST_serve;
[_undoOffer && {((player getVariable ["TEST_vest", []]) select 0) == "rhs_6b23_ML"}
    && {((player getVariable ["TEST_vest", []]) select 1) isEqualTo [["FirstAidKit", 2], ["rhs_30Rnd_545x39_7N10_AK", 3, 30]]}
    && {"rhs_6sh92_vsr" in (player getVariable ["TEST_inv", []])} && {((PMCB_accounts get _uid) select 0) == 1000}
    && {((PMCS_market get "log") select (count (PMCS_market get "log") - 1)) select 2 == "STR_PMCS_LOG_GEAR"},
    "gunsmith vest undo: the rifleman 6B23 offers the way back; two clicks put the plain 6B23 back with the contents and give the 6Sh92 back, for free (journal entry)"] call TEST_fnc_assert;

// Paid vest upgrade, refusals and the refund when the vest is gone before the swap.
player setVariable ["TEST_vest", ["rhs_6b23_ML", []]];
TEST_messages = [];
[player, _shopLaptop, "personal", "rhs_6b23_ML__rhs_6b23_ML_medic"] call PMCS_fnc_gearUpgrade;
call TEST_serve;
private _medicDone = ((player getVariable ["TEST_vest", []]) param [0, ""]) == "rhs_6b23_ML_medic" && {((PMCB_accounts get _uid) select 0) == 950};
player setVariable ["TEST_vest", ["USP_CRYE_CPC_WEAPON_RGR", []]];
player setVariable ["TEST_inv", []];
[player, _shopLaptop, "personal", "USP_CRYE_CPC_WEAPON_RGR__USP_CRYE_CPC_WEAPON_BELT_RGR"] call PMCS_fnc_gearUpgrade;
private _noBelt = (([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0) select 0;
[player, _shopLaptop, "personal", "rhs_6b23_ML__rhs_6b23_ML_medic"] call PMCS_fnc_gearUpgrade;
private _wrongVest = (([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0) select 0;
player setVariable ["TEST_inv", ["USP_CRYE_BELT_PACK_MC"]];
TEST_messages = [];
[player, _shopLaptop, "personal", "USP_CRYE_CPC_WEAPON_RGR__USP_CRYE_CPC_WEAPON_BELT_RGR"] call PMCS_fnc_gearUpgrade;
private _gearApply = (TEST_messages select {((_x select 1) select 0) == "PMCS_fnc_gearApply"}) select 0;
player setVariable ["TEST_vest", []];
(_gearApply select 0) call PMCS_fnc_gearApply;
call TEST_serve;
private _keptBelt = (player getVariable ["TEST_inv", []]) isEqualTo ["USP_CRYE_BELT_PACK_MC"];
player setVariable ["TEST_vest", ["USP_CRYE_CPC_WEAPON_RGR", []]];
TEST_messages = [];
[player, _shopLaptop, "personal", "USP_CRYE_CPC_WEAPON_RGR__USP_CRYE_CPC_WEAPON_BELT_RGR"] call PMCS_fnc_gearUpgrade;
call TEST_serve;
private _belted = ((player getVariable ["TEST_vest", []]) param [0, ""]) == "USP_CRYE_CPC_WEAPON_BELT_RGR" && {(player getVariable ["TEST_inv", []]) isEqualTo []};
(PMCB_accounts get _uid) set [0, 10];
player setVariable ["TEST_vest", ["rhs_6b23_ML", []]];
[player, _shopLaptop, "personal", "rhs_6b23_ML__rhs_6b23_ML_medic"] call PMCS_fnc_gearUpgrade;
private _poorVest = (([["PMCS_fnc_notify"] call TEST_sent] call TEST_lastOf) select 0) select 0;
[_medicDone && {_noBelt == "STR_PMCS_ERR_ITEMS"} && {_wrongVest == "STR_PMCS_ERR_UPGRADE"} && {_keptBelt} && {_belted} && {_poorVest == "STR_PMCS_ERR_FUNDS"}
    && {((PMCB_accounts get _uid) select 0) == 10} && {((player getVariable ["TEST_vest", []]) select 0) == "rhs_6b23_ML"},
    "gunsmith vest: the medic version costs 50 $; no warbelt, a vest the upgrade is not for, not enough money - refused; the vest gone before the swap - nothing taken; with a warbelt the CPC gets its belt and the warbelt is taken"] call TEST_fnc_assert;
["onUnload", []] call PMCS_fnc_ui;

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];
