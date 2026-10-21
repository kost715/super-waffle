call compile preprocessFileLineNumbers "tests/vm_compat.sqf";
TEST_count = 0;
TEST_fnc_assert = {
    params ["_ok", "_label"];
    if (!_ok) then {diag_log ("TEST_FAIL: " + _label); exitcode__ 1};
    TEST_count = TEST_count + 1;
    diag_log ("TEST_PASS: " + _label);
};

{
    missionNamespace setVariable ["ALSPMC_fnc_" + _x,
        ("addons/alspmc_core/functions/fn_" + _x + ".sqf") call TEST_fnc_load];
} forEach ["requestAllowed", "buyBase", "save", "applyValues", "reconcile", "sellHouse", "serverInit",
    "normalizeName", "setName", "phoneDo", "phoneSync", "terminalInit", "terminalEnsure",
    "terminalSync", "terminalRemove", "terminalCanUse", "desktopDo", "clientInit", "phoneBridge", "phoneMsg",
    "questInit", "questSave", "questDo", "questState", "questSite", "questScenario", "questKilled",
    "contractInit", "contractSave", "contractCatalog", "contractProfile", "contractSites", "contractPlan", "contractBase", "contractFar",
    "contractTeam", "contractAttack", "contractEquip", "contractReady", "contractScenario", "contractTick", "contractMirror", "contractEnd",
    "contractAssets", "contractHostility", "contractOffers", "contractGarrison", "contractWarBases"];
{
    missionNamespace setVariable ["ALS_fnc_" + _x,
        ("native/functions/fn_" + _x + ".sqf") call TEST_fnc_load];
} forEach ["uid", "mine", "dbGet", "dbSet", "dbLoading", "moneyGet", "moneyAdd", "moneyPay", "houseClaim",
    "housePublish", "housePrice", "houseSell", "houseLock", "canUse", "bizGet", "bizCap", "bizPublish", "licInit", "licBuy", "licGrant", "licHas",
    "crewOf", "coopAccept", "coopTick", "coopEnd", "companyOf", "companySave"];

