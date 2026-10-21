// New contracts: production planning is separately probed below; only world
// placement/AI/network calls are replaced. Mission logic and wallets are real.
private _findBefore = ALS_fnc_findPlayer;
private _planBefore = ALSPMC_fnc_contractPlan;
private _siteBefore = ALSPMC_fnc_questSite;
private _sitesBefore = ALSPMC_fnc_contractSites;
ALS_fnc_findPlayer = {
    private _uid = _this select 0;
    (TEST_players select {([_x] call ALS_fnc_uid) == _uid}) param [0, objNull]
};
TEST_building = "TestBuilding_F" createVehicle [3100,100,0];
TEST_building2 = "TestBuilding_F" createVehicle [6100,100,0];
TEST_road = "TestVan_F" createVehicle [6100,100,0];
TEST_fnc_sitesFixture = {
    switch (_this select 0) do {
        case "army": {[[[3100,100,0],"army",objNull,[],"Military"]]};
        case "enemyBase";
        case "assaultBase": {[[[3100,100,0],"b_enemy",objNull,[],"Opfor"],[[6100,100,0],"army",objNull,[],"Military"]]};
        case "government": {[[[6100,100,0],"gov",TEST_building2,[6100,100,1],""]]};
        case "commercial": {[[[3100,100,0],"shop1",objNull,[],""],[[6100,100,0],"shop2",objNull,[],""]]};
        default {[]};
    }
};
// Probe the real route/site planner using known native registry/geometry
// boundaries. No planning branch is removed or replaced in these probes.
call TEST_fnc_reset;
["p1","alspmc_pmc"] call ALS_fnc_licGrant;
[player,"h_100_100"] call ALSPMC_fnc_buyBase;
ALSPMC_fnc_contractSites = TEST_fnc_sitesFixture;
ALS_fnc_warRoadSpot = {[[(_this select 0)],90,[90]]};
ALS_fnc_roadNear = {TEST_road setPos (_this select 0); TEST_road};
ALS_fnc_houseObj = {if ((_this select 0) == "shop1") then {TEST_building} else {TEST_building2}};
ALS_fnc_houseFloor = {(getPos (_this select 0)) vectorAdd [0,0,1] call {[_this]}};
ALSPMC_fnc_questSite = {[3100,100,0]};
(ALS_war get "own") set ["army","Military"]; (ALS_war get "own") set ["b_enemy","Opfor"];
{
    private _plan = [player,_x] call _planBefore;
    [count _plan > 0 && {count (_plan get "site") == 3}, "production planner finds a native site/route: " + (_x select 0)] call TEST_fnc_assert;
    if ((_x select 2) == "guard") then {[count (_plan get "indoor") == 3, "guard planner requires an actual indoor floor position"] call TEST_fnc_assert};
    if ((_x select 2) == "convoy") then {[count (_plan get "truckPos") == 3 && {count (_plan get "destination") == 3}, "convoy planner resolves both endpoints to native roads"] call TEST_fnc_assert};
} forEach (call ALSPMC_fnc_contractCatalog);
// Reject actual near-base sites even when an external registry includes them.
private _nearSites = ALSPMC_fnc_contractSites;
ALSPMC_fnc_contractSites = {[[[200,100,0],"near",TEST_building,[200,100,1],"Military"]]};
[count ([player,(call ALSPMC_fnc_contractCatalog) select 3,"near"] call _planBefore) == 0, "selected assault base inside the exclusion circle is rejected"] call TEST_fnc_assert;
ALSPMC_fnc_contractSites = _nearSites;
private _roadBefore = ALS_fnc_warRoadSpot;
ALS_fnc_warRoadSpot = {[[[200,100,0]],90,[90]]};
[count ([player,(call ALSPMC_fnc_contractCatalog) select 1] call _planBefore) == 0, "near-base road snap is rejected even when source outpost is distant"] call TEST_fnc_assert;
ALS_fnc_warRoadSpot = _roadBefore;
[[[100,100,0],[2100,100,0]] call ALSPMC_fnc_contractFar && {!([[100,100,0],[2099,100,0]] call ALSPMC_fnc_contractFar)}, "2 km boundary is inclusive and one metre inside is rejected"] call TEST_fnc_assert;
ALSPMC_fnc_contractSites = _sitesBefore;
ALSPMC_contractSitesCache = createHashMap;
ALS_war = createHashMapFromArray [["on",true],["bases",[["army",[3100,100,0],"outpost",8,"Ours"],["enemy",[6100,100,0],"outpost",8,"Theirs"]]],
    ["own",createHashMapFromArray [["army","Military"],["enemy","Opfor"]]]];
