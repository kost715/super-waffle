// 0.7.1 fixes. Real addon and native DB/wallet/coop functions; the same
// VM-only engine/transport fixtures as company_transactions.sqf.
call TEST_fnc_reset;
TEST_fnc_said = {
    params ["_key", "_unit"];
    (TEST_messages findIf {((_x select 1) select 0) == "ALSPMC_fnc_message" && {((_x select 0) select 0) == _key} && {((_x select 1) select 1) isEqualTo _unit}}) >= 0
};
player setPos [100,100,0];
private _p2 = "C_man_1" createVehicle [100,100,0];
_p2 setVariable ["ALS_uid","p2"]; _p2 setVariable ["TEST_player",true]; _p2 setVariable ["TEST_owner",5];
private _p3 = "C_man_1" createVehicle [110,100,0];
_p3 setVariable ["ALS_uid","p3"]; _p3 setVariable ["TEST_player",true]; _p3 setVariable ["TEST_owner",6];
private _hc = "HeadlessClient_F" createVehicle [100,100,0];
_hc setVariable ["TEST_class","HeadlessClient_F"]; _hc setVariable ["ALS_uid","hc"]; _hc setVariable ["TEST_player",true];
TEST_players = [player,_p2,_p3,_hc];
ALS_fnc_findPlayer = {private _id=_this select 0; (TEST_players select {(_x getVariable ["ALS_uid",""])==_id}) param [0,objNull]};
["p1","alspmc_pmc"] call ALS_fnc_licGrant;
["p3","alspmc_pmc"] call ALS_fnc_licGrant;
["money_p3",[0,10]] call ALS_fnc_dbSet;
[[player,"h_100_100"] call ALSPMC_fnc_buyBase,"F0 first PMC buys its base"] call TEST_fnc_assert;
[[_p3,"h_110_100"] call ALSPMC_fnc_buyBase,"F0 second PMC buys its base"] call TEST_fnc_assert;
call ALSPMC_fnc_questInit;
call ALSPMC_fnc_terminalInit;
private _computer = (ALSPMC_terminals get "h_100_100") select 0;
private _computer3 = (ALSPMC_terminals get "h_110_100") select 0;
_p3 setPos [100,100,0];
private _c1 = ["p1"] call ALSPMC_fnc_companyOf; private _id1 = _c1 get "id";
private _c3 = ["p3"] call ALSPMC_fnc_companyOf; private _id3 = _c3 get "id";

// 9: invitations from several PMCs coexist.
[[player,"companyInvite",[_c1 get "revision","p2"],201,_computer] call ALSPMC_fnc_desktopDo,"F9 first PMC invites a player"] call TEST_fnc_assert;
[[_p3,"companyInvite",[_c3 get "revision","p2"],202,_computer3] call ALSPMC_fnc_desktopDo,"F9 second PMC invites the same player"] call TEST_fnc_assert;
private _offers = (([_p2] call ALSPMC_fnc_companyState) get "invites") apply {_x get "id"};
[_id1 in _offers && {_id3 in _offers} && {count _offers == 2},"F9 the second invitation no longer replaces the first"] call TEST_fnc_assert;
[[player,"companyInvite",[_c1 get "revision","p2"],203,_computer] call ALSPMC_fnc_desktopDo,"F9 repeated invitation is accepted"] call TEST_fnc_assert;
[count (ALSPMC_companyInvites get "p2")==2,"F9 repeated invitation only renews its term"] call TEST_fnc_assert;
[[_p2,"companyAccept",[0,_id3],204] call ALSPMC_fnc_phoneDo,"F9 player chooses the second offer"] call TEST_fnc_assert;
[((["p2"] call ALSPMC_fnc_companyOf) get "id")==_id3 && {!("p2" in ALSPMC_companyInvites)},"F9 acceptance withdraws every other pending offer"] call TEST_fnc_assert;
TEST_realTime=TEST_realTime+1;
[[_p2,"companyLeave",[_c3 get "revision",""],205,_computer3] call ALSPMC_fnc_desktopDo,"F9 player leaves again"] call TEST_fnc_assert;

// 11: headless clients are not hireable people.
private _candidates = (([player,true] call ALSPMC_fnc_companyState) get "candidates") apply {_x get "uid"};
[!("hc" in _candidates) && {"p2" in _candidates},"F11 headless client is not listed as a candidate"] call TEST_fnc_assert;
[!([player,"companyInvite",[_c1 get "revision","hc"],206,_computer] call ALSPMC_fnc_desktopDo),"F11 headless client cannot be invited"] call TEST_fnc_assert;