// Only world/renderer side effects are fixtures. Transactions and catalog paths
// above execute the actual separately supplied LifeSim functions.
ALS_fnc_findPlayer = {if ((_this select 0) == "p1") then {player} else {objNull}};
ALS_fnc_moneyMirror = {};
ALS_fnc_opt = {1};
ALS_fnc_mapName = {"Altis"};
ALS_fnc_civEvict = {};
ALS_fnc_tutEv = {};
ALS_fnc_haulProfile = {[0, 0]};
ALS_fnc_haulRank = {[0, "Courier"]};
ALS_fnc_fmtNum = {str _this};
ALS_fnc_serveAt = {TEST_clerk};
ALS_fnc_log = {};
ALS_fnc_houseDoors = {};
ALS_fnc_dbSave = {TEST_profilesSaved = TEST_profilesSaved + 1};
CBA_fnc_addPerFrameHandler = {};
ALS_fnc_crewPublish = {};
TEST_nativeWarBases = {TEST_seenNativeBases = +(ALS_war get "bases"); TEST_warBasesCalls = TEST_warBasesCalls + 1; true};
ALS_fnc_companyPublish = {};
ALS_fnc_coopOffers = {};
ALS_fnc_drvStop = {};
ALS_fnc_aiDrive = {TEST_driveCalls pushBack _this};
ALS_fnc_landPos = {_this select 0};
ALS_fnc_houseFloor = {[[100,100,1]]};
BIS_fnc_taskAttack = {TEST_attackCalls pushBack _this};
BIS_fnc_taskPatrol = {};
// Real map geometry is unavailable in the VM. Only placement discovery is
// replaced; server spawning, persistence, removal and authorization run as-is.
ALSPMC_fnc_terminalFindSpot = {[[100,100,0],0]};
TEST_clerk = 0;
player setVariable ["ALS_uid", "p1"];
player setVariable ["TEST_player", true];
player setVariable ["TEST_owner", 4];
player setPos [100, 100, 0];
TEST_nativeSell = ALS_fnc_houseSell;
TEST_nativeClaim = ALS_fnc_houseClaim;
TEST_nativeCoopEnd = ALS_fnc_coopEnd;
TEST_fnc_reset = {
    TEST_isServer = true;
    TEST_isRemoteExecuted = false;
    TEST_remoteOwner = 4;
    TEST_clerk = 0;
    TEST_messages = [];
    TEST_published = [];
    ALS_db = createHashMap;
    ALS_dbGuard = createHashMap;
    ALS_owned = createHashMap;
    ALS_ownedPublic = [];
    ALS_houses = createHashMapFromArray [
        ["h_100_100", [[100,100,0],"warehouse.p3d",300,2,"Kavala",50000,"Industrial","Good"]],
        ["h_110_100", [[110,100,0],"warehouse2.p3d",250,2,"Kavala",40000,"Industrial","Good"]],
        ["h_115_100", [[115,100,0],"home.p3d",150,4,"Kavala",30000,"Home","Good"]]
    ];
    ALS_biz = createHashMap;
    ALS_recipes = createHashMap;
    ALS_reserved = [];
    ALS_locked = [];
    ALS_leased = [];
    ALS_furniture = createHashMap;
    ALS_furnPrices = [];
    ALS_stashes = createHashMap;
    ALS_houseUp = createHashMap;
    ALS_townState = createHashMap;
    ALS_companies = createHashMap;
    ALS_crews = createHashMap;
    ALS_crewInvites = createHashMap;
    ALS_crewSeq = 0;
    ALS_coopJobs = createHashMap;
    ALS_coopSeq = 0;
    ALSPMC_questsStarted = false;
    ALSPMC_questsReady = false;
    ALSPMC_questSequence = 0;
    ALSPMC_questRecords = createHashMap;
    ALSPMC_questRequests = createHashMap;
    ALSPMC_contractsStarted = false;
    ALSPMC_contractsReady = false;
    ALSPMC_contractMeta = createHashMap;
    ALSPMC_ratingXP = createHashMap;
    ALSPMC_contractSitesCache = createHashMap;
    ALSPMC_contractAssets = createHashMap;
    ALSPMC_contractBoards = createHashMap;
    ALSPMC_boardSequence = 0;
    ALSPMC_garrisonLeases = createHashMap;
    ALSPMC_hostileContracts = createHashMap;
    ALSPMC_hostileRelations = createHashMap;
    ALSPMC_eastCivilianFriend = nil;
    ALSPMC_nativeWarBases = nil;
    ALS_fnc_warBases = TEST_nativeWarBases;
    TEST_seenNativeBases = []; TEST_warBasesCalls = 0;
    TEST_friendships = createHashMap;
    TEST_groupMembers = [];
    ALSPMC_nativeCoopEnd = nil;
    ALS_fnc_coopEnd = TEST_nativeCoopEnd;
    ALS_war = createHashMapFromArray [["on",false],["bases",[]],["own",createHashMap]];
    ALS_warGar = createHashMap;
    ALS_factions = createHashMapFromArray [["Gangs",createHashMapFromArray [["men",["NativeGang_Rifleman","NativeGang_Scout"]]]]];
    TEST_realTime = 1000;
    TEST_driveCalls = []; TEST_attackCalls = [];
    TEST_nearForces = [];
    TEST_randomQueue = [];
    TEST_players = [player];
    player setVariable ["TEST_group", nil];
    player setVariable ["ALS_coopJob", nil];
    player setVariable ["ALS_sideNav", []];
    ALSPMC_bases = createHashMap;
    ALSPMC_appliedBases = createHashMap;
    ALSPMC_basesPublic = [];
    ALSPMC_ready = true;
    ALSPMC_names = createHashMap;
    ALSPMC_namesReady = true;
    ALSPMC_workstationsReady = false;
    ALSPMC_workstations = createHashMap;
    ALSPMC_terminals = createHashMap;
    ALSPMC_terminalRetry = createHashMap;
    ALSPMC_terminalsPublic = [];
    ALSPMC_industrialKeys = ["h_100_100","h_110_100"];
    ALS_npcPublic = [[[100,100,0],"clerk","Test clerk","Town hall",[]]];
    ALSPMC_serverStarted = false;
    ALSPMC_nativeHouseSell = TEST_nativeSell;
    ALS_fnc_houseClaim = TEST_nativeClaim;
    ALS_fnc_houseSell = TEST_nativeSell;
    call ALS_fnc_licInit;
    ["money_p1", [10,10]] call ALS_fnc_dbSet;
};