[count (["army"] call ALSPMC_fnc_contractSites) == 1 && {count (["enemyBase"] call ALSPMC_fnc_contractSites) == 1}, "native site provider separates friendly outposts and actual opposing bases"] call TEST_fnc_assert;
ALS_war set ["on",false]; ALSPMC_contractSitesCache = createHashMap;
[count (["enemyBase"] call ALSPMC_fnc_contractSites) == 0, "inactive native war does not invent an opposing military base"] call TEST_fnc_assert;
[count (["assaultBase"] call ALSPMC_fnc_contractSites) == 2, "assault selection includes bases of both armies even when native war is off"] call TEST_fnc_assert;
// Both founders query the same cached registry; exclusion is per company.
private _otherFounder = "TestPlayer_F" createVehicle [3100,100,0];
_otherFounder setVariable ["ALS_uid","p2"];
ALS_houses set ["p2_base",[[3100,100,0],"warehouse.p3d",300,2,"Other town",50000,"Industrial","Good"]];
ALS_owned set ["p2_base","p2"]; ALSPMC_bases set ["p2_base",["p2",50000,1]];
[count (["assaultBase",player] call ALSPMC_fnc_contractSites) == 2 && {count (["assaultBase",_otherFounder] call ALSPMC_fnc_contractSites) == 1}, "shared site cache applies the 2 km circle separately to each founder"] call TEST_fnc_assert;
deleteVehicle _otherFounder;
ALSPMC_fnc_contractSites = TEST_fnc_sitesFixture;
ALSPMC_fnc_contractPlan = {
    createHashMapFromArray [["base",[100,100,0]],["site",[3100,100,0]],["source","b_enemy"],["owner","Opfor"],["route",if (((_this select 1) select 2) == "sector") then {[[3300,100,0],[3300,300,0],[3100,300,0],[3100,100,0]]} else {[]}],["building",TEST_building],
        ["indoor",[3100,100,1]],["destination",[6100,100,0]],["truckPos",[3100,100,0]],["truckDir",90]]
};
TEST_fnc_contractReset = {
    call TEST_fnc_reset;
    TEST_actor = player;
    player setPos [100,100,0];
    ["p1","alspmc_pmc"] call ALS_fnc_licGrant;
    [player,"h_100_100"] call ALSPMC_fnc_buyBase;
    ["money_p1",[0,0]] call ALS_fnc_dbSet;
    call ALSPMC_fnc_questInit;
    ALS_war set ["bases",[["b_enemy",[3100,100,0],"outpost",8,"Enemy base"],["army",[6100,100,0],"outpost",8,"Army base"]]];
    (ALS_war get "own") set ["b_enemy","Opfor"];
    (ALS_war get "own") set ["army","Military"];
};
TEST_fnc_emitContractState = {
    [TEST_actor,0,true] call ALSPMC_fnc_phoneSync;
    diag_log ("TEST_CONTRACT_STATE: " + ((TEST_actor getVariable "ALSPMC_phoneState") call TEST_fnc_toJSON));
};
TEST_fnc_emitPatrolState = {
    [TEST_actor,0,true] call ALSPMC_fnc_phoneSync;
    diag_log ("TEST_PATROL_STATE: " + ((TEST_actor getVariable "ALSPMC_phoneState") call TEST_fnc_toJSON));
};
// Scenario probes request valid server tickets. Pool generation/expiry is
// tested independently below, without changing the production validator.
TEST_fnc_offerKey = {
    params ["_type"];
    private _board = [TEST_actor] call ALSPMC_fnc_contractOffers;
    private _offered = (_board get "offers") select {(_x select 1) == _type};
    if (_offered isEqualTo []) then {
        private _entry = ((call ALSPMC_fnc_contractCatalog) select {(_x select 0) == _type}) select 0;
        private _category = _entry select 1;
        private _same = (_board get "offers") findIf {
            private _key = _x select 1;
            ((call ALSPMC_fnc_contractCatalog) findIf {(_x select 0) == _key && {(_x select 1) == _category}}) >= 0
        };
        private _new = ["test_" + _type, _type];
        if (_same >= 0) then {(_board get "offers") set [_same,_new]} else {(_board get "offers") pushBack _new};
        _offered = [_new];
    };
    (_offered select 0) select 0
};
TEST_fnc_contractStart = {
    params ["_type", "_token"];
    [[TEST_actor,"questStart",[_type] call TEST_fnc_offerKey,_token] call ALSPMC_fnc_phoneDo, "start real contract: " + _type] call TEST_fnc_assert;
    private _c = ["p1"] call ALS_fnc_crewOf;
    ALS_coopJobs get (_c get "job")
};
TEST_fnc_contractReady = {
    params ["_job", "_token"];
    TEST_actor setPos [3100,100,0];
    if (missionNamespace getVariable ["TEST_captureContractUI", false]) then {call TEST_fnc_emitContractState};
    [[TEST_actor,"questReady","q" + str (_job get "alspmcQuestId"),_token] call ALSPMC_fnc_phoneDo,
        "readiness at the real contract site: " + (_job get "alspmcType")] call TEST_fnc_assert;
    _job set ["alspmcAttackPlanned", false];
    if (missionNamespace getVariable ["TEST_captureContractUI", false]) then {
        call TEST_fnc_emitContractState;
        TEST_contractNativeMirror = +(TEST_actor getVariable "ALS_coopJob");
    };
};
TEST_fnc_contractKill = {
    params ["_job", ["_killer",player]];
    {private _victim = _x select 0; if (!isNull _victim) then {_victim setDamage 1; [_victim,_killer,_killer] call ALSPMC_fnc_questKilled}} forEach (_job get "alspmcEnemies");
};