// 7: only money and membership write the world to disk, at most twice a second.
["money_p1",[0,1000]] call ALS_fnc_dbSet;
private _saves = TEST_profilesSaved;
TEST_realTime=TEST_realTime+1;
[[player,"companyInvite",[_c1 get "revision","p2"],207,_computer] call ALSPMC_fnc_desktopDo && {TEST_profilesSaved==_saves},"F7 invitation rides on the periodic save"] call TEST_fnc_assert;
[[player,"companyDeposit",[_c1 get "revision",100],208,_computer] call ALSPMC_fnc_desktopDo && {TEST_profilesSaved==_saves+1},"F7 deposit is written to disk at once"] call TEST_fnc_assert;
[!([player,"companyDeposit",[_c1 get "revision",100],209,_computer] call ALSPMC_fnc_desktopDo) && {_c1 get "balance"==100},"F7 second disk-writing request within half a second is refused"] call TEST_fnc_assert;
TEST_realTime=TEST_realTime+1;
[[player,"companyDeposit",[_c1 get "revision",100],210,_computer] call ALSPMC_fnc_desktopDo && {_c1 get "balance"==200},"F7 the same request succeeds a second later"] call TEST_fnc_assert;

// 10: names instead of UIDs, also for members who are offline.
[[_p2,"companyAccept",[0,_id1],211] call ALSPMC_fnc_phoneDo,"F10 player joins the first PMC"] call TEST_fnc_assert;
call ALSPMC_fnc_companyTick;
TEST_players = TEST_players - [_p2];
private _state = [player,true] call ALSPMC_fnc_companyState;
private _row = ((_state get "members") select {(_x get "uid")=="p2"}) select 0;
[(_row get "name") isEqualTo (toArray "Test p2") && {!(_row get "online")},"F10 offline member keeps the last seen name"] call TEST_fnc_assert;
[((_state get "names") get "p1") isEqualTo (toArray "Test p1") && {((_state get "names") get "p2") isEqualTo (toArray "Test p2")},"F10 ledger actors resolve to names"] call TEST_fnc_assert;
call ALSPMC_fnc_companySave; call ALSPMC_fnc_companyInit;
_c1 = ["p1"] call ALSPMC_fnc_companyOf; _c3 = ["p3"] call ALSPMC_fnc_companyOf;
[([ "p2"] call ALSPMC_fnc_playerName) isEqualTo (toArray "Test p2"),"F10 names survive a restart"] call TEST_fnc_assert;
TEST_players pushBack _p2;

// 12: the active-time counter alone is saved once a minute.
call ALSPMC_fnc_companyTick;
private _stored = +(["alspmc_companies_v1",[]] call ALS_fnc_dbGet);
ALS_dbDirty = false;
TEST_realTime=TEST_realTime+2;
call ALSPMC_fnc_companyTick;
[!ALS_dbDirty && {(["alspmc_companies_v1",[]] call ALS_fnc_dbGet) isEqualTo _stored},"F12 a two-second tick does not mark LifeSim's DB as changed"] call TEST_fnc_assert;
TEST_realTime=TEST_realTime+60;
call ALSPMC_fnc_companyTick;
[ALS_dbDirty && {!((["alspmc_companies_v1",[]] call ALS_fnc_dbGet) isEqualTo _stored)},"F12 active time is written after a minute"] call TEST_fnc_assert;

// 8: a client cannot remote-execute server-only company functions directly.
call {
    TEST_isRemoteExecuted = true; TEST_remoteOwner = 6;
    private _fnc_scriptName = "ALSPMC_fnc_companyEnsure";
    private _fnc_scriptNameParent = "ALSPMC_fnc_companyEnsure";
    [count (["intruder"] call ALSPMC_fnc_companyEnsure)==0 && {!("pmc_intruder" in ALSPMC_companies)},"F8 direct remote call cannot create a company"] call TEST_fnc_assert;
    _fnc_scriptNameParent = "ALSPMC_fnc_buyBase";
    [count (["intruder"] call ALSPMC_fnc_companyEnsure)>0,"F8 the function still works inside a request's call chain"] call TEST_fnc_assert;
    TEST_isRemoteExecuted = false;
};
ALSPMC_companies deleteAt "pmc_intruder"; call ALSPMC_fnc_companySave;

