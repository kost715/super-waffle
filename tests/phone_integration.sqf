// Run the separately supplied native phone dispatcher and state builder.
// Renderer, clock, JSON and world/catalog inputs are fixtures, not Arma CEF.
call TEST_fnc_reset;
TEST_webCalls = [];
TEST_nativeMessages = [];
TEST_jsonPackets = createHashMap;
{
    missionNamespace setVariable ["ALS_fnc_" + _x,
        ("native/functions/fn_" + _x + ".sqf") call TEST_fnc_load];
} forEach ["phoneMsg", "phonePush"];
TEST_originalPhoneMsg = ALS_fnc_phoneMsg;
ALS_fnc_phoneMsg = {TEST_nativeMessages pushBack (_this select 0); _this call TEST_originalPhoneMsg};
ALS_phone = createHashMapFromArray [["ready",false],["web",player],["view","home"]];
ALS_map = createHashMapFromArray [["towns",[]]];
ALS_rentRate = 0.01;
ALS_fnc_notify = {};
ALS_fnc_jobEntry = {TEST_jobNative};
ALS_rivalPublic = [createHashMapFromArray [["id","r1"],["name","Kavala Haulage"],["boss","Test Rival"],["town","Kavala"],
    ["hq",[3100,100,0]],["hostility",[["p1",20]]],["status","active"],["owner",""],["trucks",4],["up",3],["staff",6],
    ["taken",2],["money","steady"],["down",1],["assets","trucks"],["label","Haulage"]]];
ALS_rivalFeed = [["Kavala Haulage","Electronics",1000,"08:00"]];
player setVariable ["ALS_gangRep",[["g1",0]]];

ALS_fnc_marketRoutes = {TEST_market};
TEST_market = createHashMapFromArray [["routes",[createHashMapFromArray [["good","Electronics"],["from","Kavala"],["to","Pyrgos"],["buy",100],["sell",200],["profit",100],["fromKm",0.1],["km",1]]]],
    ["town","Kavala"],["townKm",0.1],["prices",[createHashMapFromArray [["good","Electronics"],["buy",100],["sell",90],["ratio",1]]]]];
player setVariable ["ALS_haul",[4,1,"Courier",0,4,5,1,"Driver",0]];
private _job = createHashMapFromArray [["id",42],["status","open"],["taker",""],["cargo","Electronics"],["crates",1],["size",1],["tier",0],
    ["fromName","Kavala"],["toName","Pyrgos"],["pay",530],["min",10],["km",2],["fromPos",[100,100,0]],["kind","haul"]];
ALS_jobBoard = [_job];
TEST_jobNative = _job;
private _van = "TestVan_F" createVehicle [105,100,0];
_van setVariable ["TEST_class","TestVan_F"];
_van setVariable ["ALS_owner","p1"];
_van setVariable ["ALS_vpub",["veh-1",10,false,20,false]];
TEST_worldVehicles = [_van];
ALS_fnc_vehFetchPrice = {200};
ALS_fnc_vehColors = {[]};
ALS_fnc_vehWet = {false};
player setVariable ["ALS_specPub",[["electronics","Electronics",150,0,0]]];
ALS_fnc_paxKind = {""};
ALS_fnc_weekendMarket = {false};
ALS_fnc_gangRanks = {[]};
ALS_fnc_opt = {1};
ALS_fnc_streetTitle = {"Newcomer"};
BIS_fnc_sortBy = {_this select 0};
BIS_fnc_timeToString = {"08:14"};
ALSPMC_clientStarted = false;
call ALSPMC_fnc_clientInit;
private _installed = ALS_fnc_phoneMsg;
call ALSPMC_fnc_clientInit;
[ALS_fnc_phoneMsg isEqualTo _installed && {ALSPMC_nativePhoneMsg isEqualTo _installed}, "client initialization preserves original phone dispatcher and its delegate"] call TEST_fnc_assert;

private _packet = "{""a"":""ready""}";
TEST_jsonPackets set [_packet,createHashMapFromArray [["a","ready"]]];
[_packet] call ALSPMC_fnc_phoneBridge;
[ALS_phone get "ready", "native phone ready handshake survives PMC installation"] call TEST_fnc_assert;
[count TEST_webCalls == 1, "native ready pushes phone state exactly once"] call TEST_fnc_assert;
diag_log ("TEST_PHONE_STATE: " + ((((TEST_webCalls select 0) select 1) select 1) select [10, ((count (((TEST_webCalls select 0) select 1) select 1)) - 11)]));