call TEST_fnc_contractReset;
private _catalog = call ALSPMC_fnc_contractCatalog;
[count _catalog == 10 && {count (_catalog select {(_x select 1) == "government"}) == 7}, "catalog contains seven government and three private contracts"] call TEST_fnc_assert;
[(["p1"] call ALSPMC_fnc_contractProfile) get "level" == 1, "existing founder starts with rating level one"] call TEST_fnc_assert;
private _assets = call ALSPMC_fnc_contractAssets;
[(_assets get "militia") isEqualTo ["NativeGang_Rifleman","NativeGang_Scout"], "enemy classes come from the native Gangs role, not an unrelated 3CB faction"] call TEST_fnc_assert;
[count ((_assets get "weapons") select 0) > 0 && {count ((_assets get "weapons") select 2) > 0} && {
    ((_assets get "weapons") findIf {(_x findIf {(_x select 0) in ["rhs_weap_rpg7","rhs_weap_ak74_gp25"]}) >= 0}) < 0
}, "installed mod weapons have magazine pairs and exclude launchers/GL muzzles"] call TEST_fnc_assert;
// Late native faction resolution must replace a cached fallback.
ALS_factions = createHashMap;
private _fallbackAssets = call ALSPMC_fnc_contractAssets;
[(_fallbackAssets get "militia") isEqualTo ["I_C_Soldier_Bandit_1_F"], "native gang fallback is used only while its faction registry is empty"] call TEST_fnc_assert;
ALS_factions = createHashMapFromArray [["Gangs",createHashMapFromArray [["men",["NativeGang_Scout"]]]]];
[ ((call ALSPMC_fnc_contractAssets) get "militia") isEqualTo ["NativeGang_Scout"], "native faction changes invalidate the cached fallback"] call TEST_fnc_assert;
ALS_factions = createHashMapFromArray [["Gangs",createHashMapFromArray [["men",["NativeGang_Rifleman","NativeGang_Scout"]]]]];
private _supportedSites = ALSPMC_fnc_contractSites;
ALSPMC_fnc_contractSites = {[]};
private _limitedBoard = [player] call ALSPMC_fnc_contractOffers;
[count (_limitedBoard get "offers") == 6 && {count (((_limitedBoard get "offers") apply {_x select 0}) arrayIntersect ((_limitedBoard get "offers") apply {_x select 0})) == 6}, "a map without service sites still has six independently ticketed field contracts"] call TEST_fnc_assert;
[ ((_limitedBoard get "offers") findIf {!((_x select 1) in ["gov_bandits","gov_mines","gov_sector"])}) < 0, "fallback board never invents unavailable commercial/army facilities"] call TEST_fnc_assert;
ALSPMC_fnc_contractSites = _supportedSites;
ALSPMC_contractBoards = createHashMap;
private _board = [player] call ALSPMC_fnc_contractOffers;
private _initialOffers = +(_board get "offers");
[count _initialOffers == 6 && {count (_initialOffers select {(_x select 1) in ["gov_bandits","gov_convoy","gov_guard","gov_sector","gov_mines"]}) == 4}, "initial rotating pool contains six eligible offers: four government and two private"] call TEST_fnc_assert;
[( ([player] call ALSPMC_fnc_contractOffers) get "offers") isEqualTo _initialOffers, "reopening the board never rerolls offers"] call TEST_fnc_assert;
[!([player,"questStart","gov_bandits",1900] call ALSPMC_fnc_phoneDo), "raw contract type cannot bypass the server's offer pool"] call TEST_fnc_assert;
private _firstTicket = (_initialOffers select 0) select 0;
[[player,"questStart",_firstTicket,1901] call ALSPMC_fnc_phoneDo, "a valid pool ticket starts its actual scenario"] call TEST_fnc_assert;
[player,"questCancel","q1",1902] call ALSPMC_fnc_phoneDo;
[count (([player] call ALSPMC_fnc_contractOffers) get "offers") == 6, "settling a cancelled mission restores six offers without waiting for expiry"] call TEST_fnc_assert;
[!([player,"questStart",_firstTicket,1903] call ALSPMC_fnc_phoneDo), "consumed ticket cannot start another operation"] call TEST_fnc_assert;
TEST_realTime = (_board get "expires") - 1;
[count (([player] call ALSPMC_fnc_contractOffers) get "offers") == 6, "board remains stable until the ten-minute boundary"] call TEST_fnc_assert;
TEST_realTime = _board get "expires";
private _renewed = [player] call ALSPMC_fnc_contractOffers;
[count (_renewed get "offers") == 6 && {((_renewed get "offers") findIf {(_x select 0) == _firstTicket}) < 0}, "expiry generates a fresh pool with new server tickets"] call TEST_fnc_assert;
[!([player,"questStart",_firstTicket,1904] call ALSPMC_fnc_phoneDo), "expired ticket is rejected even when its type appears again"] call TEST_fnc_assert;
call TEST_fnc_contractReset;
call TEST_fnc_emitContractState;
[!([player,"questStart",["gov_base"] call TEST_fnc_offerKey,2000] call ALSPMC_fnc_phoneDo) && {!([player,"questStart",["gov_patrol"] call TEST_fnc_offerKey,2001] call ALSPMC_fnc_phoneDo)}, "base and patrol assaults are locked below levels four and three"] call TEST_fnc_assert;
ALSPMC_ratingXP set ["p1",300];
[(["p1"] call ALSPMC_fnc_contractProfile) get "level" == 3, "threshold 300 unlocks rating level three"] call TEST_fnc_assert;
[!([player,"questStart",["gov_base"] call TEST_fnc_offerKey,2002] call ALSPMC_fnc_phoneDo), "base assault remains locked at level three"] call TEST_fnc_assert;
ALSPMC_ratingXP set ["p1",700];
[(["p1"] call ALSPMC_fnc_contractProfile) get "level" == 4, "threshold 700 unlocks rating level four"] call TEST_fnc_assert;