call TEST_fnc_reset;
[((ALS_licenses get "alspmc_pmc") select 1) == 1, "native licence catalog price is 1"] call TEST_fnc_assert;
[[player, "alspmc_pmc"] call ALS_fnc_licBuy, "buy licence through native licBuy"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,9], "licence costs exactly 1 from bank"] call TEST_fnc_assert;
["alspmc_pmc" in (["lic_p1",[]] call ALS_fnc_dbGet), "native licence DB updated"] call TEST_fnc_assert;
["alspmc_pmc" in (player getVariable ["ALS_lic",[]]), "native licence mirror updated"] call TEST_fnc_assert;
[!([player,"alspmc_pmc"] call ALS_fnc_licBuy), "repeat licence rejected"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,9], "repeat licence does not charge"] call TEST_fnc_assert;
[[player,"h_100_100"] call ALSPMC_fnc_buyBase, "licenced player buys base"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,8], "base costs exactly 1 more"] call TEST_fnc_assert;
[(ALS_owned get "h_100_100") == "p1", "native ownership assigned"] call TEST_fnc_assert;
[((ALS_biz get "h_100_100") get "use") == "Warehouse", "native warehouse initialized"] call TEST_fnc_assert;
[((ALS_houses get "h_100_100") select 5) == 1, "base native valuation equals paid price"] call TEST_fnc_assert;
[((ALS_houses get "h_110_100") select 5) == 40000, "other property valuation unchanged"] call TEST_fnc_assert;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "duplicate purchase rejected"] call TEST_fnc_assert;
[!([player,"h_110_100"] call ALSPMC_fnc_buyBase), "second base rejected"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,8], "both duplicate attempts cost nothing"] call TEST_fnc_assert;
[(count (["alspmc_bases_v1",[]] call ALS_fnc_dbGet)) == 1, "base metadata serialized"] call TEST_fnc_assert;

// Simulate a fresh server map catalog and load the same saved DB.
ALSPMC_bases = createHashMap;
ALSPMC_basesPublic = [];
ALSPMC_appliedBases = createHashMap;
(ALS_houses get "h_100_100") set [5,50000];
call ALSPMC_fnc_serverInit;
[(count ALSPMC_bases) == 1, "base designation restored from DB"] call TEST_fnc_assert;
[((ALS_houses get "h_100_100") select 5) == 1, "paid valuation restored after restart"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,8], "restart does not charge again"] call TEST_fnc_assert;
[[player,"h_100_100"] call ALS_fnc_houseSell, "base sold through original sale function"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,8], "test base sale does not yield market price"] call TEST_fnc_assert;
[(count ALSPMC_bases) == 0 && {!("h_100_100" in ALS_owned)}, "sale removes both base and ownership"] call TEST_fnc_assert;
[((ALS_houses get "h_100_100") select 5) == 50000, "market valuation restored on sale"] call TEST_fnc_assert;
[["h_100_100"] call ALS_fnc_housePrice == 50000, "ordinary purchase price restored"] call TEST_fnc_assert;

call TEST_fnc_reset;
TEST_clerk = -1;
[!([player,"alspmc_pmc"] call ALS_fnc_licBuy), "native licence requires clerk"] call TEST_fnc_assert;
TEST_clerk = 0;
["money_p1",[0,0]] call ALS_fnc_dbSet;
[!([player,"alspmc_pmc"] call ALS_fnc_licBuy), "native licence rejects insufficient funds"] call TEST_fnc_assert;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "base requires licence"] call TEST_fnc_assert;
["fakelic_p1",createHashMapFromArray [["alspmc_pmc",true]]] call ALS_fnc_dbSet;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "forged licence is not establishment permit"] call TEST_fnc_assert;
["p1","alspmc_pmc"] call ALS_fnc_licGrant;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "base rejects insufficient funds"] call TEST_fnc_assert;
["money_p1",[1,0]] call ALS_fnc_dbSet;
[[player,"h_100_100"] call ALSPMC_fnc_buyBase, "cash-only purchase succeeds"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [0,0], "cash-only balance never negative"] call TEST_fnc_assert;

call TEST_fnc_reset;
["p1","alspmc_pmc"] call ALS_fnc_licGrant;
[!([player,"missing"] call ALSPMC_fnc_buyBase), "unknown property rejected"] call TEST_fnc_assert;
[!([player,"h_115_100"] call ALSPMC_fnc_buyBase), "ordinary home rejected"] call TEST_fnc_assert;
ALS_reserved = ["h_100_100"];
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "reserved property rejected"] call TEST_fnc_assert;
ALS_reserved = [];
ALS_owned set ["h_100_100","p2"];
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "other owner's property rejected"] call TEST_fnc_assert;
ALS_owned deleteAt "h_100_100";
(ALS_houses get "h_100_100") set [7,"Wrecked"];
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "ruined building rejected"] call TEST_fnc_assert;
(ALS_houses get "h_100_100") set [7,"Good"];
player setPos [1000,1000,0];
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "remote building rejected"] call TEST_fnc_assert;
player setPos [100,100,0];
TEST_isRemoteExecuted = true;
TEST_remoteOwner = 7;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "request for another player's unit rejected"] call TEST_fnc_assert;
TEST_remoteOwner = 4;
TEST_isServer = false;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "client execution rejected"] call TEST_fnc_assert;
TEST_isServer = true;
TEST_isRemoteExecuted = false;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,10], "invalid requests never charge"] call TEST_fnc_assert;