// 13: refusals are explained to the player.
TEST_messages = [];
[!([_p2,toArray "Rubezh"] call ALSPMC_fnc_setName) && {["STR_ALSPMC_owner_only",_p2] call TEST_fnc_said},"F13 employee rename is refused with a message"] call TEST_fnc_assert;
ALSPMC_companiesReady = false;
[!([player,"h_115_100"] call ALSPMC_fnc_buyBase) && {["STR_ALSPMC_company_unavailable",player] call TEST_fnc_said},"F13 unavailable company data is explained"] call TEST_fnc_assert;
ALSPMC_companiesReady = true;

// 4: LifeSim's own government buildings stay usable for government guard.
ALS_houses set ["h_5100_100",[[5100,100,0],"a3\structures_f\households\hospital_01_f.p3d",400,6,"Town",90000,"Shop","Good"]];
ALS_houses set ["h_5200_100",[[5200,100,0],"a3\structures_f\households\cafe_01_f.p3d",120,2,"Town",30000,"Shop","Good"]];
private _hospital = "TestBuilding_F" createVehicle [5100,100,0];
private _cafe = "TestBuilding_F" createVehicle [5200,100,0];
ALS_reserved append ["h_5100_100","h_5200_100"];
[["government",[[5100,100,0],"",_hospital]] call ALSPMC_fnc_contractSiteAvailable,"F4 LifeSim's reserved hospital is a government facility"] call TEST_fnc_assert;
[!(["government",[[5200,100,0],"",_cafe]] call ALSPMC_fnc_contractSiteAvailable),"F4 a reserved commercial venue stays excluded"] call TEST_fnc_assert;
[!(["commercial",[[5100,100,0],"h_5100_100",objNull]] call ALSPMC_fnc_contractSiteAvailable),"F4 private contracts never use a reserved hospital"] call TEST_fnc_assert;
ALS_npcPublic = [[[5200,100,0],"clerk","Clerk","Town hall",[]]];
[["government",[[5200,100,0],"",_cafe]] call ALSPMC_fnc_contractSiteAvailable,"F4 the building LifeSim made a town hall is a government facility"] call TEST_fnc_assert;
ALS_npcPublic = [[[5150,100,0],"clerk","Clerk","Town hall",[]]];
private _nearest = TEST_fnc_nearestObjects;
TEST_fnc_nearestObjects = {if ("House" in (_this select 1)) then {[_cafe,_hospital]} else {[]}};
ALSPMC_contractSitesCache = createHashMap;
private _government = ["government"] call ALSPMC_fnc_contractSites;
[(_government findIf {(_x select 2) isEqualTo _hospital})>=0 && {(_government findIf {(_x select 2) isEqualTo _cafe})<0},"F4 an excluded nearest building no longer hides the next one"] call TEST_fnc_assert;
ALS_owned set ["h_5100_100","p3"];
[!(["government",[[5100,100,0],"",_hospital]] call ALSPMC_fnc_contractSiteAvailable),"F4 a hospital a player owns is never used"] call TEST_fnc_assert;
ALS_owned deleteAt "h_5100_100";
TEST_fnc_nearestObjects = _nearest;
ALSPMC_contractSitesCache = createHashMap;
ALS_reserved = [];