// Every requested scenario completes via native acceptance/tick and our scoped
// settlement. No new scenario may go through native per-member/company pay.
private _offset = 0;
{
    private _entry = _x;
    private _type = _entry select 0;
    private _mode = _entry select 2;
    TEST_captureContractUI = _type == "gov_guard";
    call TEST_fnc_contractReset;
    ALSPMC_ratingXP set ["p1",1300];
    if (_type == "gov_guard") then {
        private _boardUI = [TEST_actor] call ALSPMC_fnc_contractOffers;
        _boardUI set ["offers",[["ui_base","gov_base"],["ui_guard","gov_guard"],["ui_route","gov_sector"],["ui_mines","gov_mines"],["ui_vip","private_vip"],["ui_commercial","private_guard"]]];
        call TEST_fnc_emitContractState;
    };
    private _job = [_type,2100 + _offset] call TEST_fnc_contractStart;
    _offset = _offset + 2;
    private _qid = _job get "alspmcQuestId";
    private _reward = (_entry select 4) * 4;
    if (_type == "gov_guard") then {call TEST_fnc_emitContractState};
    [(_job get "alspmcProfile") get "level" == 5 && {(_job get "pay") == _reward}, "accepted rating and budget are frozen: " + _type] call TEST_fnc_assert;
    if (_mode in ["bandits","enemyPatrol","base"]) then {
        [((_job get "alspmcEnemies") findIf {!(((_x select 0) getVariable ["TEST_class",""]) in ["NativeGang_Rifleman","NativeGang_Scout"])}) < 0, "spawned enemies use native Gangs classes: " + _type] call TEST_fnc_assert;
    };
    if (_mode == "bandits") then {
        [count (_job get "alspmcEnemies") >= 17 && {count (_job get "alspmcEnemies") <= 27}, "level five creates 15-25 infantry plus the pickup crew"] call TEST_fnc_assert;
        [((_job get "alspmcObjects") findIf {(_x getVariable ["TEST_class",""]) == "I_G_Offroad_01_armed_F"}) >= 0, "highest bandit tier always has one machine-gun pickup"] call TEST_fnc_assert;
        [((_job get "alspmcEnemies") findIf {!((((_x select 0) getVariable ["ALSPMC_loadout",[]]) select 0) in ["rhs_weap_akm","rhs_weap_pkm"])}) < 0, "high tier uses installed RHS rifle/MG pool without launchers"] call TEST_fnc_assert;
        [((_job get "alspmcEnemies") findIf {(side ((_x select 0) call TEST_fnc_group)) != east || {((_x select 0) getVariable ["TEST_rating",0]) < 0}}) < 0, "mixed mod classes are explicitly joined to friendly EAST groups with positive ratings"] call TEST_fnc_assert;
        [((_job get "alspmcEnemies") findIf {isNil {(_x select 0) getVariable "TEST_HandleRating"} || {([0,-20000] call ((_x select 0) getVariable "TEST_HandleRating")) != 0}}) < 0, "rating handler prevents combat from turning own AI into renegades"] call TEST_fnc_assert;
        [([east,civilian] call TEST_fnc_getFriend) == 0 && {([east,east] call TEST_fnc_getFriend) == 1}, "own AI is hostile to civilian players and friendly to its own side"] call TEST_fnc_assert;
    };
    if (_mode == "enemyPatrol") then {[count (_job get "alspmcEnemies") >= 3 && {count (_job get "alspmcEnemies") <= 10}, "enemy patrol total never exceeds ten including vehicle crew"] call TEST_fnc_assert};
    if (_mode in ["guard","convoy","vip","sector"]) then {
        [(count (_job get "alspmcObjects")) == 0 && {(_job get "state") == "rendezvous"}, "assets wait for readiness: " + _type] call TEST_fnc_assert;
        [!([player,"questReady","q" + str _qid,2500 + _offset] call ALSPMC_fnc_phoneDo), "readiness far from site is rejected: " + _type] call TEST_fnc_assert;
        [_job,2600 + _offset] call TEST_fnc_contractReady;
    };
    private _remainingTickets = (([TEST_actor] call ALSPMC_fnc_contractOffers) get "offers") select {(_x select 0) != (_job get "alspmcOfferSlot")};
    private _expiresBefore = ([TEST_actor] call ALSPMC_fnc_contractOffers) get "expires";
    switch (_mode) do {
        case "bandits";
        case "enemyPatrol";
        case "base": {[_job] call TEST_fnc_contractKill};
        case "guard": {
            TEST_realTime = (_job get "alspmcDutyAt") + 599;
            call ALS_fnc_coopTick;
            [_qid in ALSPMC_questRecords && {(ALSPMC_questRecords get _qid) select 1 == "active"}, "duty does not finish at 599 real seconds: " + _type] call TEST_fnc_assert;
            TEST_realTime = (_job get "alspmcDutyAt") + 600;
        };
        case "sector": {
            {TEST_actor setPos _x; call ALS_fnc_coopTick} forEach ((_job get "alspmcPlan") get "route");
        };
        case "convoy": {
            [count TEST_driveCalls == 1, "convoy calls native aiDrive once after readiness"] call TEST_fnc_assert;
            (_job get "alspmcTruck") setPos [6100,100,0];
        };
        case "vip": {
            [!isNull (_job get "alspmcProtected"), "readiness creates one VIP"] call TEST_fnc_assert;
            [((_job get "alspmcProtected") call TEST_fnc_uniform) in ["U_C_FormalSuit_01_black_F","U_C_FormalSuit_01_gray_F","U_NikosAgedBody"], "VIP receives a formal suit instead of random beachwear"] call TEST_fnc_assert;
            (_job get "alspmcProtected") setPos [6100,100,0]; TEST_actor setPos [6100,100,0];
        };
        case "mines": {
            TEST_actor setPos [3100,100,0];
            TEST_randomQueue = [0,0];
            call ALS_fnc_coopTick;
            [(_job get "state") == "active", "arriving starts the mine survey"] call TEST_fnc_assert;
            [count (_job get "alspmcMines") == 3, "armed branch creates real mine objects for the clearance task"] call TEST_fnc_assert;
            {if (_forEachIndex mod 2 == 0) then {_x setVariable ["TEST_mineActive",false]} else {deleteVehicle _x}} forEach (_job get "alspmcMines");
            TEST_realTime = (_job get "alspmcSurveyAt") + 60;
        };
    };
    call ALS_fnc_coopTick;
    private _afterBoard = [TEST_actor] call ALSPMC_fnc_contractOffers;
    [count (_afterBoard get "offers") == 6 && {if (TEST_realTime < _expiresBefore) then {(_afterBoard get "expires") == _expiresBefore} else {(_afterBoard get "expires") == TEST_realTime + 600}}, "completion refills six slots without resetting ten-minute expiry: " + _type] call TEST_fnc_assert;
    [TEST_realTime >= _expiresBefore || {(_remainingTickets findIf {!(_x in (_afterBoard get "offers"))}) < 0}, "completion preserves every unconsumed offer: " + _type] call TEST_fnc_assert;
    private _settledTickets = +(_afterBoard get "offers");
    [(ALSPMC_questRecords get _qid) select 1 == "done", "scenario completes: " + _type] call TEST_fnc_assert;
    [["p1"] call ALS_fnc_moneyGet isEqualTo [0,_reward], "entire budget reaches founder bank: " + _type] call TEST_fnc_assert;
    [(ALSPMC_ratingXP get "p1") == 1300 + (_entry select 5), "only success adds configured rating XP: " + _type] call TEST_fnc_assert;
    [((_job get "alspmcObjects") findIf {!isNull _x}) < 0, "only spawned scenario objects cleaned up: " + _type] call TEST_fnc_assert;
    [([east,civilian] call TEST_fnc_getFriend) == 1, "last mission cleanup restores native EAST/civilian relation: " + _type] call TEST_fnc_assert;
    if (_type == "gov_guard") then {call TEST_fnc_emitContractState};
    call ALS_fnc_coopTick;
    [_job,1] call ALS_fnc_coopEnd;
    [(([TEST_actor] call ALSPMC_fnc_contractOffers) get "offers") isEqualTo _settledTickets, "replayed settlement cannot reroll or duplicate offers: " + _type] call TEST_fnc_assert;
    [["p1"] call ALS_fnc_moneyGet isEqualTo [0,_reward], "repeat finish cannot pay twice: " + _type] call TEST_fnc_assert;
} forEach _catalog;
TEST_captureContractUI = false;