// Claim failure after payment must restore the precise payment source.
ALS_fnc_houseClaim = {false};
["money_p1",[1,0]] call ALS_fnc_dbSet;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "failed claim returns failure"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [1,0], "failed claim restores cash exactly"] call TEST_fnc_assert;
["money_p1",[0,1]] call ALS_fnc_dbSet;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "bank-funded failed claim returns failure"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [0,1], "failed claim restores bank exactly"] call TEST_fnc_assert;

call TEST_fnc_reset;
["p1","alspmc_pmc"] call ALS_fnc_licGrant;
[[player,"h_100_100"] call ALSPMC_fnc_buyBase, "base purchase before competing request"] call TEST_fnc_assert;
player setVariable ["ALS_uid","p2"];
["money_p2",[3,0]] call ALS_fnc_dbSet;
["p2","alspmc_pmc"] call ALS_fnc_licGrant;
[!([player,"h_100_100"] call ALSPMC_fnc_buyBase), "competing player cannot claim purchased base"] call TEST_fnc_assert;
[["p2"] call ALS_fnc_moneyGet isEqualTo [3,0], "competing player keeps all funds"] call TEST_fnc_assert;
player setVariable ["ALS_uid","p1"];
ALS_owned deleteAt "h_100_100";
call ALSPMC_fnc_reconcile;
[(count ALSPMC_bases) == 0, "externally removed ownership clears base designation"] call TEST_fnc_assert;
[((ALS_houses get "h_100_100") select 5) == 50000, "external ownership removal restores price"] call TEST_fnc_assert;

call TEST_fnc_reset;
ALS_owned set ["h_110_100","p1"];
ALSPMC_nativeHouseSell = TEST_nativeSell;
[[player,"h_110_100"] call ALSPMC_fnc_sellHouse, "ordinary property sale passes through"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,28010], "ordinary property sale keeps native payment"] call TEST_fnc_assert;

call TEST_fnc_reset;
["p1","alspmc_pmc"] call ALS_fnc_licGrant;
[[player,"h_100_100"] call ALSPMC_fnc_buyBase, "base purchase before company transfer"] call TEST_fnc_assert;
ALS_companies set ["co_1",createHashMapFromArray [["members",["p1","p2"]]]];
ALS_owned set ["h_100_100","co_1"];
call ALSPMC_fnc_reconcile;
[(count ALSPMC_bases) == 1, "transfer to founder's native company preserves base"] call TEST_fnc_assert;
ALS_owned set ["h_100_100","p2"];
call ALSPMC_fnc_reconcile;
[(count ALSPMC_bases) == 0, "different personal owner does not inherit stale designation"] call TEST_fnc_assert;
[((ALS_houses get "h_100_100") select 5) == 50000, "different owner keeps ordinary valuation"] call TEST_fnc_assert;

call TEST_fnc_reset;
private _bad = [["broken",["p1",50000]]];
["alspmc_bases_v1",_bad] call ALS_fnc_dbSet;
call ALSPMC_fnc_serverInit;
[!ALSPMC_ready, "corrupt metadata disables purchases"] call TEST_fnc_assert;
[["alspmc_bases_v1",[]] call ALS_fnc_dbGet isEqualTo _bad, "corrupt metadata is preserved"] call TEST_fnc_assert;
["alspmc_bases_v1",[]] call ALS_fnc_dbSet;
[["alspmc_bases_v1",[]] call ALS_fnc_dbGet isEqualTo _bad, "native DB guard prevents overwriting corrupt metadata"] call TEST_fnc_assert;