// 3: owner/manager cancels from the base PC without being in the crew; 20-minute rendezvous.
ALS_war set ["bases",[["army",[3100,100,0],"outpost",8,"Army"],["army2",[6100,100,0],"outpost",8,"Army 2"]]];
ALS_war set ["own",createHashMapFromArray [["army","Military"],["army2","Military"]]];
ALSPMC_contractBoards = createHashMap;
private _planner = ALSPMC_fnc_contractPlan;
ALSPMC_fnc_contractPlan = {createHashMapFromArray [["base",[100,100,0]],["site",[3100,100,0]],["source","army"],["owner","Military"],["building",objNull],["indoor",[]],["truckPos",[3100,100,0]],["truckDir",90],["destination",[6100,100,0]]]};
TEST_realTime=TEST_realTime+1;
[[player,"companyPromote",[_c1 get "revision","p2"],212,_computer] call ALSPMC_fnc_desktopDo,"F3 owner appoints a manager"] call TEST_fnc_assert;
private _board = [_p2] call ALSPMC_fnc_contractOffers;
(_board get "offers") set [0,["f3_convoy","gov_convoy"]];
[[_p2,"questStart","f3_convoy",213] call ALSPMC_fnc_phoneDo,"F3 manager accepts an operation"] call TEST_fnc_assert;
private _job = ALS_coopJobs get ((["p2"] call ALS_fnc_crewOf) get "job");
private _qid = _job get "alspmcQuestId"; private _ref = "q" + str _qid;
[(_job get "state")=="rendezvous" && {(ALSPMC_questCompanies get _qid)==_id1},"F3 operation is linked to the company"] call TEST_fnc_assert;
private _view = ([player] call ALSPMC_fnc_questState) get "active";
[(_view get "id")==_ref && {_view get "canCancelRemote"} && {(_view get "crew") isEqualTo [toArray "Test p2"]},"F3 owner outside the crew sees it, its crew and the remote cancel"] call TEST_fnc_assert;
[(_view get "rendezvousLeft")==1200,"F3 rendezvous countdown is reported"] call TEST_fnc_assert;
[!([player,"questCancel",_ref,214] call ALSPMC_fnc_phoneDo),"F3 crew cancel still requires the crew"] call TEST_fnc_assert;
[!([player,"questCancelRemote",_ref,215] call ALSPMC_fnc_phoneDo),"F3 the phone has no route to remote cancel"] call TEST_fnc_assert;
[!([_p3,"questCancelRemote",_ref,216,_computer3] call ALSPMC_fnc_desktopDo),"F3 another PMC cannot cancel at its own PC"] call TEST_fnc_assert;
[!([player,"questCancelRemote",_ref,217,_computer3] call ALSPMC_fnc_desktopDo),"F3 a foreign base PC cannot be used"] call TEST_fnc_assert;
[!([player,"questCancelRemote",_ref,218] call ALSPMC_fnc_questDo),"F3 remote cancel without a terminal is refused"] call TEST_fnc_assert;
[[player,"questCancelRemote",_ref,219,_computer] call ALSPMC_fnc_desktopDo,"F3 owner cancels at the base PC"] call TEST_fnc_assert;
[!(_qid in ALS_coopJobs) && {((ALSPMC_questRecords get _qid) select 1)=="cancelled"},"F3 operation ends as cancelled"] call TEST_fnc_assert;
private _entry = (_c1 get "ledger") select 0;
[(_entry select 1)=="p1" && {(_entry select 3)=="contractCancel"} && {(_entry select 4)==_ref},"F3 cancellation is recorded in the company ledger"] call TEST_fnc_assert;
private _history = (([player] call ALSPMC_fnc_questState) get "history") apply {_x get "id"};
[_ref in _history,"F10 owner sees the manager's operation in history"] call TEST_fnc_assert;
_board = [_p2] call ALSPMC_fnc_contractOffers;
(_board get "offers") set [0,["f3_convoy2","gov_convoy"]];
[[_p2,"questStart","f3_convoy2",220] call ALSPMC_fnc_phoneDo,"F3 manager accepts another operation"] call TEST_fnc_assert;
_job = ALS_coopJobs get ((["p2"] call ALS_fnc_crewOf) get "job");
_qid = _job get "alspmcQuestId";
TEST_realTime=TEST_realTime+600;
[([_job,[_p2]] call ALSPMC_fnc_contractTick) isEqualTo ["on"],"F3 rendezvous waits within its time"] call TEST_fnc_assert;
TEST_realTime=TEST_realTime+601;
[([_job,[_p2]] call ALSPMC_fnc_contractTick) isEqualTo ["failed",0] && {(_job get "alspmcResult")=="timeout"},"F3 unconfirmed rendezvous times out after 20 minutes"] call TEST_fnc_assert;
// 14: the owner is offline; a member online stands in for the board.
TEST_players = TEST_players - [player];
// Within the board's own term (the 20-minute wait above outlived the original one).
(ALSPMC_contractBoards get "p1") set ["expires", TEST_realTime + 300];
private _expires = (ALSPMC_contractBoards get "p1") get "expires";
[[_job,0] call ALS_fnc_coopEnd,"F3 timed-out operation settles"] call TEST_fnc_assert;
[((ALSPMC_questRecords get _qid) select 7)=="timeout" && {"p1" in ALSPMC_contractBoards} && {((ALSPMC_contractBoards get "p1") get "expires")==_expires},"F14 owner's board is kept, not rerolled, while the owner is offline"] call TEST_fnc_assert;
TEST_players pushBack player;
ALSPMC_boardSettlements = createHashMapFromArray [["p1",[["gov_mines",false,""]]]];
// Free one slot, as a settled operation would.
((ALSPMC_contractBoards get "p1") get "offers") deleteAt 0;
_board = [_p2] call ALSPMC_fnc_contractOffers;
[!("p1" in ALSPMC_boardSettlements) && {(((_board get "offers") apply {_x select 1}) find "gov_mines")>=0},"F14 a queued settlement is applied at the next board view"] call TEST_fnc_assert;
ALSPMC_fnc_contractPlan = _planner;