// Founder-only payment also overrides a native company's jobsTo setting.
call TEST_fnc_contractReset;
private _p2 = "TestPlayer_F" createVehicle [110,100,0];
_p2 setVariable ["ALS_uid","p2"]; _p2 setVariable ["TEST_player",true]; _p2 setVariable ["TEST_owner",5];
TEST_players pushBack _p2;
private _crew = createHashMapFromArray [["id","c1"],["leader","p1"],["members",["p1","p2"]],["job",-1]];
ALS_crews set ["c1",_crew]; ALS_crewSeq = 1;
ALS_companies set ["co_1",createHashMapFromArray [["id","co_1"],["name","Co"],["members",["p1","p2"]],["jobsTo",true],["ledger",[]]]];
private _job = ["gov_bandits",3000] call TEST_fnc_contractStart;
private _spawnedBefore = count (_job get "alspmcObjects");
[!([_job,[200,100,0]] call ALSPMC_fnc_contractAttack) && {count (_job get "alspmcObjects") == _spawnedBefore}, "dynamic enemy spawn inside the base exclusion circle is refused without partial objects"] call TEST_fnc_assert;
[count (_job get "alspmcEnemies") >= 3 && {count (_job get "alspmcEnemies") <= 5}, "level one bandit group has three to five infantry and no vehicle crew"] call TEST_fnc_assert;
[((_job get "alspmcEnemies") findIf {!((((_x select 0) getVariable ["ALSPMC_loadout",[]]) select 0) in ["rhs_weap_makarov_pm"])}) < 0, "level one force uses installed mod pistols"] call TEST_fnc_assert;
[_job,_p2] call TEST_fnc_contractKill;
call ALS_fnc_coopTick;
[["p1"] call ALS_fnc_moneyGet isEqualTo [0,4000] && {(["p2"] call ALS_fnc_moneyGet) isEqualTo [0,0]} && {(["co_1"] call ALS_fnc_moneyGet) isEqualTo [0,0]}, "new contract pays founder only, regardless of killer or company jobsTo"] call TEST_fnc_assert;