// All commands use the native dispatcher, including those whose buttons show
// a busy state while waiting for native phonePush to publish the result.
{
    _x params ["_app", "_msg", "_expected"];
    _packet = _msg call TEST_fnc_toJSON;
    TEST_jsonPackets set [_packet,_msg];
    TEST_messages = [];
    [_packet] call ALSPMC_fnc_phoneBridge;
    [(count TEST_messages) == 1 && {((TEST_messages select 0) select 1) isEqualTo [_expected,2]}, "native command preserved: " + _app] call TEST_fnc_assert;
    [(TEST_nativeMessages select ((count TEST_nativeMessages) - 1)) == _packet, "native dispatcher receives unchanged raw packet: " + _app] call TEST_fnc_assert;
} forEach [
    ["work",createHashMapFromArray [["a","accept"],["id",42]],"ALS_fnc_jobAccept"],
    ["garage",createHashMapFromArray [["a","veh"],["what","insure"],["id","veh-1"]],"ALS_fnc_vehDo"],
    ["legacy",createHashMapFromArray [["a","legacy"]],"ALS_fnc_legacy"],
    ["markets",createHashMapFromArray [["a","spec"],["what","pub"]],"ALS_fnc_specDo"],
    ["rivals-hire",createHashMapFromArray [["a","rivalHire"],["id","r1"],["job","tyres"]],"ALS_fnc_rivalDo"],
    ["markets-buy",createHashMapFromArray [["a","spec"],["what","buy"],["good","electronics"],["n",10]],"ALS_fnc_specDo"]
];
_packet = "rival-mark-packet";
TEST_jsonPackets set [_packet,createHashMapFromArray [["a","rivalMark"],["id","r1"]]];
[_packet] call ALSPMC_fnc_phoneBridge;
[((player getVariable "ALS_sideNav") select 0) isEqualTo [[3100,100,0],"Kavala Haulage","foreman"], "rivals map command reaches unchanged native dispatcher and marks the actual HQ"] call TEST_fnc_assert;

private _nativeBefore = count TEST_nativeMessages;
_packet = "{""a"":""alspmc"",""op"":""status"",""token"":0}";
TEST_jsonPackets set [_packet,createHashMapFromArray [["a","alspmc"],["op","status"],["token",0]]];
TEST_messages = [];
[_packet] call ALSPMC_fnc_phoneBridge;
[count TEST_nativeMessages == _nativeBefore && {((TEST_messages select 0) select 1) isEqualTo ["ALSPMC_fnc_phoneDo",2]}, "only PMC namespace is intercepted; native commands are not duplicated"] call TEST_fnc_assert;

_packet = "{""a"":""view"",""v"":""work""}";
TEST_jsonPackets set [_packet,createHashMapFromArray [["a","view"],["v","work"]]];
[_packet] call ALSPMC_fnc_phoneBridge;
[(ALS_phone get "view") == "work", "native view tracking is preserved for background refresh"] call TEST_fnc_assert;

// A new native push must still reach its own web control after a PMC request.
// Supply the changed native mirrors as server replies; network execution is
// recorded above, not emulated. The unchanged native Push builds both states.
_job set ["status","taken"];
_job set ["taker","p1"];
_job set ["left",600];
_job set ["rcPos",[110,100,0]];
_job set ["fmPos",[100,100,0]];
_job set ["fmName","Test foreman"];
_job set ["rcName","Test recipient"];
_job set ["collected",false];
ALS_myJobs = [42];
_van setVariable ["ALS_vpub",["veh-1",10,true,20,false]];
player setVariable ["ALS_specPub",[["electronics","Electronics",150,10,1000]]];
player setVariable ["ALS_legacyPub",createHashMapFromArray [["paths",[["Business",25,"","Grow your share",false],["The underworld",10,"","Build influence",false],["Liberation",0,"","War is off",false]]],["log",[]],["sectors",[["Homes",5]]]]];
call ALS_fnc_phonePush;
[(count TEST_webCalls) == 2 && {((TEST_webCalls select 1) select 0) == (ALS_phone get "web")}, "native phone state refresh stays on native phone web control"] call TEST_fnc_assert;
diag_log ("TEST_PHONE_STATE: " + ((((TEST_webCalls select 1) select 1) select 1) select [10, ((count (((TEST_webCalls select 1) select 1) select 1)) - 11)]));

// A real mirror captured from questScenario above, with crew/network inputs
// supplied as fixtures. Native Push must also work with our contract active.
player setVariable ["ALS_crew", "c-test"];
player setVariable ["ALS_coopJob", TEST_questMirror];
ALS_crewPublic = [createHashMapFromArray [["id","c-test"],["leader","p1"],["job",TEST_questMirror get "id"],["members",[["p1","Tester"]]]]];
call ALS_fnc_phonePush;
[(count TEST_webCalls) == 3, "native phone publishes state with an active PMC scenario mirror"] call TEST_fnc_assert;
diag_log ("TEST_PHONE_STATE: " + ((((TEST_webCalls select 2) select 1) select 1) select [10, ((count (((TEST_webCalls select 2) select 1) select 1)) - 11)]));
player setVariable ["ALS_coopJob", TEST_contractNativeMirror];
call ALS_fnc_phonePush;
[(count TEST_webCalls) == 4, "native phone publishes a new government protection contract without replacing its state builder"] call TEST_fnc_assert;
diag_log ("TEST_PHONE_STATE: " + ((((TEST_webCalls select 3) select 1) select 1) select [10, ((count (((TEST_webCalls select 3) select 1) select 1)) - 11)]));