// 6: a new career clears PMC standing.
ALSPMC_nativeCareerRestart = {TEST_careerCalls pushBack _this; true};
TEST_careerCalls = [];
TEST_messages = [];
[[_p2] call ALSPMC_fnc_careerRestart,"F6 member's new career runs the original"] call TEST_fnc_assert;
[!("p2" in (_c1 get "members")) && {_id1 in ALSPMC_companies} && {((_c1 get "ledger") select 0) select 3=="careerRestart"},"F6 member leaves, the company stays"] call TEST_fnc_assert;
[(TEST_careerCalls select 0) isEqualTo [_p2] && {["STR_ALSPMC_company_left_restart",_p2] call TEST_fnc_said},"F6 original receives unchanged arguments; member is told"] call TEST_fnc_assert;
TEST_realTime=TEST_realTime+1;
[[_p3,"companyInvite",[_c3 get "revision","p2"],221,_computer3] call ALSPMC_fnc_desktopDo,"F6 another PMC invites the player"] call TEST_fnc_assert;
[[_p2,"companyAccept",[0,_id3],222] call ALSPMC_fnc_phoneDo,"F6 player joins it"] call TEST_fnc_assert;
TEST_realTime=TEST_realTime+1;
["money_p3",[0,500]] call ALS_fnc_dbSet;
[[_p3,"companyDeposit",[_c3 get "revision",400],223,_computer3] call ALSPMC_fnc_desktopDo,"F6 owner funds the treasury"] call TEST_fnc_assert;
ALSPMC_ratingXP set ["p3",250]; ALSPMC_names set ["p3",toArray "Rubezh"];
ALSPMC_companyInvites set ["p1",createHashMapFromArray [[_id3,TEST_realTime+600]]];
ALSPMC_contractBoards = createHashMap;
ALSPMC_fnc_contractPlan = {createHashMapFromArray [["base",[100,100,0]],["site",[3100,100,0]],["source","army"],["owner","Military"],["building",objNull],["indoor",[]],["truckPos",[3100,100,0]],["truckDir",90],["destination",[6100,100,0]]]};
_board = [_p3] call ALSPMC_fnc_contractOffers;
(_board get "offers") set [0,["f6_convoy","gov_convoy"]];
[[_p3,"questStart","f6_convoy",224] call ALSPMC_fnc_phoneDo,"F6 owner runs an operation"] call TEST_fnc_assert;
_qid = ((ALS_coopJobs get ((["p3"] call ALS_fnc_crewOf) get "job")) get "alspmcQuestId");
ALSPMC_fnc_contractPlan = _planner;
TEST_isRemoteExecuted = true; TEST_remoteOwner = 99;
TEST_careerCalls = [];
[_p3] call ALSPMC_fnc_careerRestart;
[_id3 in ALSPMC_companies && {count TEST_careerCalls==1},"F6 a refused request clears nothing and is left to the original"] call TEST_fnc_assert;
TEST_isRemoteExecuted = false;
TEST_messages = [];
[[_p3] call ALSPMC_fnc_careerRestart,"F6 owner's new career runs the original"] call TEST_fnc_assert;
[!(_id3 in ALSPMC_companies) && {count (["p2"] call ALSPMC_fnc_companyOf)==0},"F6 owner's company and treasury are closed; employees are free"] call TEST_fnc_assert;
[((ALSPMC_questRecords get _qid) select 1)=="cancelled" && {count ALS_coopJobs==0},"F6 the company's running operation ends unpaid"] call TEST_fnc_assert;
[!("p3" in ALSPMC_ratingXP) && {!("p3" in ALSPMC_names)} && {!(_id3 in (ALSPMC_companyInvites getOrDefault ["p1",createHashMap]))},"F6 rating, name and pending invitations are removed"] call TEST_fnc_assert;
[["STR_ALSPMC_company_closed_owner",_p3] call TEST_fnc_said && {["STR_ALSPMC_company_closed_member",_p2] call TEST_fnc_said},"F6 owner and employees are told"] call TEST_fnc_assert;
private _saved = (["alspmc_companies_v1",[]] call ALS_fnc_dbGet) select 1;
[(_saved findIf {(_x select 0)==_id3})<0,"F6 the closed company is gone from the save"] call TEST_fnc_assert;