call TEST_fnc_contractReset;
_job = ["gov_convoy",3100] call TEST_fnc_contractStart;
[_job,3101] call TEST_fnc_contractReady;
private _truck = _job get "alspmcTruck";
private _driver = _job get "alspmcDriver";
_driver setDamage 1;
call ALS_fnc_coopTick;
[count ALS_coopJobs == 1 && {_job get "alspmcDriverDead"}, "dead driver does not fail an intact truck"] call TEST_fnc_assert;
_truck setDamage 1;
call ALS_fnc_coopTick;
[(ALSPMC_questRecords get 1) select 7 == "truck" && {(["p1"] call ALS_fnc_moneyGet) isEqualTo [0,0]}, "destroyed truck fails without a reward"] call TEST_fnc_assert;

call TEST_fnc_contractReset;
_job = ["private_guard",3200] call TEST_fnc_contractStart;
[_job,3201] call TEST_fnc_contractReady;
(_job get "alspmcProtected") setDamage 1;
call ALS_fnc_coopTick;
[(ALSPMC_questRecords get 1) select 7 == "protected", "dead facility NPC fails the protection contract"] call TEST_fnc_assert;
call TEST_fnc_contractReset;
_job = ["private_vip",3202] call TEST_fnc_contractStart;
[_job,3203] call TEST_fnc_contractReady;
(_job get "alspmcProtected") setDamage 1;
call ALS_fnc_coopTick;
[(ALSPMC_questRecords get 1) select 7 == "protected", "dead VIP fails the escort contract"] call TEST_fnc_assert;

call TEST_fnc_contractReset;
_job = ["gov_sector",3300] call TEST_fnc_contractStart;
[_job,3301] call TEST_fnc_contractReady;
player setPos [1500,100,0]; TEST_realTime = TEST_realTime + 1200;
call ALS_fnc_coopTick;
[(ALSPMC_questRecords get 1) select 1 == "active" && {(_job get "alspmcRouteIndex") == 0}, "time or leaving the old sector cannot finish/fail the checkpoint patrol"] call TEST_fnc_assert;
player setPos [3300,300,0]; call ALS_fnc_coopTick;
[(_job get "alspmcRouteIndex") == 0, "visiting a later checkpoint cannot skip the first one"] call TEST_fnc_assert;
call TEST_fnc_emitPatrolState;
player setPos [3300,100,0]; call ALS_fnc_coopTick;
[(_job get "alspmcRouteIndex") == 1 && {(_job get "alspmcLeft") == -1} && {(player getVariable "ALS_coopJob") get "sector" isEqualTo []}, "next checkpoint replaces the old area marker and duty timer"] call TEST_fnc_assert;
call TEST_fnc_emitPatrolState;
{player setPos _x; call ALS_fnc_coopTick} forEach ((_job get "alspmcPlan") get "route");
[(ALSPMC_questRecords get 1) select 1 == "done", "visiting every checkpoint in order completes without a ten-minute timer"] call TEST_fnc_assert;