call TEST_fnc_reset;
[!([player,"name","Рубеж" call TEST_fnc_bytes,1] call ALSPMC_fnc_phoneDo), "name requires real PMC licence"] call TEST_fnc_assert;
[[player,"license","",2] call ALSPMC_fnc_phoneDo, "phone buys native licence"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,9], "phone licence still costs 1"] call TEST_fnc_assert;
[[player,"name","  Рубеж  и Ко  " call TEST_fnc_bytes,3] call ALSPMC_fnc_phoneDo, "phone accepts Cyrillic company name"] call TEST_fnc_assert;
[(ALSPMC_names get "p1") isEqualTo ("Рубеж и Ко" call TEST_fnc_bytes), "server trims and collapses spaces"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,9], "naming is free"] call TEST_fnc_assert;
private _state = player getVariable ["ALSPMC_phoneState",createHashMap];
[(_state get "reply") == 3 && {_state get "ok"}, "phone action acknowledgement preserves request token"] call TEST_fnc_assert;
[player,"status","",0] call ALSPMC_fnc_phoneDo;
private _polled = player getVariable ["ALSPMC_phoneState",createHashMap];
[(_polled get "reply") == 3 && {_polled get "ok"}, "background polling cannot lose rename acknowledgement"] call TEST_fnc_assert;
[(_state get "name") isEqualTo ("Рубеж и Ко" call TEST_fnc_bytes), "phone transports exact name as UTF8 bytes"] call TEST_fnc_assert;
[(count (_state get "nearby")) == 2, "phone lists nearby suitable buildings"] call TEST_fnc_assert;
[[player,"base","h_100_100",4] call ALSPMC_fnc_phoneDo, "phone purchases native warehouse base"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,8], "phone base still costs 1"] call TEST_fnc_assert;
_state = player getVariable ["ALSPMC_phoneState",createHashMap];
[(_state get "hasOwnBase") && {count (_state get "nearby") == 0}, "owned base replaces purchase choices"] call TEST_fnc_assert;
[(((_state get "bases") select 0) get "name") isEqualTo ("Рубеж и Ко" call TEST_fnc_bytes), "base displays founder's PMC name"] call TEST_fnc_assert;
[[player,"lock","h_100_100",5] call ALSPMC_fnc_phoneDo, "phone uses native base locking"] call TEST_fnc_assert;
["h_100_100" in ALS_locked, "native lock record updated"] call TEST_fnc_assert;
[[player,"unlock","h_100_100",6] call ALSPMC_fnc_phoneDo, "phone uses native base unlocking"] call TEST_fnc_assert;
[!("h_100_100" in ALS_locked), "native unlock record updated"] call TEST_fnc_assert;
private _savedNames = ["alspmc_names_v1",[]] call ALS_fnc_dbGet;
ALSPMC_names = createHashMap;
call ALSPMC_fnc_serverInit;
[(ALSPMC_names get "p1") isEqualTo ("Рубеж и Ко" call TEST_fnc_bytes), "name restored from existing world DB"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [10,8], "upgrade restores old base without rebuying"] call TEST_fnc_assert;
[[player,"name","Legacy & Рубеж" call TEST_fnc_bytes,7] call ALSPMC_fnc_phoneDo, "mixed Latin and Cyrillic rename supported"] call TEST_fnc_assert;
[[player,"sell","h_100_100",8] call ALSPMC_fnc_phoneDo, "phone sells through native sale wrapper"] call TEST_fnc_assert;
[(count ALSPMC_bases) == 0 && {(ALSPMC_names get "p1") isEqualTo ("Legacy & Рубеж" call TEST_fnc_bytes)}, "sale preserves PMC name"] call TEST_fnc_assert;
[!([player,"lock","h_110_100",9] call ALSPMC_fnc_phoneDo), "phone cannot manage ordinary unowned property"] call TEST_fnc_assert;
[!([player,"unknown","",10] call ALSPMC_fnc_phoneDo), "unknown phone command rejected"] call TEST_fnc_assert;

{
    [[_x] call ALSPMC_fnc_normalizeName isEqualTo [], "invalid UTF8 or name shape rejected"] call TEST_fnc_assert;
} forEach [[],[32,32,32],toArray "ab",toArray "<script>",toArray "a
b",[192,175,97],[226,130],[237,160,128],[244,144,128,128],[-1,98,99],[256,98,99],[97,98,1],[97,98,160],[97,98,226,128,139]];
private _long = []; for "_n" from 1 to 40 do {_long append ("Я" call TEST_fnc_bytes)};
[([_long] call ALSPMC_fnc_normalizeName) isEqualTo _long, "40 Cyrillic characters accepted without byte-count bug"] call TEST_fnc_assert;
_long append ("Я" call TEST_fnc_bytes);
[([_long] call ALSPMC_fnc_normalizeName) isEqualTo [], "41 Unicode characters rejected"] call TEST_fnc_assert;
call TEST_fnc_reset;
call ALSPMC_fnc_serverInit;
[ALSPMC_namesReady && {count ALSPMC_names == 0}, "alpha1 save without names upgrades automatically"] call TEST_fnc_assert;

call compile preprocessFileLineNumbers "tests/desktop_transactions.sqf";
call compile preprocessFileLineNumbers "tests/quest_transactions.sqf";
call compile preprocessFileLineNumbers "tests/contract_transactions.sqf";
call compile preprocessFileLineNumbers "tests/phone_integration.sqf";
diag_log format ["TEST_COMPLETE: %1 assertions",TEST_count];