// 1: LifeSim NPCs near contract enemies surrender as hostages; fast reopening.
private _npc = "C_man_1" createVehicle [7000,100,0]; _npc setVariable ["ALS_npc",7];
private _held = "C_man_1" createVehicle [7000,120,0]; _held setVariable ["ALS_npc",8]; _held setCaptive true;
private _enemy = "O_G_Soldier_F" createVehicle [7100,100,0];
private _hostageJob = createHashMapFromArray [["alspmcQuestId",77],["alspmcEnemies",[[_enemy,false]]]];
ALS_coopJobs set [77,_hostageJob];
TEST_nearEntities = [_npc,_held,player];
player setPos [7050,100,0];
["tick",_hostageJob] call ALSPMC_fnc_contractCivilians;
[captive _npc && {_npc getVariable ["ALSPMC_hostage",false]},"F1 nearby LifeSim NPC surrenders as a hostage"] call TEST_fnc_assert;
[!(_held getVariable ["ALSPMC_hostage",false]) && {!captive player},"F1 units LifeSim already holds, and players, are left alone"] call TEST_fnc_assert;
["tick",_hostageJob] call ALSPMC_fnc_contractCivilians;
[captive _npc,"F1 the hostage stays held while enemies are near"] call TEST_fnc_assert;
deleteVehicle _enemy;
["tick",_hostageJob] call ALSPMC_fnc_contractCivilians;
[!captive _npc && {!(_npc getVariable ["ALSPMC_hostage",false])} && {captive _held},"F1 hostage is released once no enemy is near; others untouched"] call TEST_fnc_assert;
ALS_npcSpots = createHashMapFromArray [[7,createHashMapFromArray [["id",7],["deadAt",time]]],[8,createHashMapFromArray [["id",8],["deadAt",time]]]];
private _killer = "O_G_Soldier_F" createVehicle [7100,100,0]; _killer setVariable ["ALSPMC_contractEnemy",77];
[_npc,_killer,_killer] call ALSPMC_fnc_questKilled;
[_held,player,player] call ALSPMC_fnc_questKilled;
[count ALSPMC_npcCasualties==1,"F1 only a death caused by contract enemies is recorded"] call TEST_fnc_assert;
private _playerDeath = (ALS_npcSpots get 8) get "deadAt";
["release",_hostageJob] call ALSPMC_fnc_contractCivilians;
[((ALS_npcSpots get 7) get "deadAt") <= ((time - 1650) max 0) && {ALSPMC_npcCasualties isEqualTo []},"F1 NPC killed by contract enemies reopens about 2.5 minutes after the operation"] call TEST_fnc_assert;
[((ALS_npcSpots get 8) get "deadAt")==_playerDeath,"F1 a player's killing keeps LifeSim's normal 30 minutes"] call TEST_fnc_assert;
ALS_coopJobs deleteAt 77;
player setPos [100,100,0];

// 2: LifeSim war defenders on EAST are moved to RESISTANCE during contracts.
resistance setFriend [west, 0];
BIS_fnc_taskDefend = {TEST_defendCalls pushBack _this}; TEST_defendCalls = [];
ALS_war set ["bases",[["depot1",[8000,100,0],"depot",8,"Depot"]]];
private _defenders = createGroup [east,true];
private _defender = _defenders createUnit ["O_G_Soldier_F",[8000,100,0],[],0,"NONE"]; _defender setVariable ["ALS_defender","depot1"];
private _ours = createGroup [east,true];
private _militia = _ours createUnit ["O_G_Soldier_F",[9000,100,0],[],0,"NONE"];
private _leaseJob = createHashMapFromArray [["alspmcQuestId",78],["alspmcRoster",[]]];
["acquire",_leaseJob] call ALSPMC_fnc_contractHostility;
[side group _defender == resistance && {side group _militia == east},"F2 war defender moved to RESISTANCE; contract enemies stay EAST"] call TEST_fnc_assert;
[count TEST_defendCalls==1 && {((TEST_defendCalls select 0) select 1) isEqualTo [8000,100,0]},"F2 moved defenders keep defending their base"] call TEST_fnc_assert;
["release",_leaseJob] call ALSPMC_fnc_contractHostility;
diag_log ("TEST_FIXES_071_COMPANY_STATE: " + (([player,true] call ALSPMC_fnc_companyState) call TEST_fnc_toJSON));