call TEST_fnc_contractReset;
_job = ["gov_guard",3310] call TEST_fnc_contractStart;
[_job,3311] call TEST_fnc_contractReady;
_job set ["alspmcAttackPlanned",true]; _job set ["alspmcAttackAt",TEST_realTime];
call ALS_fnc_coopTick;
[(_job get "alspmcAttackDone") && {count (_job get "alspmcEnemies") >= 3} && {count TEST_attackCalls > 0}, "scheduled guard attack creates attackers and native attack orders"] call TEST_fnc_assert;
[player,"questCancel","q1",3312] call ALSPMC_fnc_phoneDo;
call TEST_fnc_contractReset;
_job = ["private_vip",3320] call TEST_fnc_contractStart;
[_job,3321] call TEST_fnc_contractReady;
_job set ["alspmcAttackPlanned",true];
(_job get "alspmcProtected") setPos [4200,100,0]; player setPos [4200,100,0];
TEST_realTime = TEST_realTime + 31;
call ALS_fnc_coopTick;
[(_job get "alspmcAttackDone") && {count (_job get "alspmcEnemies") >= 3}, "VIP ambush waits for progress along the route and then targets the escorted person"] call TEST_fnc_assert;
[player,"questCancel","q1",3322] call ALSPMC_fnc_phoneDo;
call TEST_fnc_contractReset;
_job = ["gov_mines",3330] call TEST_fnc_contractStart;
player setPos [3100,100,0]; TEST_randomQueue = [0.99];
call ALS_fnc_coopTick;
[count (_job get "alspmcMines") == 0 && {(ALSPMC_questRecords get 1) select 1 == "active"}, "clean minefield still requires an on-site survey"] call TEST_fnc_assert;
TEST_realTime = TEST_realTime + 60; call ALS_fnc_coopTick;
[(ALSPMC_questRecords get 1) select 1 == "done", "survey completes a field where no mines were rolled"] call TEST_fnc_assert;

// Respawn is allowed until the instant that the whole roster is dead.
call TEST_fnc_contractReset;
private _p1Body = "TestPlayer_F" createVehicle [100,100,0];
_p1Body setVariable ["ALS_uid","p1"]; _p1Body setVariable ["TEST_player",true]; _p1Body setVariable ["TEST_owner",4];
TEST_actor = _p1Body; TEST_players = [_p1Body,_p2];
_crew = createHashMapFromArray [["id","c1"],["leader","p1"],["members",["p1","p2"]],["job",-1]];
ALS_crews set ["c1",_crew]; ALS_crewSeq = 1;
_job = ["gov_bandits",3400] call TEST_fnc_contractStart;
_p1Body setDamage 1; [_p1Body,objNull,objNull] call ALSPMC_fnc_questKilled;
[(_job get "alspmcResult") == "", "one casualty does not fail a group with a living participant"] call TEST_fnc_assert;
private _respawn1 = "TestPlayer_F" createVehicle [110,100,0];
_respawn1 setVariable ["ALS_uid","p1"]; _respawn1 setVariable ["TEST_player",true];
TEST_players = [_respawn1,_p2];
[count ([_job] call ALSPMC_fnc_contractTeam) == 2, "respawned participant rejoins the current contract"] call TEST_fnc_assert;
_p2 setDamage 1; [_p2,objNull,objNull] call ALSPMC_fnc_questKilled;
[(_job get "alspmcResult") == "", "second casualty is allowed while the first has respawned"] call TEST_fnc_assert;
_respawn1 setDamage 1; [_respawn1,objNull,objNull] call ALSPMC_fnc_questKilled;
[(_job get "alspmcResult") == "wiped", "simultaneous full-roster death is captured before the next tick"] call TEST_fnc_assert;
_respawn1 setDamage 0; _p2 setDamage 0;
call ALS_fnc_coopTick;
[(ALSPMC_questRecords get 1) select 7 == "wiped" && {(["p1"] call ALS_fnc_moneyGet) isEqualTo [0,0]}, "respawning after a recorded total wipe cannot undo the failure"] call TEST_fnc_assert;
{deleteVehicle _x} forEach [_p1Body,_respawn1];

// Replace one selected native garrison; preserve other bases and resume the
// native generator after cleanup, without changing ownership or supply.
call TEST_fnc_contractReset;
ALSPMC_ratingXP set ["p1",700];
private _nativeGroup = [west,true] call TEST_fnc_createGroup;
private _nativeSoldier = [_nativeGroup,["O_G_Soldier_F",[3100,100,0],[],0,"NONE"]] call TEST_fnc_createUnit;
ALS_warGar set ["b_enemy",createHashMapFromArray [["grp",_nativeGroup],["n",1]]];
_job = ["gov_base",3500] call TEST_fnc_contractStart;
[isNull _nativeSoldier && {count (_job get "alspmcEnemies") >= 15}, "contract replaces a weak native garrison with at least fifteen guards"] call TEST_fnc_assert;
ALS_war set ["bases",[["b_enemy",[3100,100,0],"outpost",8,"Target"],["other",[5000,100,0],"outpost",8,"Other"]]];
["probe"] call ALS_fnc_warBases;
[count TEST_seenNativeBases == 1 && {(TEST_seenNativeBases select 0) select 0 == "other"}, "native base tick excludes only the leased target"] call TEST_fnc_assert;
[count (ALS_war get "bases") == 2, "native world registry is restored immediately after its tick"] call TEST_fnc_assert;
[[player,"questCancel","q1",3501] call ALSPMC_fnc_phoneDo, "reinforced base contract can be cancelled"] call TEST_fnc_assert;
[!("b_enemy" in ALSPMC_garrisonLeases) && {!("b_enemy" in ALS_warGar)} && {((ALS_war get "own") get "b_enemy") == "Opfor"}, "cancellation releases the base for normal generation without changing its owner"] call TEST_fnc_assert;
["probe"] call ALS_fnc_warBases;
[count TEST_seenNativeBases == 2, "released base reaches the native generator again"] call TEST_fnc_assert;

// The server validates the selected native base, not a client-supplied position.
call TEST_fnc_contractReset;
ALSPMC_ratingXP set ["p1",700];
private _fixedPlan = ALSPMC_fnc_contractPlan;
ALSPMC_fnc_contractPlan = _planBefore;
private _baseTicket = ["gov_base"] call TEST_fnc_offerKey;
[!([player,"questStart",_baseTicket + "|invented_base",3510] call ALSPMC_fnc_phoneDo), "invented base selection cannot launch an assault"] call TEST_fnc_assert;
[[player,"questStart",_baseTicket + "|army",3511] call ALSPMC_fnc_phoneDo, "server accepts a selected Military base outside an active war"] call TEST_fnc_assert;
_job = ALS_coopJobs get ((["p1"] call ALS_fnc_crewOf) get "job");
[((_job get "alspmcPlan") get "source") == "army" && {((_job get "alspmcPlan") get "owner") == "Military"}, "selected base and actual owner are frozen in the real plan"] call TEST_fnc_assert;
[player,"questCancel","q1",3512] call ALSPMC_fnc_phoneDo;
ALSPMC_fnc_contractPlan = _fixedPlan;

// Multiple missions share relation leases; native wanted-side changes never
// require changing player ratings or borrowing their real groups.
call TEST_fnc_contractReset;
private _lease1 = createHashMapFromArray [["alspmcQuestId",501]];
private _lease2 = createHashMapFromArray [["alspmcQuestId",502]];
["acquire",_lease1] call ALSPMC_fnc_contractHostility;
["acquire",_lease2] call ALSPMC_fnc_contractHostility;
["release",_lease1] call ALSPMC_fnc_contractHostility;
[[east,civilian] call TEST_fnc_getFriend == 0, "ending one mission keeps hostility needed by another"] call TEST_fnc_assert;
["release",_lease2] call ALSPMC_fnc_contractHostility;
[[east,civilian] call TEST_fnc_getFriend == 1, "ending the last lease restores native diplomacy"] call TEST_fnc_assert;
_job = ["gov_bandits",3520] call TEST_fnc_contractStart;
private _outlawGroup = [east,true] call TEST_fnc_createGroup;
player setVariable ["TEST_group",_outlawGroup];
call ALS_fnc_coopTick;
[(_job get "alspmcEnemySide") == resistance && {((_job get "alspmcEnemies") findIf {side ((_x select 0) call TEST_fnc_group) != resistance}) < 0}, "native outlaw-side change moves only combat AI to a hostile side"] call TEST_fnc_assert;
[[resistance,east] call TEST_fnc_getFriend == 0 && {(player call TEST_fnc_group) isEqualTo _outlawGroup}, "outlaw remains in his real group while enemies target his actual side"] call TEST_fnc_assert;
player setVariable ["TEST_group",nil];
[player,"questCancel","q1",3521] call ALSPMC_fnc_phoneDo;
deleteGroup _outlawGroup;

// Rating/receipt persistence uses the same native DB and an optional new key.
call TEST_fnc_contractReset;
_job = ["gov_bandits",3600] call TEST_fnc_contractStart;
[_job] call TEST_fnc_contractKill; call ALS_fnc_coopTick;
private _database = +ALS_db;
call TEST_fnc_reset; ALS_db = _database;
call ALSPMC_fnc_questInit;
[(ALSPMC_ratingXP get "p1") == 10 && {(ALSPMC_contractMeta get 1) select 3 == 4000}, "reload restores owner rating and payment receipt"] call TEST_fnc_assert;
[(["p1"] call ALSPMC_fnc_contractProfile) get "level" == 1, "one ordinary success no longer advances a whole rating level"] call TEST_fnc_assert;
[["p1"] call ALS_fnc_moneyGet isEqualTo [0,4000], "reloading a completed contract does not repay"] call TEST_fnc_assert;
call TEST_fnc_reset;
private _bad = [1,[[1,["unknown",1,100,0]]],[]];
["alspmc_contracts_v1",_bad] call ALS_fnc_dbSet;
call ALSPMC_fnc_questInit;
[!ALSPMC_contractsReady && {ALSPMC_ready}, "bad contract metadata does not disable base management"] call TEST_fnc_assert;
["alspmc_contracts_v1",[]] call ALS_fnc_dbSet;
[["alspmc_contracts_v1",[]] call ALS_fnc_dbGet isEqualTo _bad, "native guard preserves corrupt rating metadata"] call TEST_fnc_assert;

ALS_fnc_findPlayer = _findBefore;
ALSPMC_fnc_contractPlan = _planBefore;
ALSPMC_fnc_questSite = _siteBefore;
ALSPMC_fnc_contractSites = _sitesBefore;
deleteVehicle _p2; deleteVehicle TEST_building; deleteVehicle TEST_building2; deleteVehicle TEST_road;
