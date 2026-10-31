// PMC Interactions checks in SQF-VM: the four game models, the ACE hooks (time and
// success callbacks, with ACE replaced by recording stand-ins), the board's input,
// watchdog and results, and which pictures the board shows. The window itself (layout,
// controls) is not exercised.
call compile preprocessFileLineNumbers "tests/vm_compat.sqf";
TEST_count = 0;
TEST_fnc_assert = {
    params ["_ok", "_label"];
    if (!_ok) then {diag_log ("TEST_FAIL: " + _label); exitcode__ 1};
    TEST_count = TEST_count + 1;
    diag_log ("TEST_PASS: " + _label);
};
{
    missionNamespace setVariable ["PMCI_fnc_" + (_x select 1), (format ["pmc_interactions/%1/fn_%2.sqf", _x select 0, _x select 1]) call TEST_fnc_load];
} forEach [["Init", "settings"], ["Hooks", "table"], ["Hooks", "hookOf"], ["Hooks", "original"], ["Hooks", "plays"], ["Hooks", "treatmentTime"],
    ["Hooks", "timeNormal"], ["Hooks", "timeTrained"], ["Hooks", "treatmentSuccess"], ["Hooks", "repairTime"], ["Hooks", "repairSuccess"],
    ["Games", "cprModel"], ["Games", "tourniquetModel"], ["Games", "bandageModel"], ["Games", "wheelModel"],
    ["Games", "pressureModel"], ["Games", "edgesModel"], ["Games", "cleanModel"], ["Hooks", "woundOf"], ["Hooks", "woundGame"],
    ["Board", "boardOpen"], ["Board", "boardEvent"], ["Board", "boardTick"], ["Board", "boardValid"], ["Board", "finish"], ["Board", "boardLook"],
    ["Board", "boardMarks"], ["Board", "cprRibs"], ["Init", "events"],
    ["Games", "ivModel"], ["Games", "sutureModel"], ["Games", "splintModel"], ["Games", "diagnoseModel"], ["Games", "weldModel"], ["Games", "trackModel"],
    ["Hooks", "repairGame"], ["Hooks", "partOf"], ["Hooks", "stitch"], ["Hooks", "stitchProgress"],
    ["Board", "keysOf"], ["Board", "keyIs"], ["Board", "keyName"],
    ["Games", "lockpickModel"], ["Games", "terminalModel"], ["Games", "safeModel"], ["Lock", "lockSet"], ["Lock", "lockClear"], ["Lock", "lockApply"],
    ["Lock", "lockActions"], ["Lock", "lockOpen"], ["Lock", "lockHack"], ["Lock", "lockNotify"], ["Lock", "lockKeys"], ["Lock", "lockTool"],
    ["Lock", "codeValid"], ["Lock", "itemCount"], ["Lock", "itemName"], ["Lock", "itemTake"], ["Lock", "terminalDump"],
    ["Games", "weldSeams"], ["Hooks", "stitchCount"], ["Lock", "lockPins"]];
TEST_mouse = [0, 0];
PMCI_fnc_boardMouse = {+TEST_mouse};
PMCI_fnc_boardDraw = {};
PMCI_fnc_boardLayout = {};

// ACE stand-ins: record every call.
TEST_calls = [];
{
    missionNamespace setVariable [_x, compile format ["TEST_calls pushBack ['%1', +_this]; 0", _x]];
} forEach ["ace_medical_treatment_fnc_bandage", "ace_medical_treatment_fnc_tourniquet", "ace_medical_treatment_fnc_cprSuccess",
    "ace_medical_treatment_fnc_cprFailure", "ace_repair_fnc_doReplaceWheel", "ace_repair_fnc_doRemoveWheel", "ace_common_fnc_claim",
    "ace_common_fnc_addToInventory", "ace_common_fnc_adjustMagazineAmmo", "CBA_fnc_removePerFrameHandler", "CBA_fnc_targetEvent",
    "ace_medical_fnc_addDamageToUnit", "ace_medical_treatment_fnc_ivBag", "ace_medical_treatment_fnc_splint", "ace_medical_treatment_fnc_surgicalKitProgress",
    "ace_repair_fnc_doRepair", "ace_repair_fnc_doRepairTrack", "ace_repair_fnc_doReplaceTrack", "ace_repair_fnc_doRemoveTrack",
    "ace_medical_gui_fnc_openMenu", "CBA_fnc_execNextFrame", "CBA_fnc_addKeybind"];
ace_medical_treatment_treatmentTimeIV = 12;
ace_medical_treatment_treatmentTimeTrainedIV = 8;
ace_medical_treatment_treatmentTimeSplint = 7;
ace_medical_treatment_treatmentTimeTrainedSplint = 5;
ace_medical_treatment_fnc_getStitchTime = {10};
ace_repair_miscRepairTime = 15;
TEST_stitchable = 0;
// As ACE: removes the given bandaged wound entry, or the last one, from the patient's list.
ace_medical_treatment_fnc_stitchWound = {
    params ["_patient", "_part", ["_wound", []]];
    TEST_calls pushBack ["stitchWound", +_this];
    if (TEST_stitchable <= 0) exitWith {false};
    private _list = [_patient getVariable ["ace_medical_bandagedWounds", createHashMap], [_part, []]] call TEST_fnc_getDefault;
    private _at = if (_wound isEqualTo []) then {count _list - 1} else {_list find _wound};
    if (_at < 0) exitWith {false};
    _list deleteAt _at;
    TEST_stitchable = TEST_stitchable - 1;
    true
};
TEST_sutureUser = objNull;
ace_medical_treatment_fnc_useItem = {TEST_calls pushBack ["useItem", +_this]; [TEST_sutureUser, "ACE_suture"]};
ace_medical_treatment_fnc_getBandageTime = {TEST_calls pushBack ["getBandageTime", +_this]; 7.5};
ace_medical_treatment_treatmentTimeTourniquet = 7;
ace_medical_treatment_treatmentTimeTrainedTourniquet = 4;
ace_medical_treatment_treatmentTimeCPR = 15;
ace_repair_wheelChangeTime = 10;
TEST_trained = false;
ace_medical_treatment_fnc_isMedic = {TEST_trained};
ace_repair_fnc_isEngineer = {TEST_trained};
CBA_fnc_addPerFrameHandler = {77};
TEST_settings = [];
CBA_fnc_addSetting = {
    params ["_name", "_type", "_title", "_category", "_value", ["_global", 0]];
    TEST_settings pushBack [_name, _type, _global];
    missionNamespace setVariable [_name, switch (_type) do {case "SLIDER": {_value select 2}; case "LIST": {(_value select 0) select (_value select 2)}; default {_value}}];
};
TEST_called = {params ["_name"]; TEST_calls select {(_x select 0) == _name}};
TEST_medic = player;
TEST_medic setVariable ["TEST_class", "B_Soldier_F"];
TEST_fnc_unit = {
    params ["_pos"];
    private _u = "B_Soldier_F" createVehicle _pos;
    _u setPos _pos;
    _u setVariable ["TEST_class", "B_Soldier_F"];
    _u
};
TEST_patient = [[1, 0, 0]] call TEST_fnc_unit;
TEST_ai = [[0, 1, 0]] call TEST_fnc_unit;
TEST_fnc_fresh = {
    PMCI_board = nil;
    TEST_calls = [];
    TEST_dialogs = [];
    TEST_zeusOpen = false;
    TEST_trained = false;
    TEST_hasInterface = true;
    TEST_settings = [];
    call PMCI_fnc_settings;
    player setPos [0, 0, 0];
};
call TEST_fnc_fresh;

// --- Settings -----------------------------------------------------------------------
private _names = TEST_settings apply {_x select 0};
[count TEST_settings == 86 && {"PMCI_enable_wheel" in _names} && {"PMCI_lockKey5" in _names} && {"PMCI_safeItem" in _names} && {"PMCI_terminalAttempts" in _names} && {"PMCI_trackHits" in _names} && {"PMCI_weldHeat" in _names} && {"PMCI_enable_edges" in _names} && {"PMCI_ribChance" in _names}
    && {"PMCI_enable_track" in _names} && {"PMCI_ivLimit" in _names} && {!("PMCI_enable_diagnose" in _names)} && {"PMCI_sutureMax" in _names}
    && {"PMCI_lockpickTwo" in _names} && {"PMCI_lockpickSpeed" in _names} && {"PMCI_safeNoise" in _names}
    && {(TEST_settings findIf {(_x select 2) != 1}) < 0},
    "settings: difficulty, preparation bar, each game on/off plus its tuning, the locks' keys, tools and tuning, forced by the server"] call TEST_fnc_assert;
[PMCI_difficulty == 1 && {PMCI_prepTime == 1} && {PMCI_cprDuration == 15} && {PMCI_enable_bandage}, "defaults: normal, 1 s preparation, 15 s CPR, all games on"] call TEST_fnc_assert;

// --- CPR rhythm ---------------------------------------------------------------------
TEST_fnc_cpr = {
    params ["_interval"];
    private _state = ["init", nil, [10, 0.05, 0.5]] call PMCI_fnc_cprModel;
    private _next = 0;
    while {(_state get "status") == "running"} do {
        if ((_state get "t") >= _next) then {["press", _state] call PMCI_fnc_cprModel; _next = _next + _interval};
        ["tick", _state, 0.005] call PMCI_fnc_cprModel;
    };
    _state
};
private _good = [0.545] call TEST_fnc_cpr;
[(_good get "status") == "success" && {(_good get "quality") > 0.9}, "CPR at 110 per minute succeeds with high quality"] call TEST_fnc_assert;
[(([1] call TEST_fnc_cpr) get "status") == "fail" && {(([0.3] call TEST_fnc_cpr) get "status") == "fail"}, "too slow (60/min) or too fast (200/min) fails"] call TEST_fnc_assert;
private _edge = [0.64] call TEST_fnc_cpr;
[(_edge get "good") > 0, "the tolerance accepts a slightly slow pace (94/min)"] call TEST_fnc_assert;

// --- Tourniquet -----------------------------------------------------------------------
TEST_fnc_turn = {
    params ["_state", "_seconds"];
    ["press", _state] call PMCI_fnc_tourniquetModel;
    for "_i" from 1 to round (_seconds / 0.01) do {["tick", _state, 0.01] call PMCI_fnc_tourniquetModel};
    ["release", _state] call PMCI_fnc_tourniquetModel;
};
private _t = ["init", nil, [0.62, 0.8, 0.32, 25, 1]] call PMCI_fnc_tourniquetModel;
[_t, 2.2] call TEST_fnc_turn;
["fix", _t] call PMCI_fnc_tourniquetModel;
[(_t get "status") == "success", "stopping in the band and fixing applies the tourniquet"] call TEST_fnc_assert;
_t = ["init", nil, [0.62, 0.8, 0.32, 25, 1]] call PMCI_fnc_tourniquetModel;
[_t, 3.3] call TEST_fnc_turn;
[(_t get "slips") == 1 && {(_t get "p") < 0.1} && {(_t get "status") == "running"}, "past full pressure it slips back to zero"] call TEST_fnc_assert;
["fix", _t] call PMCI_fnc_tourniquetModel;
[(_t get "status") == "fail", "one slip too many fails"] call TEST_fnc_assert;
_t = ["init", nil, [0.62, 0.8, 0.32, 3, 1]] call PMCI_fnc_tourniquetModel;
for "_i" from 1 to 31 do {["tick", _t, 0.1] call PMCI_fnc_tourniquetModel};
[(_t get "status") == "fail", "the time limit fails"] call TEST_fnc_assert;

// --- Bandage ----------------------------------------------------------------------------
TEST_fnc_pack = {
    params ["_steer"];
    private _state = ["init", nil, [0.22, 30, 6, 0]] call PMCI_fnc_bandageModel;
    while {(_state get "status") == "running"} do {
        if (_steer && {(_state get "needle") < (_state get "center")}) then {["press", _state] call PMCI_fnc_bandageModel} else {["release", _state] call PMCI_fnc_bandageModel};
        ["tick", _state, 0.05] call PMCI_fnc_bandageModel;
    };
    _state
};
private _packed = [true] call TEST_fnc_pack;
[(_packed get "status") == "success" && {(_packed get "quality") > 0.6} && {(_packed get "t") < 12}, "keeping the needle in the zone packs the wound"] call TEST_fnc_assert;
private _idle = [false] call TEST_fnc_pack;
[(_idle get "status") == "fail" && {(_idle get "progress") == 0}, "doing nothing runs out of time"] call TEST_fnc_assert;

// --- Wheel --------------------------------------------------------------------------------
private _w = ["init", nil, [0.8, 3]] call PMCI_fnc_wheelModel;
private _wait = {params ["_state", "_s"]; for "_i" from 1 to round (_s / 0.1) do {["tick", _state, 0.1] call PMCI_fnc_wheelModel}};
["swap", _w] call PMCI_fnc_wheelModel;
[(_w get "phase") == "loosen", "the wheel cannot be swapped before the nuts are loose"] call TEST_fnc_assert;
{["nut", _w, _x] call PMCI_fnc_wheelModel; [_w, 0.9] call _wait} forEach [1, 3, 0, 2, 4];
[(_w get "phase") == "swap" && {(_w get "mistakes") == 0}, "a star from any nut (2-4-1-3-5) loosens the wheel"] call TEST_fnc_assert;
["swap", _w] call PMCI_fnc_wheelModel;
[_w, 3.1] call _wait;
["nut", _w, 2] call PMCI_fnc_wheelModel;
["nut", _w, 4] call PMCI_fnc_wheelModel;
[(_w get "step") == 1, "a nut clicked while busy is ignored"] call TEST_fnc_assert;
[_w, 0.9] call _wait;
["nut", _w, 3] call PMCI_fnc_wheelModel;
[(_w get "mistakes") == 1 && {(_w get "step") == 1}, "a nut out of the star is a mistake"] call TEST_fnc_assert;
[_w, 0.9] call _wait;
{["nut", _w, _x] call PMCI_fnc_wheelModel; [_w, 0.9] call _wait} forEach [4, 1, 3, 0];
[(_w get "status") == "success", "tightening in a star finishes the wheel"] call TEST_fnc_assert;

// --- Hooks: which ACE action plays, ACE's own time and result otherwise -----------------
[(["KAT_Bandage", configFile >> "ace_medical_treatment_actions"] call PMCI_fnc_hookOf) select 0 == "FieldDressing" && {
    (["Morphine", configFile >> "ace_medical_treatment_actions"] call PMCI_fnc_hookOf) select 0 == "FieldDressing"} && {
    (["BasicBandage", configFile >> "ace_medical_treatment_actions"] call PMCI_fnc_hookOf) isEqualTo []},
    "another mod's bandage inherits the hook; untouched classes have none"] call TEST_fnc_assert;
[getText (configFile >> "ace_medical_treatment_actions" >> "FieldDressing" >> "callbackSuccess") == "PMCI_fnc_treatmentSuccess" && {
    getText (configFile >> "ace_medical_treatment_actions" >> "ApplyTourniquet" >> "treatmentTimeTrained") == "PMCI_fnc_timeTrained"} && {
    getText (configFile >> "ACE_Repair" >> "Actions" >> "ReplaceWheel" >> "repairingTime") == "PMCI_fnc_repairTime"} && {
    getText (configFile >> "ace_medical_treatment_actions" >> "Morphine" >> "callbackSuccess") == "ace_medical_treatment_fnc_medication"},
    "the addon config takes over exactly the chosen ACE actions"] call TEST_fnc_assert;
private _treat = [TEST_medic, TEST_patient, "LeftArm", "FieldDressing"];
[(_treat call PMCI_fnc_timeNormal) == 1, "a player's bandage gets the short preparation bar"] call TEST_fnc_assert;
private _aiTreat = [TEST_ai, TEST_patient, "LeftArm", "FieldDressing"];
[(_aiTreat call PMCI_fnc_timeNormal) == 7.5 && {count ("getBandageTime" call TEST_called) == 1}, "an AI medic gets ACE's own bandage time"] call TEST_fnc_assert;
PMCI_enable_bandage = false;
[(_treat call PMCI_fnc_timeNormal) == 7.5, "with the game off, ACE's own time"] call TEST_fnc_assert;
PMCI_enable_bandage = true;
TEST_zeusOpen = true;
[(_treat call PMCI_fnc_timeNormal) == 7.5, "treating from Zeus keeps ACE's bar"] call TEST_fnc_assert;
TEST_zeusOpen = false;
PMCI_enable_tourniquet = false;
private _turnTreat = [TEST_medic, TEST_patient, "LeftLeg", "ApplyTourniquet"];
[(_turnTreat call PMCI_fnc_timeNormal) == 7 && {(_turnTreat call PMCI_fnc_timeTrained) == 4}, "ACE's normal and trained tourniquet times are kept apart"] call TEST_fnc_assert;
PMCI_enable_tourniquet = true;
[([TEST_medic, objNull, "HitLFWheel", "ReplaceWheel"] call PMCI_fnc_repairTime) == 1 && {
    ([TEST_medic, objNull, "HitLFWheel", "RemoveWheel"] call PMCI_fnc_repairTime) == 1} && {
    ([TEST_ai, objNull, "HitLFWheel", "ReplaceWheel"] call PMCI_fnc_repairTime) == 10},
    "wheel change and removal: preparation bar for the player; AI keeps ACE's time"] call TEST_fnc_assert;
private _dressing = configFile >> "ace_medical_treatment_actions" >> "FieldDressing";
[getText (_dressing >> "treatmentTimeTrained") == "PMCI_fnc_timeTrained"
    && {getText (configFile >> "ace_medical_treatment_actions" >> "CPR" >> "treatmentTimeTrained") == "PMCI_fnc_timeTrained"}
    && {([TEST_medic, TEST_patient, "LeftArm", "FieldDressing"] call PMCI_fnc_timeTrained) == 1},
    "a trained medic's bandage gets the short preparation bar too (ACE takes the trained time then)"] call TEST_fnc_assert;

// --- Treatment results ----------------------------------------------------------------------
call TEST_fnc_fresh;
private _aiArgs = [TEST_ai, TEST_patient, "LeftArm", "FieldDressing", TEST_ai, "ACE_fieldDressing", true];
_aiArgs call PMCI_fnc_treatmentSuccess;
[("ace_medical_treatment_fnc_bandage" call TEST_called) isEqualTo [["ace_medical_treatment_fnc_bandage", _aiArgs]] && {isNil "PMCI_board"},
    "an AI medic's bandage is applied by ACE at once"] call TEST_fnc_assert;
TEST_calls = [];
private _args = [TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true];
_args call PMCI_fnc_treatmentSuccess;
[!isNil "PMCI_board" && {TEST_dialogs isEqualTo ["PMCI_RscBoard"]} && {("ace_medical_treatment_fnc_bandage" call TEST_called) isEqualTo []},
    "a player's bandage opens the board and waits"] call TEST_fnc_assert;
(PMCI_board get "state") set ["quality", 1];
(PMCI_board get "state") set ["status", "success"];
call PMCI_fnc_boardTick;
private _bandaged = "ace_medical_treatment_fnc_bandage" call TEST_called;
[count _bandaged == 1 && {((_bandaged select 0) select 1) select 7 == 1.2} && {isNil "PMCI_board"},
    "a perfect packing bandages with effectiveness 1.2 through ACE"] call TEST_fnc_assert;
TEST_calls = [];
_args call PMCI_fnc_treatmentSuccess;
(PMCI_board get "state") set ["quality", 0];
(PMCI_board get "state") set ["status", "success"];
call PMCI_fnc_boardTick;
[(((("ace_medical_treatment_fnc_bandage" call TEST_called) select 0) select 1) select 7) == 0.6, "a poor packing still bandages, at 0.6"] call TEST_fnc_assert;
TEST_calls = [];
_args call PMCI_fnc_treatmentSuccess;
["cancel"] call PMCI_fnc_boardEvent;
["onUnload"] call PMCI_fnc_boardEvent;
[("ace_common_fnc_addToInventory" call TEST_called) isEqualTo [["ace_common_fnc_addToInventory", [TEST_medic, "ACE_fieldDressing"]]] && {
    ("ace_medical_treatment_fnc_bandage" call TEST_called) isEqualTo []} && {isNil "PMCI_board"}, "giving up returns the bandage"] call TEST_fnc_assert;
TEST_calls = [];
[TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "TEST_bandageMagazine", true] call PMCI_fnc_treatmentSuccess;
[false] call PMCI_fnc_finish;
[count ("ace_common_fnc_adjustMagazineAmmo" call TEST_called) == 1, "an item that is a magazine comes back as a magazine"] call TEST_fnc_assert;
// The patient walks away during the game.
TEST_calls = [];
_args call PMCI_fnc_treatmentSuccess;
TEST_patient setPos [20, 0, 0];
call PMCI_fnc_boardTick;
[isNil "PMCI_board" && {count ("ace_common_fnc_addToInventory" call TEST_called) == 1}, "moving away ends the game as given up"] call TEST_fnc_assert;
TEST_patient setPos [1, 0, 0];

// --- Tourniquet and CPR through the board ---------------------------------------------------
TEST_calls = [];
[TEST_medic, TEST_patient, "LeftLeg", "ApplyTourniquet", TEST_medic, "ACE_tourniquet", false] call PMCI_fnc_treatmentSuccess;
["keyDown", [objNull, 57]] call PMCI_fnc_boardEvent;
TEST_realTime = TEST_realTime + 0.001;
PMCI_board set ["last", TEST_realTime];
for "_i" from 1 to 22 do {TEST_realTime = TEST_realTime + 0.1; call PMCI_fnc_boardTick};
["keyUp", [objNull, 57]] call PMCI_fnc_boardEvent;
["keyDown", [objNull, 28]] call PMCI_fnc_boardEvent;
call PMCI_fnc_boardTick;
[count ("ace_medical_treatment_fnc_tourniquet" call TEST_called) == 1 && {isNil "PMCI_board"}, "Space and Enter apply a tourniquet through ACE"] call TEST_fnc_assert;
TEST_calls = [];
TEST_patient setVariable ["ACE_isUnconscious", true];
TEST_patient setVariable ["ace_medical_CPR_provider", TEST_medic];
[TEST_medic, TEST_patient, "Body", "CPR", objNull, "", false] call PMCI_fnc_treatmentSuccess;
["keyDown", [objNull, 57]] call PMCI_fnc_boardEvent;
["keyDown", [objNull, 57]] call PMCI_fnc_boardEvent;
[((PMCI_board get "state") get "presses") == 1, "a held key counts one compression, not its auto-repeat"] call TEST_fnc_assert;
["keyUp", [objNull, 57]] call PMCI_fnc_boardEvent;
TEST_patient setVariable ["ace_medical_CPR_provider", objNull];
call PMCI_fnc_boardTick;
[isNil "PMCI_board" && {count ("ace_medical_treatment_fnc_cprFailure" call TEST_called) == 1} && {("ace_medical_treatment_fnc_cprSuccess" call TEST_called) isEqualTo []},
    "CPR stops through ACE when this medic is no longer the CPR provider"] call TEST_fnc_assert;
TEST_calls = [];
TEST_patient setVariable ["ace_medical_CPR_provider", TEST_medic];
[TEST_medic, TEST_patient, "Body", "CPR", objNull, "", false] call PMCI_fnc_treatmentSuccess;
(PMCI_board get "state") set ["quality", 0.8];
(PMCI_board get "state") set ["status", "success"];
call PMCI_fnc_boardTick;
[count ("ace_medical_treatment_fnc_cprSuccess" call TEST_called) == 1, "good CPR hands over to ACE's own CPR success roll"] call TEST_fnc_assert;
TEST_patient setVariable ["ACE_isUnconscious", false];

// --- Wheel through the board ------------------------------------------------------------------
TEST_calls = [];
private _car = "C_Offroad_01_F" createVehicle [3, 0, 0];
_car setVariable ["TEST_class", "C_Offroad_01_F"];
private _spare = "ACE_Wheel" createVehicle [2, 1, 0];
private _repair = [TEST_medic, _car, "HitLFWheel", "ReplaceWheel", [], [], [_spare]];
_repair call PMCI_fnc_repairSuccess;
[("ace_common_fnc_claim" call TEST_called) isEqualTo [["ace_common_fnc_claim", [TEST_medic, _spare, false]]] && {!isNil "PMCI_board"},
    "the spare wheel is held again while the player works"] call TEST_fnc_assert;
_car setVariable ["TEST_speed", 5];
call PMCI_fnc_boardTick;
[isNil "PMCI_board" && {("ace_repair_fnc_doReplaceWheel" call TEST_called) isEqualTo []} && {
    ("ace_common_fnc_claim" call TEST_called) select 1 isEqualTo ["ace_common_fnc_claim", [objNull, _spare, false]]},
    "a vehicle driving off ends the game; the wheel is released"] call TEST_fnc_assert;
_car setVariable ["TEST_speed", 0];
TEST_calls = [];
_repair call PMCI_fnc_repairSuccess;
{["nut", _x] call PMCI_fnc_boardEvent; for "_i" from 1 to 9 do {TEST_realTime = TEST_realTime + 0.1; call PMCI_fnc_boardTick}} forEach [0, 2, 4, 1, 3];
["swap"] call PMCI_fnc_boardEvent;
for "_i" from 1 to 31 do {TEST_realTime = TEST_realTime + 0.1; call PMCI_fnc_boardTick};
{["nut", _x] call PMCI_fnc_boardEvent; for "_i" from 1 to 9 do {TEST_realTime = TEST_realTime + 0.1; call PMCI_fnc_boardTick}} forEach [0, 2, 4, 1, 3];
private _replaced = "ace_repair_fnc_doReplaceWheel" call TEST_called;
[count _replaced == 1 && {((_replaced select 0) select 1) isEqualTo _repair} && {isNil "PMCI_board"}, "a finished wheel change replaces the wheel through ACE"] call TEST_fnc_assert;
TEST_calls = [];
[TEST_ai, _car, "HitLFWheel", "ReplaceWheel", [], [], [_spare]] call PMCI_fnc_repairSuccess;
[count ("ace_repair_fnc_doReplaceWheel" call TEST_called) == 1 && {("ace_common_fnc_claim" call TEST_called) isEqualTo []}, "an AI's wheel change is done by ACE at once"] call TEST_fnc_assert;
TEST_calls = [];
[TEST_medic, _car, "HitLFWheel", "RemoveWheel", [], [], []] call PMCI_fnc_repairSuccess;
private _off = PMCI_board get "state";
private _offName = PMCI_board get "name";
{["nut", _x] call PMCI_fnc_boardEvent; ["tick", _off, 1] call PMCI_fnc_wheelModel} forEach [0, 2, 4, 1, 3];
call PMCI_fnc_boardTick;
[(_off get "phase") == "done" && {_offName == "wheelOff"} && {count ("ace_repair_fnc_doRemoveWheel" call TEST_called) == 1} && {("ace_repair_fnc_doReplaceWheel" call TEST_called) isEqualTo []} && {isNil "PMCI_board"},
    "removing a wheel: the nuts are loosened in a star, then ACE takes the wheel off"] call TEST_fnc_assert;

// --- Board pictures ---------------------------------------------------------------------------------
// Layers: scene, hands, beat, windlass, gauze, wheel, nut 0-4, then the wound games' 21.
TEST_tex = {if (_this == "") then {""} else {format ["\pmc_interactions\data\%1_ca.paa", _this]}};
TEST_look = {params ["_game", "_state", ["_depth", 0], ["_hint", false], ["_type", ""], ["_scrub", false]]; [_game, _state, _depth, _hint, _type, _scrub] call PMCI_fnc_boardLook};
TEST_near = {
    params ["_got", "_want"];
    private _ok = count _got == count _want;
    {if (abs (_x - (_want select _forEachIndex)) > 0.001) then {_ok = false}} forEach _got;
    _ok
};
TEST_full = {private _all = +_this; while {count _all < 32} do {_all pushBack ""}; _all};
TEST_none = [] call TEST_full;
private _c = ["init", nil, [15, 0.05, 0.5]] call PMCI_fnc_cprModel;
private _look = ["cpr", _c, 1] call TEST_look;
[_look isEqualTo ((["cpr_scene", "cpr_hands_down", "cpr_beat_on"] call TEST_full) apply {_x call TEST_tex}),
    "CPR shows the casualty, pressed hands and the lit heart at the start of a beat"] call TEST_fnc_assert;
_c set ["t", 0.3];
_look = ["cpr", _c, 0.4] call TEST_look;
[(_look select 1) == ("cpr_hands_up" call TEST_tex) && {(_look select 2) == ("cpr_beat_off" call TEST_tex)},
    "between compressions the hands are up and the heart is dark between beats"] call TEST_fnc_assert;
_c set ["t", 60 / 110 * 3 + 0.05];
[((["cpr", _c] call TEST_look) select 2) == ("cpr_beat_on" call TEST_tex), "the heart lights again on every beat at 110 per minute"] call TEST_fnc_assert;
private _t = ["init", nil, [0.6, 0.8, 0.32, 25, 2]] call PMCI_fnc_tourniquetModel;
private _frames = [-0.1, 0, 0.124, 0.13, 0.5, 0.99, 1.2] apply {_t set ["p", _x]; (["tourniquet", _t] call TEST_look) select 3};
[_frames isEqualTo ([0, 0, 0, 1, 4, 7, 7] apply {format ["tq_windlass_%1", _x] call TEST_tex})
    && {((["tourniquet", _t] call TEST_look) select 0) == ("tq_scene" call TEST_tex)},
    "the windlass turns one frame per eighth of the pressure and stays within the eight frames"] call TEST_fnc_assert;
private _b = ["init", nil, [0.3, 30, 6, 0.25]] call PMCI_fnc_bandageModel;
private _stages = [0, 0.01, 0.25, 0.26, 0.5, 0.75, 1] apply {_b set ["progress", _x]; (["bandage", _b] call TEST_look) select 4};
[_stages isEqualTo (["", "bandage_gauze_1", "bandage_gauze_1", "bandage_gauze_2", "bandage_gauze_2", "bandage_gauze_3", "bandage_gauze_4"] apply {_x call TEST_tex}),
    "no gauze before packing starts, then one stage per quarter of the packing"] call TEST_fnc_assert;
private _w = ["init", nil, [0.8, 3]] call PMCI_fnc_wheelModel;
private _wait = {params ["_state", "_s"]; for "_i" from 1 to round (_s / 0.1) do {["tick", _state, 0.1] call PMCI_fnc_wheelModel}};
private _nuts = {params ["_hint"]; (["wheel", _w, 0, _hint] call TEST_look) select [6, 5]};
[(["wheel", _w] call TEST_look) isEqualTo ((["", "", "", "", "", "wheel_old", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight"] call TEST_full) apply {_x call TEST_tex}),
    "the wheel starts as the old wheel with five tight nuts, no scene picture"] call TEST_fnc_assert;
[([true] call _nuts) isEqualTo ((["wheel_nut_tight"] call {_this + _this + _this + _this + _this}) apply {_x call TEST_tex}),
    "no hint before the first nut: any nut may start the star"] call TEST_fnc_assert;
["nut", _w, 1] call PMCI_fnc_wheelModel;
[_w, 0.9] call _wait;
[([true] call _nuts) isEqualTo (["wheel_nut_tight", "wheel_nut_loose", "wheel_nut_tight", "wheel_nut_next", "wheel_nut_tight"] apply {_x call TEST_tex})
    && {([false] call _nuts) isEqualTo (["wheel_nut_tight", "wheel_nut_loose", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight"] apply {_x call TEST_tex})},
    "a loosened nut shows loose; the hint marks every second nut only on easy"] call TEST_fnc_assert;
{["nut", _w, _x] call PMCI_fnc_wheelModel; [_w, 0.9] call _wait} forEach [3, 0, 2, 4];
private _swapLook = ["wheel", _w, 0, true] call TEST_look;
[(_w get "phase") == "swap" && {(_swapLook select 5) == ("wheel_old" call TEST_tex)}
    && {(_swapLook select [6, 5]) isEqualTo ((["wheel_nut_loose"] call {_this + _this + _this + _this + _this}) apply {_x call TEST_tex})},
    "with all nuts loose the old wheel waits for the swap"] call TEST_fnc_assert;
["swap", _w] call PMCI_fnc_wheelModel;
[_w, 3.1] call _wait;
["nut", _w, 2] call PMCI_fnc_wheelModel;
[_w, 0.9] call _wait;
private _tightLook = ["wheel", _w, 0, true] call TEST_look;
[(_tightLook select 5) == ("wheel_new" call TEST_tex)
    && {(_tightLook select [6, 5]) isEqualTo (["wheel_nut_loose", "wheel_nut_loose", "wheel_nut_done", "wheel_nut_loose", "wheel_nut_next"] apply {_x call TEST_tex})},
    "after the swap the new wheel shows; tightened nuts are marked done"] call TEST_fnc_assert;
{["nut", _w, _x] call PMCI_fnc_wheelModel; [_w, 0.9] call _wait} forEach [4, 1, 3, 0];
[(_w get "status") == "success" && {(["wheel", _w] call TEST_look) isEqualTo ((["", "", "", "", "", "wheel_new", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight"] call TEST_full) apply {_x call TEST_tex})},
    "a finished change shows the new wheel with all nuts tight"] call TEST_fnc_assert;
[(["unknown", _w] call TEST_look) isEqualTo TEST_none, "an unknown game shows no pictures"] call TEST_fnc_assert;

// --- Wounds: which one, which game ------------------------------------------------------------
// ACE's wound classes in config order; a class ID is 10 x index + size.
ace_medical_damage_woundClassNames = ["Abrasion", "Avulsion", "Contusion", "Crush", "Cut", "Laceration", "VelocityWound", "PunctureWound", "ThermalBurn"];
private _names = ace_medical_damage_woundClassNames;
[([[[61, 1, 0.02, 0.3], [41, 2, 0.008, 0.1], [22, 1, 0, 0.5]], _names] call PMCI_fnc_woundOf) isEqualTo ["VelocityWound", 1]
    && {([[[61, 1, 0.02, 0.3], [41, 3, 0.008, 0.1]], _names] call PMCI_fnc_woundOf) isEqualTo ["Cut", 1]},
    "the wound treated first is the one losing most blood (amount x bleeding), with its size"] call TEST_fnc_assert;
[([[[22, 3, 0, 0.5], [82, 1, 0, 0.2]], _names] call PMCI_fnc_woundOf) isEqualTo ["", 0] && {([[], _names] call PMCI_fnc_woundOf) isEqualTo ["", 0]},
    "bruises and burns do not bleed: no wound to bandage"] call TEST_fnc_assert;
private _games = ["VelocityWound", "PunctureWound", "Avulsion", "Crush", "Cut", "Laceration", "Abrasion", ""] apply {[_x] call PMCI_fnc_woundGame};
[_games isEqualTo ["bandage", "bandage", "pressure", "pressure", "edges", "edges", "clean", "bandage"],
    "gunshot and puncture: packing; avulsion and crush: pressure; cut and laceration: edges; abrasion: cleaning"] call TEST_fnc_assert;
PMCI_enable_edges = false;
[(["Cut"] call PMCI_fnc_woundGame) == "bandage" && {(["Abrasion"] call PMCI_fnc_woundGame) == "clean"}, "a wound game switched off falls back to packing"] call TEST_fnc_assert;
PMCI_enable_edges = true;

// --- Pressure -------------------------------------------------------------------------------------
TEST_fnc_pressure = {
    params ["_mode"];
    private _state = ["init", nil, [0.58, 0.78, 6, 30, 100, 0.1]] call PMCI_fnc_pressureModel;
    while {(_state get "status") == "running"} do {
        private _hold = switch (_mode) do {case "steer": {(_state get "needle") < 0.68}; case "always": {true}; default {false}};
        ["release", "press"] select _hold call {[_this, _state] call PMCI_fnc_pressureModel};
        ["tick", _state, 0.02] call PMCI_fnc_pressureModel;
    };
    _state
};
private _held = ["steer"] call TEST_fnc_pressure;
[(_held get "status") == "success" && {(_held get "quality") > 0.6} && {(_held get "t") < 12}, "answering each pulse keeps the pressure in the zone and stops the bleeding"] call TEST_fnc_assert;
private _crushed = ["always"] call TEST_fnc_pressure;
[(_crushed get "status") == "fail" && {(_crushed get "needle") > 0.9}, "pressing all the time overshoots the zone and runs out of time"] call TEST_fnc_assert;
[((["idle"] call TEST_fnc_pressure) get "status") == "fail", "doing nothing runs out of time"] call TEST_fnc_assert;
private _beats = [0, 0.1] apply {
    private _state = ["init", nil, [0.58, 0.78, 6, 30, 100, _x]] call PMCI_fnc_pressureModel;
    ["press", _state] call PMCI_fnc_pressureModel;
    for "_i" from 1 to 61 do {["tick", _state, 0.01] call PMCI_fnc_pressureModel};
    _state get "needle"
};
[abs ((_beats select 0) - 0.505) < 0.001 && {abs (((_beats select 0) - (_beats select 1)) - 0.1) < 0.001},
    "holding raises the pressure by half the gauge per second; one pulse beat (100 per minute, after 0.6 s) knocks it down by the kick"] call TEST_fnc_assert;

// --- Closing the edges ------------------------------------------------------------------------------
private _e = ["init", nil, [[[0.1, 0.2], [0.5, 0.6]], 0.5, 30, 1]] call PMCI_fnc_edgesModel;
for "_i" from 1 to 300 do {["tick", _e, 0.01] call PMCI_fnc_edgesModel};
[abs ((_e get "pos") - 0.5) < 0.001 && {(_e get "dir") == -1}, "the runner goes to the end of the wound and comes back"] call TEST_fnc_assert;
_e = ["init", nil, [[[0.1, 0.2], [0.5, 0.6]], 0.5, 30, 1]] call PMCI_fnc_edgesModel;
while {(_e get "status") == "running"} do {
    private _pos = _e get "pos";
    private _open = (_e get "stretches") findIf {_pos >= (_x select 0) + 0.02 && {_pos <= (_x select 1) - 0.02}};
    if (_open >= 0 && {!(_open in (_e get "closed"))}) then {["press", _e] call PMCI_fnc_edgesModel};
    ["tick", _e, 0.01] call PMCI_fnc_edgesModel;
};
[(_e get "status") == "success" && {(_e get "quality") == 1} && {(_e get "closed") isEqualTo [0, 1]}, "a strip on every stretch with no miss closes the wound at full quality"] call TEST_fnc_assert;
_e = ["init", nil, [[[0.1, 0.2], [0.5, 0.6]], 0.5, 30, 1]] call PMCI_fnc_edgesModel;
_e set ["pos", 0.15];
["press", _e] call PMCI_fnc_edgesModel;
["press", _e] call PMCI_fnc_edgesModel;
[(_e get "closed") isEqualTo [0] && {(_e get "misses") == 1} && {(_e get "status") == "running"}, "a second strip on a closed stretch is a miss"] call TEST_fnc_assert;
_e set ["pos", 0.35];
["press", _e] call PMCI_fnc_edgesModel;
[(_e get "status") == "fail", "one miss more than allowed fails"] call TEST_fnc_assert;
_e = ["init", nil, [[[0.1, 0.2], [0.5, 0.6]], 0.5, 30, 3]] call PMCI_fnc_edgesModel;
{_e set ["pos", _x]; ["press", _e] call PMCI_fnc_edgesModel} forEach [0.3, 0.15, 0.55];
[(_e get "status") == "success" && {abs ((_e get "quality") - 0.8) < 0.001}, "each miss costs a fifth of the quality"] call TEST_fnc_assert;

// --- Cleaning -------------------------------------------------------------------------------------
private _c = ["init", nil, [[[100, 100, 50], [300, 100, 50]], 0.01, 20, 1]] call PMCI_fnc_cleanModel;
["scrub", _c, [110, 90, 60]] call PMCI_fnc_cleanModel;
["scrub", _c, [200, 100, 500]] call PMCI_fnc_cleanModel;
[abs (((_c get "dirt") select 0) - 0.4) < 0.0001 && {((_c get "dirt") select 1) == 1}, "scrubbing wears only the dirt under the mouse, by the distance scrubbed"] call TEST_fnc_assert;
["press", _c] call PMCI_fnc_cleanModel;
for "_i" from 1 to 20 do {["tick", _c, 0.1] call PMCI_fnc_cleanModel};
[(_c get "covered") == 0 && {(_c get "phase") == "clean"}, "the dressing cannot go on a dirty wound"] call TEST_fnc_assert;
["scrub", _c, [100, 100, 40]] call PMCI_fnc_cleanModel;
["scrub", _c, [300, 110, 93]] call PMCI_fnc_cleanModel;
[(_c get "phase") == "clean", "a spot with 7% of its dirt left still needs scrubbing"] call TEST_fnc_assert;
["scrub", _c, [300, 110, 3]] call PMCI_fnc_cleanModel;
[(_c get "phase") == "cover" && {(_c get "dirt") isEqualTo [0, 0]}, "almost clean (under 5% left) counts as clean: then the dressing"] call TEST_fnc_assert;
for "_i" from 1 to 11 do {["tick", _c, 0.1] call PMCI_fnc_cleanModel};
[(_c get "status") == "success" && {(_c get "quality") == 1}, "holding covers the wound; done early is full quality"] call TEST_fnc_assert;
_c = ["init", nil, [[[100, 100, 50]], 0.01, 20, 1]] call PMCI_fnc_cleanModel;
for "_i" from 1 to 150 do {["tick", _c, 0.1] call PMCI_fnc_cleanModel};
[abs ((_c get "quality") - 0.72) < 0.01 && {(_c get "status") == "running"}, "quality falls after 40% of the time limit"] call TEST_fnc_assert;
for "_i" from 1 to 51 do {["tick", _c, 0.1] call PMCI_fnc_cleanModel};
[(_c get "status") == "fail", "the time limit fails"] call TEST_fnc_assert;

// --- CPR: a broken rib -----------------------------------------------------------------------------
[(([0.3] call TEST_fnc_cpr) get "fast") > 10 && {(([0.545] call TEST_fnc_cpr) get "fast") == 0}, "compressions faster than the accepted rhythm are counted"] call TEST_fnc_assert;
call TEST_fnc_fresh;
TEST_patient setVariable ["ACE_isUnconscious", true];
TEST_patient setVariable ["ace_medical_CPR_provider", TEST_medic];
PMCI_ribChance = 1;
PMCI_ribMax = 1;
[TEST_medic, TEST_patient, "Body", "CPR", TEST_medic, "", true] call PMCI_fnc_treatmentSuccess;
private _cprState = PMCI_board get "state";
TEST_fnc_tap = {params ["_at"]; _cprState set ["t", _at]; ["keyDown", [0, 57]] call PMCI_fnc_boardEvent; ["keyUp", [0, 57]] call PMCI_fnc_boardEvent};
{[_x] call TEST_fnc_tap} forEach [1, 1.55, 2.1];
[("CBA_fnc_targetEvent" call TEST_called) isEqualTo [] && {([PMCI_board, ["ribs", 0]] call TEST_fnc_getDefault) == 0}, "compressions in rhythm break nothing"] call TEST_fnc_assert;
{[_x] call TEST_fnc_tap} forEach [2.3, 2.5, 2.7];
[("CBA_fnc_targetEvent" call TEST_called) isEqualTo [["CBA_fnc_targetEvent", ["PMCI_ribFracture", [TEST_patient, TEST_medic], TEST_patient]]]
    && {(PMCI_board get "ribs") == 1} && {(PMCI_board get "crackAt") == 2.3},
    "a too fast compression breaks a rib on the patient's machine, at most the set number per CPR"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
call TEST_fnc_fresh;
TEST_patient setVariable ["ACE_isUnconscious", true];
TEST_patient setVariable ["ace_medical_CPR_provider", TEST_medic];
PMCI_ribChance = 0;
[TEST_medic, TEST_patient, "Body", "CPR", TEST_medic, "", true] call PMCI_fnc_treatmentSuccess;
_cprState = PMCI_board get "state";
{[_x] call TEST_fnc_tap} forEach [1, 1.1, 1.2, 1.3];
[("CBA_fnc_targetEvent" call TEST_called) isEqualTo [], "with no chance set, no rib breaks"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
TEST_patient setVariable ["ACE_isUnconscious", false];
TEST_events = [];
CBA_fnc_addEventHandler = {TEST_events pushBack _this; 0};
call PMCI_fnc_events;
TEST_calls = [];
[TEST_patient, TEST_medic] call ((TEST_events select 0) select 1);
[(TEST_events select 0 select 0) == "PMCI_ribFracture"
    && {("ace_medical_fnc_addDamageToUnit" call TEST_called) isEqualTo [["ace_medical_fnc_addDamageToUnit", [TEST_patient, 0.2, "Body", "pmci_ribs", TEST_medic]]]},
    "the rib becomes an ACE wound of the mod's damage type on the chest"] call TEST_fnc_assert;

// --- Bandaging picks the wound's game -----------------------------------------------------------------
TEST_fnc_bandageOn = {
    params ["_wounds"];
    call TEST_fnc_fresh;
    TEST_patient setVariable ["ace_medical_openWounds", createHashMapFromArray [["leftarm", _wounds]]];
    [TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
    [PMCI_board get "game", PMCI_board get "wound", PMCI_board get "state"]
};
private _opened = [[[41, 1, 0.01, 0.1]]] call TEST_fnc_bandageOn;
[(_opened select 0) == "edges" && {(_opened select 1) isEqualTo ["Cut", 1]} && {count ((_opened select 2) get "stretches") == 4},
    "a medium cut opens closing the edges with four stretches"] call TEST_fnc_assert;
(PMCI_board get "state") set ["quality", 1];
(PMCI_board get "state") set ["status", "success"];
call PMCI_fnc_boardTick;
private _bandaged = "ace_medical_treatment_fnc_bandage" call TEST_called;
[count _bandaged == 1 && {((_bandaged select 0) select 1) select 7 == 1.2}, "a wound game's quality sets the bandage's effectiveness like packing does"] call TEST_fnc_assert;
// Held Space repeats keyDown: only the first places a strip (the repeat would be a miss).
[[[41, 1, 0.01, 0.1]]] call TEST_fnc_bandageOn;
(PMCI_board get "state") set ["pos", (((PMCI_board get "state") get "stretches") select 1) call {((_this select 0) + (_this select 1)) / 2}];
["keyDown", [0, 57]] call PMCI_fnc_boardEvent;
["keyDown", [0, 57]] call PMCI_fnc_boardEvent;
[((PMCI_board get "state") get "closed") isEqualTo [1] && {((PMCI_board get "state") get "misses") == 0}, "holding Space places one strip, not a miss after it"] call TEST_fnc_assert;
["keyUp", [0, 57]] call PMCI_fnc_boardEvent;
[false] call PMCI_fnc_finish;
_opened = [[[52, 1, 0.05, 0.2], [12, 1, 0.1, 0.4]]] call TEST_fnc_bandageOn;
[(_opened select 0) == "pressure" && {(_opened select 1) isEqualTo ["Avulsion", 2]} && {((_opened select 2) get "hold") == 8}
    && {((_opened select 2) get "rate") == 100}, "a large avulsion opens direct pressure, the longest hold and the faster pulse"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
_opened = [[[0, 1, 0.001, 0.1]]] call TEST_fnc_bandageOn;
[(_opened select 0) == "clean" && {count ((_opened select 2) get "spots") == 4}, "a minor abrasion opens cleaning with four dirt spots"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
_opened = [[[52, 1, 0.05, 0.2]]] call TEST_fnc_bandageOn;
private _lacerated = (_opened select 2) get "stretches";
[(_opened select 0) == "edges" && {count _lacerated == 7} && {(((_lacerated select 1) select 1) - ((_lacerated select 1) select 0)) < (((_lacerated select 0) select 1) - ((_lacerated select 0) select 0))},
    "a large laceration has seven stretches of uneven width"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
_opened = [[[71, 1, 0.05, 0.2]]] call TEST_fnc_bandageOn;
[(_opened select 0) == "bandage" && {(_opened select 1) isEqualTo ["PunctureWound", 1]}, "a puncture wound is packed"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
TEST_patient setVariable ["ace_medical_openWounds", nil];

// --- Wound games: pictures and moving layers ----------------------------------------------------------
private _p = ["init", nil, [0.58, 0.78, 6, 30, 100, 0.1]] call PMCI_fnc_pressureModel;
_p set ["needle", 0.2];
private _pLook = ["pressure", _p, 0, false, "Crush"] call TEST_look;
private _pMarks = ["pressure", _p] call PMCI_fnc_boardMarks;
[(_pLook select 0) == ("wound_crush" call TEST_tex) && {(_pLook select 11) == ("pressure_hand_light" call TEST_tex)}
    && {((_pMarks select 0) select 2) > 0.9}, "too little pressure: a light hand and blood seeping out"] call TEST_fnc_assert;
_p set ["needle", 0.65];
_pMarks = ["pressure", _p] call PMCI_fnc_boardMarks;
[((["pressure", _p, 0, false, "Avulsion"] call TEST_look) select 11) == ("pressure_hand_firm" call TEST_tex) && {((_pMarks select 0) select 2) == 0}
    && {((["pressure", _p, 0, false, "Avulsion"] call TEST_look) select 0) == ("wound_avulsion" call TEST_tex)}, "enough pressure: a firm hand, no seeping"] call TEST_fnc_assert;
private _ed = ["init", nil, [[[0.1, 0.2], [0.5, 0.6]], 0.5, 30, 1]] call PMCI_fnc_edgesModel;
_ed set ["pos", 0.15];
["press", _ed] call PMCI_fnc_edgesModel;
private _edLook = ["edges", _ed, 0, false, "Laceration"] call TEST_look;
private _edMarks = ["edges", _ed] call PMCI_fnc_boardMarks;
[(_edLook select 0) == ("wound_laceration" call TEST_tex) && {(_edLook select 15) == ("edges_strip" call TEST_tex)} && {(_edLook select 16) == ("edges_target" call TEST_tex)}
    && {(_edLook select 17) == ""} && {(_edLook select 31) == ("edges_runner" call TEST_tex)}
    && {[(_edMarks select 0) select 1, [232 + 560 * 0.15 - 36, 150, 72, 212]] call TEST_near}
    && {[(_edMarks select 1) select 1, [232 + 560 * 0.5, 196, 560 * 0.1, 120]] call TEST_near}
    && {[(_edMarks select 2) select 1, [232 + 560 * 0.15 - 20, 150, 40, 212]] call TEST_near},
    "a placed strip covers its stretch, open stretches are highlighted, the runner follows the marker"] call TEST_fnc_assert;
private _cl = ["init", nil, [[[100, 100, 50], [300, 100, 50]], 0.01, 20, 1]] call PMCI_fnc_cleanModel;
["scrub", _cl, [100, 100, 30]] call PMCI_fnc_cleanModel;
private _clLook = ["clean", _cl, 0, false, "Abrasion", true] call TEST_look;
private _clMarks = ["clean", _cl, [120, 140]] call PMCI_fnc_boardMarks;
[(_clLook select 0) == ("wound_abrasion" call TEST_tex) && {(_clLook select 23) == ("dirt_1" call TEST_tex)} && {(_clLook select 24) == ("dirt_2" call TEST_tex)}
    && {(_clLook select 25) == ""} && {(_clLook select 14) == ("abrasion_swab" call TEST_tex)} && {(_clLook select 13) == ""}
    && {abs (((_clMarks select 0) select 2) - 0.7) < 0.001} && {[(_clMarks select 2) select 1, [72, 92, 96, 96]] call TEST_near},
    "dirt fades as it is scrubbed; the swab follows the mouse while scrubbing"] call TEST_fnc_assert;
_cl set ["phase", "cover"];
[((["clean", _cl] call TEST_look) select 13) == ("abrasion_pad" call TEST_tex) && {((["clean", _cl] call TEST_look) select 14) == ""},
    "once clean, the dressing pad appears"] call TEST_fnc_assert;
private _pk = ["init", nil, [0.3, 30, 6, 0.25]] call PMCI_fnc_bandageModel;
[((["bandage", _pk, 0, false, "VelocityWound"] call TEST_look) select 0) == ("wound_velocity" call TEST_tex)
    && {((["bandage", _pk, 0, false, "PunctureWound"] call TEST_look) select 0) == ("wound_puncture" call TEST_tex)}
    && {((["bandage", _pk] call TEST_look) select 0) == ("bandage_scene" call TEST_tex)},
    "packing shows the gunshot or puncture wound, or the general wound when the type is unknown"] call TEST_fnc_assert;

// --- ACE medical menu --------------------------------------------------------------------------------
// A treatment from the menu: ACE marks the menu to reopen, which would close the board.
call TEST_fnc_fresh;
ace_medical_gui_pendingReopen = true;
ace_medical_gui_openAfterTreatment = true;
[TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
[!ace_medical_gui_pendingReopen && {PMCI_board get "reopenMenu"}, "a game started from the medical menu stops ACE reopening the menu over it"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
private _reopen = "CBA_fnc_execNextFrame" call TEST_called;
[count _reopen == 1 && {((_reopen select 0) select 1) select 1 isEqualTo TEST_patient}
    && {(((_reopen select 0) select 1) select 0) isEqualTo ace_medical_gui_fnc_openMenu}, "when the game ends the menu reopens on the patient"] call TEST_fnc_assert;
call TEST_fnc_fresh;
[TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
[false] call PMCI_fnc_finish;
[("CBA_fnc_execNextFrame" call TEST_called) isEqualTo [], "a game started from the interaction menu reopens nothing"] call TEST_fnc_assert;
ace_medical_gui_openAfterTreatment = false;
call TEST_fnc_fresh;
ace_medical_gui_pendingReopen = true;
[TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
[false] call PMCI_fnc_finish;
[("CBA_fnc_execNextFrame" call TEST_called) isEqualTo [], "with ACE's 'open after treatment' off, the menu stays closed"] call TEST_fnc_assert;

// --- IV -------------------------------------------------------------------------------------------------
TEST_ivTicks = {params ["_state", "_s"]; for "_i" from 1 to round (_s / 0.05) do {["tick", _state, 0.05] call PMCI_fnc_ivModel}};
private _iv = ["init", nil, [[0, 100, 400, 100], 10, 1, 20, 1, 0]] call PMCI_fnc_ivModel;
["mouse", _iv, [200, 104, 0, true]] call PMCI_fnc_ivModel;
[_iv, 1.05] call TEST_ivTicks;
[(_iv get "status") == "success" && {(_iv get "quality") == 1}, "holding the needle on the vein pushes it in"] call TEST_fnc_assert;
_iv = ["init", nil, [[0, 100, 400, 100], 10, 1, 20, 1, 0]] call PMCI_fnc_ivModel;
["mouse", _iv, [200, 130, 0, true]] call PMCI_fnc_ivModel;
[_iv, 0.1] call TEST_ivTicks;
["mouse", _iv, [200, 100, 0, true]] call PMCI_fnc_ivModel;
[_iv, 0.5] call TEST_ivTicks;
[(_iv get "misses") == 1 && {(_iv get "depth") == 0} && {(_iv get "lastMiss") isEqualTo [200, 130]},
    "pushing off the vein blows it; the needle must be pushed again with a fresh press"] call TEST_fnc_assert;
["mouse", _iv, [200, 100, 0, false]] call PMCI_fnc_ivModel;
["mouse", _iv, [200, 100, 0, true]] call PMCI_fnc_ivModel;
[_iv, 1.05] call TEST_ivTicks;
[(_iv get "status") == "success" && {(_iv get "quality") == 0.75}, "a miss costs a quarter of the quality"] call TEST_fnc_assert;
_iv = ["init", nil, [[0, 100, 400, 100], 10, 1, 20, 0, 0]] call PMCI_fnc_ivModel;
["mouse", _iv, [200, 300, 0, true]] call PMCI_fnc_ivModel;
[_iv, 0.05] call TEST_ivTicks;
[(_iv get "status") == "fail", "one miss more than allowed fails"] call TEST_fnc_assert;
_iv = ["init", nil, [[0, 100, 400, 100], 10, 1, 20, 1, 6]] call PMCI_fnc_ivModel;
["mouse", _iv, [200, 104, 0, true]] call PMCI_fnc_ivModel;
[_iv, 0.5] call TEST_ivTicks;
private _inTip = _iv get "tip";
(_iv get "entry") params [["_ex", -1], ["_ey", -1]];
[abs (_ex - 200) <= 6 && {_ey == 100} && {[_inTip, [_ex - 30 * 0.5 * cos 40, 100 + 30 * 0.5 * sin 40]] call TEST_near},
    "once the vein is pierced the needle stays there and slides in, without trembling"] call TEST_fnc_assert;
["mouse", _iv, [215, 104, 0, true]] call PMCI_fnc_ivModel;
[_iv, 0.05] call TEST_ivTicks;
[(_iv get "misses") == 1 && {(_iv get "entry") isEqualTo []} && {(_iv get "depth") == 0}, "moving the hand while pushing blows the vein"] call TEST_fnc_assert;
_iv = ["init", nil, [[0, 100, 400, 100], 10, 1, 20, 1, 6]] call PMCI_fnc_ivModel;
["mouse", _iv, [200, 100, 0, false]] call PMCI_fnc_ivModel;
[_iv, 0.5] call TEST_ivTicks;
[[_iv get "tip", [200 + 6 * sin (0.5 * 317), 100 + 6 * cos (0.5 * 241)]] call TEST_near, "the tip trembles around the mouse"] call TEST_fnc_assert;

// --- Suture (led like a weld along the zigzag of stitch points) ------------------------------------------
TEST_zigzag = [[100, 100], [110, 150], [200, 100], [210, 150]];
// The point at distance _d along a polyline.
TEST_fnc_along = {
    params ["_points", "_d"];
    private _at = +(_points select (count _points - 1));
    for "_i" from 1 to count _points - 1 do {
        (_points select (_i - 1)) params ["_ax", "_ay"];
        (_points select _i) params ["_bx", "_by"];
        private _len = sqrt ((_bx - _ax) ^ 2 + (_by - _ay) ^ 2);
        if (_d <= _len) exitWith {_at = [_ax + (_bx - _ax) * _d / _len, _ay + (_by - _ay) * _d / _len]};
        _d = _d - _len;
    };
    _at
};
TEST_fnc_stitch = {
    params ["_speed", ["_until", 1e9], ["_dy", 0]];
    private _state = ["init", nil, [TEST_zigzag, 10, 20, 140, 60]] call PMCI_fnc_sutureModel;
    private _d = 0;
    while {(_state get "status") == "running" && {_d <= (_until min 240)}} do {
        (([TEST_zigzag, _d] call TEST_fnc_along)) params ["_x0", "_y0"];
        ["mouse", _state, [_x0, _y0 + _dy, _speed * 0.02, true, 0.02]] call PMCI_fnc_sutureModel;
        ["tick", _state, 0.02] call PMCI_fnc_sutureModel;
        _d = _d + _speed * 0.02;
    };
    _state
};
private _su = [80] call TEST_fnc_stitch;
[(_su get "status") == "success" && {(_su get "quality") > 0.95} && {(_su get "next") == 4}, "leading the needle steadily through all points stitches the wound"] call TEST_fnc_assert;
_su = [300] call TEST_fnc_stitch;
[(_su get "status") == "success" && {(_su get "quality") == 0.2}, "too fast pulls the stitches loose: the lowest quality"] call TEST_fnc_assert;
_su = [80, 60] call TEST_fnc_stitch;
[(_su get "next") == 2 && {(_su get "status") == "running"}, "passing the second point finishes the first stitch"] call TEST_fnc_assert;
private _suLook = ["suture", _su] call TEST_look;
private _suMarks = ["suture", _su] call PMCI_fnc_boardMarks;
private _faint = _suMarks select {(_x select 0) == 23};
[(_suLook select 15) == ("suture_stitch" call TEST_tex) && {(_suLook select 16) == ""} && {(_suLook select 31) == ("suture_point" call TEST_tex)}
    && {(_suLook select 23) == ("suture_point" call TEST_tex)} && {(_suLook select 24) == ""}
    && {count _faint == 1} && {((_faint select 0) select 2) == 0.45} && {[(_faint select 0) select 1, [196, 136, 28, 28]] call TEST_near},
    "a finished stitch is drawn, the next point glows, the points after it show faintly"] call TEST_fnc_assert;
_su = [80, 1e9, 40] call TEST_fnc_stitch;
[(_su get "covered") == 0 && {(_su get "next") == 0}, "away from the points nothing is stitched"] call TEST_fnc_assert;
_su = ["init", nil, [TEST_zigzag, 10, 20, 140, 60]] call PMCI_fnc_sutureModel;
for "_i" from 1 to 60 do {["mouse", _su, [100, 100, 0, true, 0.05]] call PMCI_fnc_sutureModel; ["tick", _su, 0.05] call PMCI_fnc_sutureModel};
[(_su get "status") == "running" && {(_su get "heat") == 0}, "the thread does not overheat: going slowly is fine"] call TEST_fnc_assert;

// --- Splint ----------------------------------------------------------------------------------------------
private _sp = ["init", nil, [20, 4, 1, 30, 5, 0.25]] call PMCI_fnc_splintModel;
for "_i" from 1 to 10 do {["tick", _sp, 0.1] call PMCI_fnc_splintModel};
[(_sp get "angle") > 24, "the spasm pushes the broken part further from straight"] call TEST_fnc_assert;
_sp = ["init", nil, [20, 4, 1, 30, 0, 0.25]] call PMCI_fnc_splintModel;
["mouse", _sp, [0, 0, 0, true]] call PMCI_fnc_splintModel;
["mouse", _sp, [100, 0, 100, true]] call PMCI_fnc_splintModel;
["mouse", _sp, [300, 0, 200, false]] call PMCI_fnc_splintModel;
[abs ((_sp get "angle") + 5) < 0.001, "dragging right with the button held turns it back; moving without the button does nothing"] call TEST_fnc_assert;
["mouse", _sp, [0, 0, 0, true]] call PMCI_fnc_splintModel;
["mouse", _sp, [-20, 0, 20, true]] call PMCI_fnc_splintModel;
for "_i" from 1 to 11 do {["tick", _sp, 0.1] call PMCI_fnc_splintModel};
[(_sp get "status") == "success" && {(_sp get "quality") == 1}, "held straight for the hold time, the splint goes on"] call TEST_fnc_assert;
_sp = ["init", nil, [2, 4, 1, 30, 5, 0.25]] call PMCI_fnc_splintModel;
for "_i" from 1 to 3 do {["tick", _sp, 0.1] call PMCI_fnc_splintModel};
private _was = _sp get "aligned";
for "_i" from 1 to 3 do {["tick", _sp, 0.1] call PMCI_fnc_splintModel};
[_was > 0.25 && {(_sp get "aligned") == 0} && {(_sp get "status") == "running"}, "drifting out of the zone starts the count again"] call TEST_fnc_assert;

// --- Diagnosis and repair of a component ------------------------------------------------------------------
private _dg = ["init", nil, [5, 2, 1, 2, 40, 0.55, 0.75]] call PMCI_fnc_diagnoseModel;
["test", _dg, 0] call PMCI_fnc_diagnoseModel;
["test", _dg, 1] call PMCI_fnc_diagnoseModel;
[(_dg get "tested") isEqualTo [0] && {(_dg get "mistakes") == 1}, "testing a good part is a mistake and takes time: no second test meanwhile"] call TEST_fnc_assert;
for "_i" from 1 to 11 do {["tick", _dg, 0.1] call PMCI_fnc_diagnoseModel};
["test", _dg, 0] call PMCI_fnc_diagnoseModel;
["test", _dg, 2] call PMCI_fnc_diagnoseModel;
[(_dg get "tested") isEqualTo [0, 2] && {(_dg get "phase") == "fix"} && {(_dg get "mistakes") == 1}, "the faulty part found, the repair begins"] call TEST_fnc_assert;
while {(_dg get "status") == "running"} do {
    [["release", "press"] select ((_dg get "needle") < 0.65), _dg] call PMCI_fnc_diagnoseModel;
    ["tick", _dg, 0.05] call PMCI_fnc_diagnoseModel;
};
[(_dg get "status") == "success" && {(_dg get "quality") > 0.5}
    && {abs ((_dg get "quality") - (0.4 + 0.6 * (_dg get "inside") / (_dg get "fixT") - 0.1 * (_dg get "mistakes"))) < 0.0001},
    "holding the force in the zone repairs it; quality is how steadily, minus a tenth per wrong part"] call TEST_fnc_assert;
_dg = ["init", nil, [5, 2, 1, 2, 3, 0.55, 0.75]] call PMCI_fnc_diagnoseModel;
for "_i" from 1 to 31 do {["tick", _dg, 0.1] call PMCI_fnc_diagnoseModel};
[(_dg get "status") == "fail", "the time limit fails"] call TEST_fnc_assert;

// --- Weld ---------------------------------------------------------------------------------------------------
TEST_fnc_weld = {
    params ["_speed", ["_y", 100]];
    private _state = ["init", nil, [[[0, 100], [200, 100], [400, 100]], 10, 20, 200, 60, 1]] call PMCI_fnc_weldModel;
    private _x0 = 0;
    for "_i" from 1 to 400 do {
        if ((_state get "status") != "running") exitWith {};
        _x0 = _x0 + _speed * 0.05;
        ["mouse", _state, [_x0, _y, _speed * 0.05, true, 0.05]] call PMCI_fnc_weldModel;
        ["tick", _state, 0.05] call PMCI_fnc_weldModel;
    };
    _state
};
private _wd = [100] call TEST_fnc_weld;
[(_wd get "status") == "success" && {(_wd get "quality") > 0.95}, "a steady torch along the crack lays a good seam"] call TEST_fnc_assert;
_wd = [300] call TEST_fnc_weld;
[(_wd get "status") == "success" && {(_wd get "quality") == 0.2} && {(_wd get "good") == 0}, "too fast lays a weak seam: the lowest quality"] call TEST_fnc_assert;
_wd = [0] call TEST_fnc_weld;
[(_wd get "status") == "fail" && {(_wd get "t") < 1.2}, "standing still on the seam burns through the plate"] call TEST_fnc_assert;
_wd = [100, 150] call TEST_fnc_weld;
[(_wd get "covered") == 0 && {(_wd get "heat") == 0}, "away from the crack nothing is welded"] call TEST_fnc_assert;
_wd = ["init", nil, [[[0, 100], [400, 100]], 10, 20, 200, 60, 1]] call PMCI_fnc_weldModel;
["mouse", _wd, [300, 100, 300, true, 0.05]] call PMCI_fnc_weldModel;
[(_wd get "covered") == 0, "the bead goes on from where it ended, not jumping ahead"] call TEST_fnc_assert;

// --- Track ---------------------------------------------------------------------------------------------------
private _tr = ["init", nil, [40, 6, 0.5, 2, 0.6, 0.9, 1, 30, 1]] call PMCI_fnc_trackModel;
["tick", _tr, 0.5] call PMCI_fnc_trackModel;
["press", _tr] call PMCI_fnc_trackModel;
[(_tr get "misses") == 1 && {(_tr get "phase") == "align"}, "pressing while the link is off the track is a miss"] call TEST_fnc_assert;
["tick", _tr, 0.5] call PMCI_fnc_trackModel;
["press", _tr] call PMCI_fnc_trackModel;
[(_tr get "phase") == "pin", "pressing as the holes line up holds the link"] call TEST_fnc_assert;
["tick", _tr, 0.75] call PMCI_fnc_trackModel;
["press", _tr] call PMCI_fnc_trackModel;
["tick", _tr, 0.5] call PMCI_fnc_trackModel;
["press", _tr] call PMCI_fnc_trackModel;
[(_tr get "status") == "success" && {abs ((_tr get "quality") - 0.85) < 0.001}, "hits in the zone drive the pin in; the miss costs 15%"] call TEST_fnc_assert;

// --- Which game a medical action or repair plays ---------------------------------------------------------------------
private _tank = "B_MBT_01_cannon_F" createVehicle [3, 3, 0];
_tank setVariable ["TEST_class", "B_MBT_01_cannon_F"];
_tank setVariable ["TEST_hitPoints", [["HitHull", "HitEngine", "HitFuel", "HitTurret", "HitLTrack"], [], [0.5, 0.5, 0.5, 0.5, 0.5]]];
[([0, 1, 2, 3, 4] apply {[_tank, _x, "repair"] call PMCI_fnc_repairGame}) isEqualTo ["weld", "", "", "", ""]
    && {([_tank, "HitBody", "repair"] call PMCI_fnc_repairGame) == "weld"} && {([_tank, "HitLTrack", "track"] call PMCI_fnc_repairGame) == "track"},
    "a component repair is a weld on the hull or body, no game elsewhere (diagnosis off for now); tracks stay tracks"] call TEST_fnc_assert;
[([0, 1, 2, 3, 4] apply {[_tank, _x] call PMCI_fnc_partOf}) isEqualTo ["hull", "engine", "fuel", "turret", "other"], "the part named in the title"] call TEST_fnc_assert;
call TEST_fnc_fresh;
[([TEST_medic, _tank, 0, "MiscRepair"] call PMCI_fnc_repairTime) == 1 && {([TEST_medic, _tank, 1, "MiscRepair"] call PMCI_fnc_repairTime) == 15}
    && {([TEST_medic, _tank, 1, "RemoveTrack"] call PMCI_fnc_repairTime) == 15},
    "a hull repair gets the short bar; the engine and removing a track keep ACE's time"] call TEST_fnc_assert;
[TEST_medic, _tank, 0, "MiscRepair", [], [], []] call PMCI_fnc_repairSuccess;
[(PMCI_board get "game") == "weld" && {(PMCI_board get "part") == "hull"}, "a hull repair opens the weld"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
call TEST_fnc_fresh;
[TEST_medic, _tank, 1, "MiscRepair", [], [], []] call PMCI_fnc_repairSuccess;
[isNil "PMCI_board" && {("ace_repair_fnc_doRepair" call TEST_called) isEqualTo [["ace_repair_fnc_doRepair", [TEST_medic, _tank, 1, "MiscRepair", [], [], []]]]},
    "an engine repair is done by ACE at once after its own bar"] call TEST_fnc_assert;
call TEST_fnc_fresh;
[TEST_medic, _tank, 0, "MiscRepair", [], [], []] call PMCI_fnc_repairSuccess;
private _weldState = PMCI_board get "state";
private _variant = _weldState get "variant";
[_variant in [1, 2, 3, 4] && {(_weldState get "seam") isEqualTo ((call PMCI_fnc_weldSeams) select (_variant - 1))}
    && {abs ((_weldState get "limit") - 40 * (_weldState get "total") / 650) < 0.001}
    && {((["weld", _weldState] call TEST_look) select 0) == (format ["weld_scene_%1", _variant] call TEST_tex)},
    "a hull repair picks one of four cracks with its plate; the time limit grows with the crack"] call TEST_fnc_assert;
(PMCI_board get "state") set ["quality", 1];
(PMCI_board get "state") set ["status", "success"];
call PMCI_fnc_boardTick;
[("ace_repair_fnc_doRepair" call TEST_called) isEqualTo [["ace_repair_fnc_doRepair", [TEST_medic, _tank, 0, "MiscRepair", [], [], []]]], "a finished weld is repaired by ACE"] call TEST_fnc_assert;
call TEST_fnc_fresh;
private _track = "ACE_Track" createVehicle [2, 3, 0];
[TEST_medic, _tank, "HitLTrack", "RepairTrack", [], [], [_track]] call PMCI_fnc_repairSuccess;
[(PMCI_board get "game") == "track" && {("ace_common_fnc_claim" call TEST_called) isEqualTo [["ace_common_fnc_claim", [TEST_medic, _track, false]]]},
    "a track repair opens the track game and holds the spare track"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
private _actions = configFile >> "ACE_Repair" >> "Actions";
[getText (_actions >> "RemoveTrack" >> "callbackSuccess") == "ace_repair_fnc_doRemoveTrack"
    && {getText (_actions >> "FullRepair" >> "callbackSuccess") == "ace_repair_fnc_doFullRepair"}
    && {getText (_actions >> "FullRepair" >> "repairingTime") == "ace_repair_fnc_getFullRepairTime"}
    && {getText (_actions >> "ReplaceTrack" >> "callbackSuccess") == "PMCI_fnc_repairSuccess"},
    "removing a track and the full repair stay ACE's own; replacing a track is taken over"] call TEST_fnc_assert;
call TEST_fnc_fresh;
[([TEST_medic, TEST_patient, "LeftArm", "BloodIV_500"] call PMCI_fnc_timeNormal) == 1, "an IV bag (any size) gets the short bar"] call TEST_fnc_assert;
PMCI_enable_iv = false;
[([TEST_medic, TEST_patient, "LeftArm", "PlasmaIV"] call PMCI_fnc_timeNormal) == 12
    && {([TEST_medic, TEST_patient, "LeftArm", "PlasmaIV"] call PMCI_fnc_timeTrained) == 8}, "with IVs switched off, ACE's own times"] call TEST_fnc_assert;
PMCI_enable_iv = true;
{
    _x params ["_class", "_game"];
    call TEST_fnc_fresh;
    [TEST_medic, TEST_patient, "LeftArm", _class, TEST_medic, "", true] call PMCI_fnc_treatmentSuccess;
    [(PMCI_board get "game") == _game, format ["%1 opens the %2 game", _class, _game]] call TEST_fnc_assert;
    [false] call PMCI_fnc_finish;
} forEach [["BloodIV_500", "iv"], ["PlasmaIV", "iv"], ["Splint", "splint"]];
call TEST_fnc_fresh;
[TEST_medic, TEST_patient, "LeftArm", "BloodIV", TEST_medic, "ACE_bloodIV", true] call PMCI_fnc_treatmentSuccess;
(PMCI_board get "state") set ["quality", 1];
(PMCI_board get "state") set ["status", "success"];
call PMCI_fnc_boardTick;
[count ("ace_medical_treatment_fnc_ivBag" call TEST_called) == 1, "a placed IV is given by ACE"] call TEST_fnc_assert;

// --- Surgical kit ---------------------------------------------------------------------------------------------------
call TEST_fnc_fresh;
TEST_patient setVariable ["ace_medical_bandagedWounds", createHashMapFromArray [["leftarm", [[41, 1, 0, 0.1], [61, 1, 0, 0.3], [11, 1, 0, 0.4]]]]];
[TEST_medic, TEST_patient, "LeftArm", "SurgicalKit", TEST_medic, "", true] call PMCI_fnc_treatmentSuccess;
[(PMCI_board get "game") == "suture" && {count ((PMCI_board get "state") get "points") == 6} && {((PMCI_board get "state") get "limit") == 40}
    && {((PMCI_board get "state") get "fast") == 140} && {((PMCI_board get "state") get "slow") == 20} && {((PMCI_board get "state") get "tolerance") == 14},
    "three bandaged wounds: three stitches to lead the needle through, normal speed limits"] call TEST_fnc_assert;
TEST_stitchable = 3;
(PMCI_board get "state") set ["quality", 1];
(PMCI_board get "state") set ["status", "success"];
call PMCI_fnc_boardTick;
[count ("stitchWound" call TEST_called) == 3 && {("useItem" call TEST_called) isEqualTo []}, "a finished suture stitches every bandaged wound with ACE's stitchWound"] call TEST_fnc_assert;
call TEST_fnc_fresh;
ace_medical_treatment_consumeSurgicalKit = 2;
TEST_patient setVariable ["ace_medical_bandagedWounds", createHashMapFromArray [["leftarm", [[41, 1, 0, 0.1], [61, 1, 0, 0.3], [11, 1, 0, 0.4]]]]];
TEST_stitchable = 3;
[TEST_medic, TEST_patient, "leftarm"] call PMCI_fnc_stitch;
[count ("stitchWound" call TEST_called) == 1 && {count ("useItem" call TEST_called) == 1}, "with sutures consumed and none left, stitching stops after the first wound"] call TEST_fnc_assert;
TEST_calls = [];
TEST_sutureUser = TEST_medic;
TEST_patient setVariable ["ace_medical_bandagedWounds", createHashMapFromArray [["leftarm", [[41, 1, 0, 0.1], [61, 1, 0, 0.3], [11, 1, 0, 0.4]]]]];
TEST_stitchable = 3;
[TEST_medic, TEST_patient, "leftarm"] call PMCI_fnc_stitch;
[count ("stitchWound" call TEST_called) == 3 && {count ("useItem" call TEST_called) == 2}, "one suture for each further wound"] call TEST_fnc_assert;
ace_medical_treatment_consumeSurgicalKit = 0;
// Twelve wounds in three entries: ten stitches at most; the first entry is split.
call TEST_fnc_fresh;
TEST_patient setVariable ["ace_medical_bandagedWounds", createHashMapFromArray [["leftarm", [[41, 5, 0, 0.1], [61, 4, 0, 0.3], [11, 3, 0, 0.4]]]]];
[TEST_medic, TEST_patient, "LeftArm", "SurgicalKit", TEST_medic, "", true] call PMCI_fnc_treatmentSuccess;
private _many = PMCI_board get "state";
TEST_stitchable = 10;
_many set ["quality", 1];
_many set ["status", "success"];
call PMCI_fnc_boardTick;
private _rest = [TEST_patient getVariable ["ace_medical_bandagedWounds", createHashMap], ["leftarm", []]] call TEST_fnc_getDefault;
private _stitched = ("stitchWound" call TEST_called) apply {(_x select 1) param [2, []]};
[count (_many get "points") == 20 && {(_many get "limit") == 80} && {count _stitched == 3} && {(_stitched select 2) isEqualTo [41, 3, 0, 0.1]}
    && {_rest isEqualTo [[41, 2, 0, 0.1]]},
    "one stitch per wound, ten at most (more time for more): the wounds over that stay bandaged for the next kit"] call TEST_fnc_assert;
PMCI_sutureMax = 4;
[([TEST_patient, "LeftArm"] call PMCI_fnc_stitchCount) == 2 && {([TEST_patient, "Head"] call PMCI_fnc_stitchCount) == 0}, "the stitches per kit follow the CBA limit"] call TEST_fnc_assert;
PMCI_sutureMax = 10;
TEST_patient setVariable ["ace_medical_bandagedWounds", nil];
TEST_calls = [];
private _progress = [[TEST_medic, TEST_patient, "LeftArm"], 0.5, 1] call PMCI_fnc_stitchProgress;
[_progress && {("ace_medical_treatment_fnc_surgicalKitProgress" call TEST_called) isEqualTo []}, "before a game nothing is stitched during the short bar"] call TEST_fnc_assert;
[[TEST_ai, TEST_patient, "LeftArm"], 0.5, 1] call PMCI_fnc_stitchProgress;
[count ("ace_medical_treatment_fnc_surgicalKitProgress" call TEST_called) == 1, "an AI medic stitches the ACE way"] call TEST_fnc_assert;

// --- The mouse in the game loop ---------------------------------------------------------------------------------------
call TEST_fnc_fresh;
[TEST_medic, TEST_patient, "LeftArm", "BloodIV", TEST_medic, "ACE_bloodIV", true] call PMCI_fnc_treatmentSuccess;
TEST_mouse = [500, 250];
["scrubDown"] call PMCI_fnc_boardEvent;
TEST_realTime = TEST_realTime + 0.1;
call PMCI_fnc_boardTick;
private _ivState = PMCI_board get "state";
[(_ivState get "mouse") isEqualTo [500, 250] && {_ivState get "held"} && {_ivState get "pushing"}, "the IV needle follows the mouse and the held button pushes it"] call TEST_fnc_assert;
["scrubUp"] call PMCI_fnc_boardEvent;
TEST_realTime = TEST_realTime + 0.1;
call PMCI_fnc_boardTick;
[!(_ivState get "held") && {(_ivState get "depth") == 0}, "letting go pulls the needle out"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
call TEST_fnc_fresh;
TEST_patient setVariable ["ace_medical_bandagedWounds", createHashMapFromArray [["leftarm", [[41, 3, 0, 0.1]]]]];
[TEST_medic, TEST_patient, "LeftArm", "SurgicalKit", TEST_medic, "", true] call PMCI_fnc_treatmentSuccess;
private _points = (PMCI_board get "state") get "points";
TEST_mouse = +(_points select 0);
["scrubDown"] call PMCI_fnc_boardEvent;
TEST_realTime = TEST_realTime + 0.1;
call PMCI_fnc_boardTick;
TEST_mouse = [_points, 8] call TEST_fnc_along;
TEST_realTime = TEST_realTime + 0.1;
call PMCI_fnc_boardTick;
[((PMCI_board get "state") get "covered") > 0 && {((PMCI_board get "state") get "next") == 1}, "holding the button and moving along lays the thread"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
TEST_patient setVariable ["ace_medical_bandagedWounds", nil];

// --- Later games: pictures and moving layers -----------------------------------------------------------------------------
private _ivLook = ["iv", _iv] call TEST_look;
[(_ivLook select 0) == ("iv_scene" call TEST_tex) && {(_ivLook select 14) == ("iv_needle" call TEST_tex)}
    && {[((["iv", _iv] call PMCI_fnc_boardMarks) select 0) select 1, [((_iv get "tip") select 0) - 20, ((_iv get "tip") select 1) - 236, 256, 256]] call TEST_near},
    "the IV needle is drawn with its tip at the trembling tip"] call TEST_fnc_assert;
_iv set ["lastMiss", [120, 140]];
[((["iv", _iv] call TEST_look) select 13) == ("iv_bruise" call TEST_tex), "a blown vein leaves a bruise"] call TEST_fnc_assert;
_sp set ["angle", -27.5];
[((["splint", _sp] call TEST_look) select 12) == ("splint_limb" call TEST_tex) && {(["splint", _sp] call PMCI_fnc_boardMarks) isEqualTo [[12, [0, -256, 1024, 1024], 1, -27.5]]},
    "the broken part is one picture turned smoothly to its angle about the break"] call TEST_fnc_assert;
_dg = ["init", nil, [5, 2, 1, 2, 40, 0.55, 0.75]] call PMCI_fnc_diagnoseModel;
_dg set ["spots", [[100, 100], [200, 100], [300, 100], [400, 100], [500, 100]]];
_dg set ["tested", [0, 2]];
private _dgLook = ["diagnose", _dg] call TEST_look;
_dg set ["phase", "fix"];
[(_dgLook select 6) == ("diag_ok" call TEST_tex) && {(_dgLook select 8) == ""} && {(((["diagnose", _dg] call TEST_look)) select 8) == ("diag_bad" call TEST_tex)}
    && {(_dgLook select 7) == ""} && {((["diagnose", _dg] call PMCI_fnc_boardMarks) select 2) select 1 isEqualTo [276, 8, 48, 48]},
    "tested good parts light up green, the found fault red, untested ones not at all"] call TEST_fnc_assert;
_wd = [100] call TEST_fnc_weld;
_wd set ["covered", 0.3];
private _beads = (["weld", _wd] call TEST_look) select [15, 16];
private _bend = +_wd;
_bend set ["seam", [[0, 100], [200, 100], [200, 300]]];
_bend set ["lengths", [200, 400]];
_bend set ["covered", 1];
private _turned = (["weld", _bend] call PMCI_fnc_boardMarks) select 12;
[(_beads select [0, 4]) isEqualTo ((["weld_bead", "weld_bead", "weld_bead", "weld_bead"]) apply {_x call TEST_tex}) && {(_beads select 4) == ""}
    && {((["weld", _wd] call TEST_look) select 0) == ("weld_scene_1" call TEST_tex)}
    && {(((["weld", _wd] call PMCI_fnc_boardMarks) select 2) select [0, 2]) isEqualTo [17, [50, 87.5, 25, 25]]}
    && {(_turned select 0) == 27} && {abs ((_turned select 3) - 90) < 0.001} && {[_turned select 1, [187.5, 200, 25, 25]] call TEST_near},
    "the bead shows in sixteenths of the seam, each piece turned along it (down the crack after a corner)"] call TEST_fnc_assert;
_tr = ["init", nil, [40, 6, 0.5, 4, 0.6, 0.9, 1, 30, 1]] call PMCI_fnc_trackModel;
_tr set ["offset", 12];
_tr set ["done", 2];
private _trMarks = ["track", _tr] call PMCI_fnc_boardMarks;
[((_trMarks select 0) select 1) isEqualTo [384, 140, 256, 256] && {((_trMarks select 1) select 1) isEqualTo [545, 224, 256, 64]},
    "the loose link swings with its offset; the pin goes in with the hits"] call TEST_fnc_assert;

// --- Balance and keys from CBA ------------------------------------------------------------------------------
call TEST_fnc_fresh;
private _keybinds = ("CBA_fnc_addKeybind" call TEST_called) apply {[(_x select 1) select 1, (_x select 1) select 5]};
[_keybinds isEqualTo [["pmci_press", [57, [false, false, false]]], ["pmci_fix", [28, [false, false, false]]]],
    "two keys in CBA's controls: press/hold on Space, fix on Enter"] call TEST_fnc_assert;
PMCI_ivTolerance = 20;
PMCI_ivMisses = 4;
[TEST_medic, TEST_patient, "LeftArm", "BloodIV", TEST_medic, "ACE_bloodIV", true] call PMCI_fnc_treatmentSuccess;
[((PMCI_board get "state") get "tolerance") == 20 && {((PMCI_board get "state") get "allowed") == 4}, "the IV takes its vein tolerance and misses from the settings"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
call TEST_fnc_fresh;
PMCI_trackHits = 7;
PMCI_trackZone = 0.3;
[TEST_medic, _tank, "HitLTrack", "RepairTrack", [], [], [_track]] call PMCI_fnc_repairSuccess;
private _trSet = PMCI_board get "state";
[(_trSet get "hits") == 7 && {abs ((_trSet get "high") - (_trSet get "low") - 0.3) < 0.0001}, "the track takes its strikes and zone from the settings"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
private _opened2 = [[[12, 1, 0.1, 0.4]]] call TEST_fnc_bandageOn;
private _kickDefault = (_opened2 select 2) get "kick";
[false] call PMCI_fnc_finish;
call TEST_fnc_fresh;
PMCI_pressurePulse = 2;
PMCI_pressureHold = 9;
TEST_patient setVariable ["ace_medical_openWounds", createHashMapFromArray [["leftarm", [[12, 1, 0.1, 0.4]]]]];
[TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
[abs (((PMCI_board get "state") get "kick") - 2 * _kickDefault) < 0.0001 && {((PMCI_board get "state") get "hold") == 12},
    "pressure: pulse strength scales the kick; a large wound holds 4/3 of the set time"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
TEST_patient setVariable ["ace_medical_openWounds", nil];
call TEST_fnc_fresh;
PMCI_bandageFill = 9;
PMCI_edgesMisses = 5;
PMCI_cleanScrub = 900;
TEST_patient setVariable ["ace_medical_openWounds", createHashMapFromArray [["leftarm", [[62, 1, 0.2, 0.5]]]]];
[TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
private _fill = (PMCI_board get "state") get "fill";
[false] call PMCI_fnc_finish;
TEST_patient setVariable ["ace_medical_openWounds", createHashMapFromArray [["leftarm", [[41, 1, 0.01, 0.1]]]]];
[TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
private _cutMisses = (PMCI_board get "state") get "allowed";
[false] call PMCI_fnc_finish;
PMCI_cleanScrub = 900;
TEST_patient setVariable ["ace_medical_openWounds", createHashMapFromArray [["leftarm", [[0, 1, 0.001, 0.1]]]]];
[TEST_medic, TEST_patient, "LeftArm", "FieldDressing", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
private _scrubRate = (PMCI_board get "state") get "rate";
[false] call PMCI_fnc_finish;
TEST_patient setVariable ["ace_medical_openWounds", nil];
[_fill == 12 && {_cutMisses == 5} && {abs (_scrubRate - 1 / 900) < 1e-9},
    "packing time (a large wound 4/3 of it), misses on the edges and scrubbing come from the settings"] call TEST_fnc_assert;
call TEST_fnc_fresh;
PMCI_difficulty = 0;
TEST_patient setVariable ["ace_medical_openWounds", nil];
[TEST_medic, TEST_patient, "LeftArm", "ApplyTourniquet", TEST_medic, "ACE_tourniquet", true] call PMCI_fnc_treatmentSuccess;
[((PMCI_board get "state") get "allowed") == 2, "on easy the tourniquet allows one slip more than set"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
call TEST_fnc_fresh;
PMCI_difficulty = 0;
PMCI_ivTolerance = 10;
[TEST_medic, TEST_patient, "LeftArm", "BloodIV", TEST_medic, "ACE_bloodIV", true] call PMCI_fnc_treatmentSuccess;
[abs (((PMCI_board get "state") get "tolerance") - 13.5) < 0.0001, "the set value is the normal difficulty's; easy scales it up"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
// Keys: defaults without CBA's keybinds, then a player's own.
[(["press", 57, [false, false, false]] call PMCI_fnc_keyIs) && {!(["press", 28] call PMCI_fnc_keyIs)}
    && {["fix", 28] call PMCI_fnc_keyIs} && {["fix", 156] call PMCI_fnc_keyIs}, "by default Space presses, Enter (or numpad Enter) fixes"] call TEST_fnc_assert;
TEST_binds = [["pmci_press", [[30, [false, true, false]]]], ["pmci_fix", []]];
CBA_fnc_getKeybind = {
    params ["", "_action"];
    private _i = TEST_binds findIf {(_x select 0) == _action};
    if (_i < 0) exitWith {nil};
    private _binds = (TEST_binds select _i) select 1;
    ["PMC Interactions", _action, "", {}, {}, _binds param [0, [-1, [false, false, false]]], false, 0, _binds]
};
[(["press", 30, [false, true, false]] call PMCI_fnc_keyIs) && {!(["press", 30, [false, false, false]] call PMCI_fnc_keyIs)}
    && {["press", 30] call PMCI_fnc_keyIs} && {!(["press", 57, [false, false, false]] call PMCI_fnc_keyIs)},
    "a key set in CBA (Ctrl+A) needs its modifiers to press; letting go counts without them; Space no longer presses"] call TEST_fnc_assert;
[!(["fix", 28] call PMCI_fnc_keyIs) && {(["fix"] call PMCI_fnc_keysOf) isEqualTo []}, "a removed key does nothing (the buttons still work)"] call TEST_fnc_assert;
TEST_binds = [["pmci_press", [[-1, [false, false, false]]]]];
[(["press"] call PMCI_fnc_keysOf) isEqualTo [] && {["fix", 28] call PMCI_fnc_keyIs},
    "CBA's empty key slot is no key; an action CBA does not know keeps its default"] call TEST_fnc_assert;
TEST_binds = [["pmci_press", [[30, [false, true, false]]]], ["pmci_fix", []]];
CBA_fnc_localizeKey = {format ["K%1", _this select 0]};
[(["press"] call PMCI_fnc_keyName) == "K30", "the hints name the key set in CBA"] call TEST_fnc_assert;
call TEST_fnc_fresh;
TEST_patient setVariable ["ACE_isUnconscious", true];
TEST_patient setVariable ["ace_medical_CPR_provider", TEST_medic];
[TEST_medic, TEST_patient, "Body", "CPR", TEST_medic, "", true] call PMCI_fnc_treatmentSuccess;
["keyDown", [0, 57, false, false, false]] call PMCI_fnc_boardEvent;
private _before = (PMCI_board get "state") get "presses";
["keyDown", [0, 30, false, true, false]] call PMCI_fnc_boardEvent;
[_before == 0 && {((PMCI_board get "state") get "presses") == 1}, "on the board the rebound key compresses and Space does not"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
TEST_patient setVariable ["ACE_isUnconscious", false];
CBA_fnc_getKeybind = nil;
CBA_fnc_localizeKey = nil;

// --- Difficulty -----------------------------------------------------------------------------------
call TEST_fnc_fresh;
TEST_trained = true;
PMCI_difficulty = 0;
[TEST_medic, TEST_patient, "LeftArm", "QuikClot", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
private _wide = (PMCI_board get "state") get "width";
[false] call PMCI_fnc_finish;
TEST_trained = false;
PMCI_difficulty = 2;
[TEST_medic, TEST_patient, "LeftArm", "PackingBandage", TEST_medic, "ACE_fieldDressing", true] call PMCI_fnc_treatmentSuccess;
private _narrow = (PMCI_board get "state") get "width";
[false] call PMCI_fnc_finish;
[_wide > 0.45 && {_narrow < 0.15}, "an easy QuikClot by a trained medic is much easier than a hard packing bandage"] call TEST_fnc_assert;

// --- Lock picking -------------------------------------------------------------------------------
// [sweet, zone, falloff, turn/s, life, picks, limit]
TEST_fnc_pick = {
    params ["_angleX", "_angleY", ["_seconds", 2], ["_picks", 3]];
    private _p = ["init", nil, [[60], 5, 45, 1.2, 1, _picks, 90]] call PMCI_fnc_lockpickModel;
    ["mouse", _p, [_angleX, _angleY, 1, false, 0.02]] call PMCI_fnc_lockpickModel;
    ["press", _p] call PMCI_fnc_lockpickModel;
    for "_i" from 1 to round (_seconds / 0.05) do {["tick", _p, 0.05] call PMCI_fnc_lockpickModel};
    _p
};
// 60 degrees (right of up): the mouse at (512 + 100 cos 60, 300 - 100 sin 60).
private _open = [562, 300 - 86.6025] call TEST_fnc_pick;
[(_open get "status") == "success" && {(_open get "quality") == 1} && {(_open get "broken") == 0} && {abs (((_open get "angles") select 0) - 60) < 0.01},
    "the pick at the sweet spot turns the plug all the way and opens the lock"] call TEST_fnc_assert;
// 90 degrees: 25 past the zone of 5 with a falloff of 45 -> the plug stops at 1 - 25/45.
private _half = [512, 200, 0.5] call TEST_fnc_pick;
[(_half get "status") == "running" && {abs ((_half get "turn") - (1 - 25 / 45)) < 0.001} && {(_half get "strained") == 0} && {(_half get "broken") == 0},
    "further from the spot the plug stops early and the pick strains"] call TEST_fnc_assert;
private _snap = [512, 200, 1.6] call TEST_fnc_pick;
[(_snap get "broken") == 1 && {(_snap get "picks") == 2} && {(_snap get "turn") == 0} && {!(_snap get "turning")} && {(_snap get "status") == "running"},
    "forcing it too long breaks a pick: one pick less, the plug springs back, a new press is needed"] call TEST_fnc_assert;
private _last = [512, 200, 1.6, 1] call TEST_fnc_pick;
[(_last get "status") == "fail", "the last pick broken fails"] call TEST_fnc_assert;
private _any = [512, 200, 1.6, -1] call TEST_fnc_pick;
[(_any get "status") == "running" && {(_any get "picks") == -1}, "without a lockpick class the picks never run out"] call TEST_fnc_assert;
["mouse", _any, [900, 250, 1, false, 0.02]] call PMCI_fnc_lockpickModel;
private _right = (_any get "angles") select 0;
["mouse", _any, [100, 400, 1, false, 0.02]] call PMCI_fnc_lockpickModel;
private _below = (_any get "angles") select 0;
["press", _any] call PMCI_fnc_lockpickModel;
["mouse", _any, [512, 100, 1, false, 0.02]] call PMCI_fnc_lockpickModel;
[_right < 10 && {_below == 180} && {((_any get "angles") select 0) == 180}, "the pick follows the mouse around the keyhole, stays at an end below it and holds still while turning"] call TEST_fnc_assert;
private _back = [562, 300 - 86.6025, 0.4] call TEST_fnc_pick;
private _was = _back get "turn";
["release", _back] call PMCI_fnc_lockpickModel;
["tick", _back, 0.1] call PMCI_fnc_lockpickModel;
[_was > 0.4 && {abs ((_back get "turn") - (_was - 0.24)) < 0.001}, "released, the plug springs back"] call TEST_fnc_assert;
private _slow = ["init", nil, [[60], 5, 45, 1.2, 1, 3, 2]] call PMCI_fnc_lockpickModel;
for "_i" from 1 to 50 do {["tick", _slow, 0.05] call PMCI_fnc_lockpickModel};
[(_slow get "status") == "fail", "the time limit fails"] call TEST_fnc_assert;

// Two picks: both must be at their spots; the fix key switches the one the mouse moves.
TEST_fnc_mouseAt = {params ["_p", "_deg"]; ["mouse", _p, [512 + 100 * cos _deg, 300 - 100 * sin _deg, 1, false, 0.02]] call PMCI_fnc_lockpickModel};
private _duo = ["init", nil, [[40, 140], 5, 45, 1.2, 1, 3, 90]] call PMCI_fnc_lockpickModel;
[_duo, 40] call TEST_fnc_mouseAt;
["fix", _duo] call PMCI_fnc_lockpickModel;
["mouse", _duo, [512 - 100, 300, 0, false, 0.02]] call PMCI_fnc_lockpickModel;
private _still = ((_duo get "angles") select 1) == 120;
[_duo, 100] call TEST_fnc_mouseAt;
private _kept = _still && {[(_duo get "angles"), [40, 100]] call TEST_near};
["press", _duo] call PMCI_fnc_lockpickModel;
["fix", _duo] call PMCI_fnc_lockpickModel;
for "_i" from 1 to 6 do {["tick", _duo, 0.05] call PMCI_fnc_lockpickModel};
[_kept && {(_duo get "active") == 1} && {(_duo get "strained") == 1} && {abs ((_duo get "turn") - (1 - 35 / 45)) < 0.001},
    "two picks: the fix key switches the moved pick (it waits for the mouse to move; not while turning); the one off its spot stops the plug and shakes"] call TEST_fnc_assert;
["release", _duo] call PMCI_fnc_lockpickModel;
[_duo, 140] call TEST_fnc_mouseAt;
["press", _duo] call PMCI_fnc_lockpickModel;
for "_i" from 1 to 20 do {["tick", _duo, 0.05] call PMCI_fnc_lockpickModel};
[(_duo get "status") == "success", "both picks at their spots open the lock"] call TEST_fnc_assert;
private _snapTwo = ["init", nil, [[40, 140], 5, 45, 1.2, 1, 2, 90]] call PMCI_fnc_lockpickModel;
["press", _snapTwo] call PMCI_fnc_lockpickModel;
for "_i" from 1 to 45 do {["tick", _snapTwo, 0.05] call PMCI_fnc_lockpickModel};
private _duoMarks = ["lockpick", _duo] call PMCI_fnc_boardMarks;
[(_snapTwo get "status") == "fail" && {(_snapTwo get "picks") == 1}
    && {((_duoMarks select 1) select [0, 3]) isEqualTo [14, [288, 76, 448, 448], 0.55]} && {((_duoMarks select 2) select [0, 3]) isEqualTo [13, [288, 76, 448, 448], 1]}
    && {((["lockpick", _duo] call TEST_look) select 13) == ("lock_pick" call TEST_tex)},
    "a two-pick lock fails when fewer than two picks are left; the inactive pick is dimmed"] call TEST_fnc_assert;
PMCI_lockpickTwo = 1;
private _pinsNormal = [[0] call PMCI_fnc_lockPins, [1] call PMCI_fnc_lockPins, [2] call PMCI_fnc_lockPins];
PMCI_lockpickTwo = 3;
[_pinsNormal isEqualTo [1, 2, 2] && {([2] call PMCI_fnc_lockPins) == 1}, "the CBA setting chooses from which difficulty a lock takes two picks"] call TEST_fnc_assert;
PMCI_lockpickTwo = 2;

// --- Safe -----------------------------------------------------------------------------------------
// [numbers, tolerance, range, gain, limit, mistakes allowed]; the mouse drags 1 number per px.
TEST_fnc_dial = {
    params ["_s", "_px"];
    private _from = 500;
    ["mouse", _s, [_from, 0, 0, true, 0.02]] call PMCI_fnc_safeModel;
    ["mouse", _s, [_from + _px, 0, 0, true, 0.02]] call PMCI_fnc_safeModel;
    ["mouse", _s, [_from + _px, 0, 0, false, 0.02]] call PMCI_fnc_safeModel;
    ["tick", _s, 0.05] call PMCI_fnc_safeModel;
};
private _safe = ["init", nil, [[30, 10, 5], 2, 12, 1, 90, 1]] call PMCI_fnc_safeModel;
[_safe, 24] call TEST_fnc_dial;
private _near = _safe get "signal";
[_safe, 6] call TEST_fnc_dial;
[abs (_near - 0.5) < 0.001 && {(_safe get "signal") == 1} && {(_safe get "dial") == 30}, "turning up, the needle rises towards the first number"] call TEST_fnc_assert;
["press", _safe] call PMCI_fnc_safeModel;
[_safe, -15] call TEST_fnc_dial;
private _overshoot = _safe get "signal";
[_safe, 3] call TEST_fnc_dial;
private _blocked = (_safe get "dial") == 15 && {(_safe get "blockedAt") == (_safe get "t") - 0.05};
[_safe, -5] call TEST_fnc_dial;
["press", _safe] call PMCI_fnc_safeModel;
[(_safe get "next") == 2 && {_overshoot > 0} && {_blocked} && {(_safe get "mistakes") == 0},
    "the second number is dialled turning down; the dial does not go back up"] call TEST_fnc_assert;
[_safe, 99] call TEST_fnc_dial;
["press", _safe] call PMCI_fnc_safeModel;
[(_safe get "dial") == 9 && {(_safe get "mistakes") == 1} && {(_safe get "next") == 2}, "a number passed by and set anyway is a mistake"] call TEST_fnc_assert;
[_safe, -4] call TEST_fnc_dial;
[_safe, 96] call TEST_fnc_dial;
["press", _safe] call PMCI_fnc_safeModel;
[(_safe get "status") == "success" && {abs ((_safe get "quality") - 0.85) < 0.001}, "going round again reaches it; all numbers set opens the safe, 15% off per mistake"] call TEST_fnc_assert;
private _noisy = ["init", nil, [[50], 2, 12, 1, 90, 0, 0.2]] call PMCI_fnc_safeModel;
[_noisy, 50] call TEST_fnc_dial;
private _peaks = [];
for "_i" from 1 to 10 do {["tick", _noisy, 0.05] call PMCI_fnc_safeModel; _peaks pushBack (_noisy get "signal")};
[(_peaks findIf {_x < 0.97}) >= 0 && {(_peaks findIf {_x > 1 || {_x < 0}}) < 0}, "the needle trembles, staying between 0 and 1"] call TEST_fnc_assert;
private _wrap = ["init", nil, [[99], 2, 12, 1, 90, 0]] call PMCI_fnc_safeModel;
[_wrap, 97] call TEST_fnc_dial;
[_wrap, 4] call TEST_fnc_dial;
private _wrapped = _wrap get "dial";
["press", _wrap] call PMCI_fnc_safeModel;
[_wrapped == 1 && {(_wrap get "status") == "success"}, "the dial goes round past 99 and the tolerance counts across it"] call TEST_fnc_assert;
private _miss = ["init", nil, [[50], 2, 12, 1, 90, 0]] call PMCI_fnc_safeModel;
[_miss, 40] call TEST_fnc_dial;
["press", _miss] call PMCI_fnc_safeModel;
[(_miss get "status") == "fail", "one mistake too many fails"] call TEST_fnc_assert;

// --- Terminal -----------------------------------------------------------------------------------
// Codes 0-3, the answer is 2 ("4719"); rows: junk, codes, two brackets.
TEST_fnc_term = {
    ["init", nil, [["4711", "1719", "4719", "9999"], 2, [["junk", -1], ["code", 0], ["code", 1], ["code", 2], ["code", 3], ["bracket", 0], ["bracket", 1]],
        4, ["dud", "reset"], 60]] call PMCI_fnc_terminalModel
};
private _term = call TEST_fnc_term;
["pick", _term, 1] call PMCI_fnc_terminalModel;
["pick", _term, 1] call PMCI_fnc_terminalModel;
["pick", _term, 0] call PMCI_fnc_terminalModel;
[((_term get "log") select 0) isEqualTo ["no", "4711", 3] && {(_term get "left") == 2} && {((_term get "log") select 1) isEqualTo ["junk"]} && {count (_term get "log") == 2},
    "a wrong code costs an attempt and tells the likeness, once; a row of junk costs an attempt too"] call TEST_fnc_assert;
["pick", _term, 5] call PMCI_fnc_terminalModel;
["pick", _term, 5] call PMCI_fnc_terminalModel;
[(_term get "removed") isEqualTo [1] && {((_term get "log") select 2) isEqualTo ["dud", "1719"]} && {count (_term get "log") == 3},
    "a bracket removes a dud (not the answer, not a tried code), once"] call TEST_fnc_assert;
["pick", _term, 2] call PMCI_fnc_terminalModel;
[(_term get "left") == 2 && {count (_term get "log") == 3}, "a removed dud can no longer be tried"] call TEST_fnc_assert;
["pick", _term, 4] call PMCI_fnc_terminalModel;
["pick", _term, 6] call PMCI_fnc_terminalModel;
[(_term get "left") == 4 && {((_term get "log") select 4) isEqualTo ["reset"]}, "the last bracket restores the attempts"] call TEST_fnc_assert;
["pick", _term, 3] call PMCI_fnc_terminalModel;
[(_term get "status") == "success" && {(_term get "quality") == 1}, "the right code opens the lock"] call TEST_fnc_assert;
private _locked = call TEST_fnc_term;
{["pick", _locked, _x] call PMCI_fnc_terminalModel} forEach [1, 2, 4, 0];
[(_locked get "status") == "fail" && {(_locked get "left") == 0}, "the last attempt used fails"] call TEST_fnc_assert;
private _second = call TEST_fnc_term;
{["pick", _second, _x] call PMCI_fnc_terminalModel} forEach [1, 3];
[(_second get "status") == "success" && {abs ((_second get "quality") - 3 / 4) < 0.001}, "quality is the share of attempts left"] call TEST_fnc_assert;
private _dump = [5, 9, 2] call PMCI_fnc_terminalDump;
_dump params ["_codes", "_answer", "_rows", "_effects", "_texts"];
private _like = true;
{
    private _code = _x;
    if (count _code != 5 || {(toArray _code) findIf {_x < 48 || {_x > 57}} >= 0}) then {_like = false};
} forEach _codes;
private _junkDigits = false;
{
    _x params ["_address", "_before", "_middle", "_after"];
    if (count (_before + _middle + _after) != 14 || {count _address != 6} || {(toArray (_before + _after)) findIf {_x >= 48 && {_x <= 57}} >= 0}) then {_junkDigits = true};
} forEach _texts;
[count _codes == 9 && {_like} && {count (_codes arrayIntersect _codes) == 9} && {(_codes select _answer) isEqualType ""}
    && {count _rows == 16} && {({(_x select 0) == "code"} count _rows) == 9} && {({(_x select 0) == "bracket"} count _rows) == 2}
    && {_effects isEqualTo ["dud", "reset"]} && {!_junkDigits} && {((_texts select 0) select 0) == "0xF4A0"}
    && {((_texts select (_rows findIf {(_x select 0) == "code" && {(_x select 1) == _answer}})) select 2) == (_codes select _answer)},
    "the dump: different codes of the lock's length, 16 rows of 14 junk characters without digits, the codes and brackets in them"] call TEST_fnc_assert;
[(([4, 1, 1] call PMCI_fnc_terminalDump) select 3) isEqualTo ["dud"] && {[["1234"] call PMCI_fnc_codeValid, ["123456"] call PMCI_fnc_codeValid, ["123"] call PMCI_fnc_codeValid,
    ["1234567"] call PMCI_fnc_codeValid, ["12a4"] call PMCI_fnc_codeValid] isEqualTo [true, true, false, false, false]},
    "a single bracket removes a dud; a code has 4 to 6 digits"] call TEST_fnc_assert;

// --- Locking a box (server) ---------------------------------------------------------------------------
call TEST_fnc_fresh;
TEST_messages = [];
TEST_box = "Box_NATO_Wps_F" createVehicle [2, 0, 0];
TEST_box setPos [2, 0, 0];
TEST_lockMessages = {params ["_fn"]; TEST_messages select {((_x select 1) select 0) == _fn}};
PMCI_lockKey2 = " pmc_key_red ";
[(call PMCI_fnc_lockKeys) isEqualTo ["", "pmc_key_red", "", "", ""], "the five key slots come from CBA, trimmed"] call TEST_fnc_assert;
[TEST_medic, TEST_box, "classic", 1, "pmc_key_red", ""] call PMCI_fnc_lockSet;
[(TEST_box getVariable ["PMCI_lock", []]) isEqualTo [] && {TEST_messages isEqualTo []}, "only a Zeus can lock a box"] call TEST_fnc_assert;
TEST_medic setVariable ["TEST_curator", TEST_ai];
[TEST_medic, TEST_box, "classic", 2, "pmc_key_red", "1234"] call PMCI_fnc_lockSet;
private _apply = "PMCI_fnc_lockApply" call TEST_lockMessages;
[(TEST_box getVariable ["PMCI_lock", []]) isEqualTo ["classic", 2, "pmc_key_red", 0] && {(TEST_box getVariable ["PMCI_lockCode", "?"]) == ""}
    && {count _apply == 1} && {(_apply select 0) isEqualTo [[TEST_box, ["classic", 2, "pmc_key_red", 0]], ["PMCI_fnc_lockApply", 0, TEST_box]]},
    "a Zeus locks the box: every machine, players joining later too, gets the lock (a classic lock keeps no code)"] call TEST_fnc_assert;
TEST_messages = [];
[TEST_medic, TEST_box, "code", 1, "pmc_key_red", "12a4"] call PMCI_fnc_lockSet;
[(TEST_box getVariable ["PMCI_lock", []]) isEqualTo ["classic", 2, "pmc_key_red", 0] && {((("PMCI_fnc_lockNotify" call TEST_lockMessages) select 0) select 0) isEqualTo ["STR_PMCI_LOCK_ERR_CODE"]},
    "a code that is not 4-6 digits is refused"] call TEST_fnc_assert;
[TEST_medic, TEST_box, "safe", 0, "pmc_key_red", "048213"] call PMCI_fnc_lockSet;
[(TEST_box getVariable ["PMCI_lock", []]) isEqualTo ["safe", 0, "", 6] && {(TEST_box getVariable ["PMCI_lockCode", ""]) == "048213"},
    "a safe keeps its code on the server; players see only its length"] call TEST_fnc_assert;
[TEST_box, ["safe", 0, "", 6]] call PMCI_fnc_lockApply;
private _shut = TEST_box getVariable ["TEST_locked", false];
TEST_isRemoteExecuted = true;
TEST_remoteOwner = 5;
[TEST_box, []] call PMCI_fnc_lockApply;
TEST_isRemoteExecuted = false;
TEST_remoteOwner = 2;
[_shut && {TEST_box getVariable ["TEST_locked", false]}, "the inventory is locked; a client cannot unlock it for others"] call TEST_fnc_assert;

// --- Opening a box ------------------------------------------------------------------------------------
TEST_messages = [];
[TEST_medic, TEST_box, "code", "048210"] call PMCI_fnc_lockOpen;
[TEST_medic, TEST_box, "key"] call PMCI_fnc_lockOpen;
private _said = ("PMCI_fnc_lockNotify" call TEST_lockMessages) apply {(_x select 0) select 0};
[_said isEqualTo ["STR_PMCI_LOCK_WRONG_CODE", "STR_PMCI_LOCK_NO_KEY"] && {(TEST_box getVariable ["PMCI_lock", []]) isNotEqualTo []}, "a wrong code or no key leaves the safe locked"] call TEST_fnc_assert;
TEST_isRemoteExecuted = true;
TEST_remoteOwner = 7;
TEST_messages = [];
[TEST_medic, TEST_box, "code", "048213"] call PMCI_fnc_lockOpen;
TEST_isRemoteExecuted = false;
TEST_remoteOwner = 2;
[TEST_messages isEqualTo [] && {(TEST_box getVariable ["PMCI_lock", []]) isNotEqualTo []}, "a request sent for another player's unit is ignored"] call TEST_fnc_assert;
player setPos [9, 0, 0];
[TEST_medic, TEST_box, "code", "048213"] call PMCI_fnc_lockOpen;
player setPos [0, 0, 0];
[(TEST_box getVariable ["PMCI_lock", []]) isNotEqualTo [], "the code is entered at the box only"] call TEST_fnc_assert;
[TEST_medic, TEST_box, "code", "048213"] call PMCI_fnc_lockOpen;
_apply = "PMCI_fnc_lockApply" call TEST_lockMessages;
[(TEST_box getVariable ["PMCI_lock", []]) isEqualTo [] && {(_apply select 0) isEqualTo [[TEST_box, []], ["PMCI_fnc_lockApply", 0, TEST_box]]}
    && {((("PMCI_fnc_lockNotify" call TEST_lockMessages) select 0) select 0) isEqualTo ["STR_PMCI_LOCK_OPENED"]},
    "the right code opens the safe for good, for everyone"] call TEST_fnc_assert;
[TEST_medic, TEST_box, "classic", 1, "PMC_Key_Red", ""] call PMCI_fnc_lockSet;
TEST_medic setVariable ["TEST_inv", ["pmc_key_red"]];
[TEST_medic, TEST_box, "key"] call PMCI_fnc_lockOpen;
[(TEST_box getVariable ["PMCI_lock", []]) isEqualTo [], "the key set for a classic lock opens it (class names in any case)"] call TEST_fnc_assert;
TEST_medic setVariable ["TEST_inv", []];
[TEST_medic, TEST_box, "classic", 1, "", ""] call PMCI_fnc_lockSet;
[TEST_medic, TEST_box, "none", 1, "", ""] call PMCI_fnc_lockSet;
[(TEST_box getVariable ["PMCI_lock", []]) isEqualTo [], "Zeus can take the lock off again"] call TEST_fnc_assert;

// --- Hacking a box ------------------------------------------------------------------------------------
call TEST_fnc_fresh;
TEST_messages = [];
PMCI_terminalItem = "pmc_hacker";
[TEST_medic, TEST_box, "code", 2, "", "4821"] call PMCI_fnc_lockSet;
[TEST_box, TEST_box getVariable "PMCI_lock"] call PMCI_fnc_lockApply;
[TEST_medic, TEST_box] call PMCI_fnc_lockHack;
[isNil "PMCI_board" && {("PMCI_fnc_lockOpen" call TEST_lockMessages) isEqualTo []}, "without the device the hack does not start"] call TEST_fnc_assert;
TEST_medic setVariable ["TEST_inv", ["PMC_Hacker"]];
[TEST_medic, TEST_box] call PMCI_fnc_lockHack;
private _term = PMCI_board get "state";
[(PMCI_board get "game") == "terminal" && {(PMCI_board get "kind") == "lock"} && {(PMCI_board get "ease") == 0.75} && {count ((_term get "codes") select 0) == 4}
    && {count (_term get "codes") == round (8 / 0.75)} && {(_term get "effects") isEqualTo ["dud"]} && {count (_term get "texts") == 16}
    && {(("PMCI_fnc_lockOpen" call TEST_lockMessages) select 0) isEqualTo [[TEST_medic, TEST_box, "begin"], ["PMCI_fnc_lockOpen", 2]]},
    "with the device: the server hears the hack began; a hard code lock gives 4-digit codes, more candidates, one bracket"] call TEST_fnc_assert;
TEST_messages = [];
private _answerRow = (_term get "rows") findIf {(_x select 0) == "code" && {(_x select 1) == (_term get "answer")}};
["select", _answerRow] call PMCI_fnc_boardEvent;
["keyDown", [0, 57, false, false, false]] call PMCI_fnc_boardEvent;
call PMCI_fnc_boardTick;
TEST_realTime = TEST_realTime + 1;
call PMCI_fnc_boardTick;
private _shown = !isNil "PMCI_board" && {("PMCI_fnc_lockOpen" call TEST_lockMessages) isEqualTo []};
TEST_realTime = TEST_realTime + 1;
call PMCI_fnc_boardTick;
[_shown && {isNil "PMCI_board"} && {(("PMCI_fnc_lockOpen" call TEST_lockMessages) select 0) isEqualTo [[TEST_medic, TEST_box, "hack"], ["PMCI_fnc_lockOpen", 2]]},
    "the right row with the press key wins: the result stays on screen 1.5 s, then the server is asked to open the box"] call TEST_fnc_assert;
// The server side of that: the hack must have begun at least 0.5 s before, with the device.
TEST_messages = [];
[TEST_medic, TEST_box, "begin"] call PMCI_fnc_lockOpen;
[TEST_medic, TEST_box, "hack"] call PMCI_fnc_lockOpen;
private _early = (TEST_box getVariable ["PMCI_lock", []]) isNotEqualTo [];
TEST_realTime = TEST_realTime + 3;
TEST_medic setVariable ["TEST_inv", []];
[TEST_medic, TEST_box, "hack"] call PMCI_fnc_lockOpen;
private _noTool = (TEST_box getVariable ["PMCI_lock", []]) isNotEqualTo [];
TEST_medic setVariable ["TEST_inv", ["pmc_hacker"]];
[TEST_medic, TEST_ai, "hack"] call PMCI_fnc_lockOpen;
[TEST_medic, TEST_box, "hack"] call PMCI_fnc_lockOpen;
[_early && {_noTool} && {(TEST_box getVariable ["PMCI_lock", []]) isEqualTo []}, "the server opens a hacked box only some time after the hack began, with the device"] call TEST_fnc_assert;
TEST_medic setVariable ["TEST_inv", []];
PMCI_terminalItem = "";
// A double click picks a row too; a box opened by someone else ends the game.
[TEST_medic, TEST_box, "code", 0, "", "48213"] call PMCI_fnc_lockSet;
[TEST_medic, TEST_box] call PMCI_fnc_lockHack;
_term = PMCI_board get "state";
private _junkRow = (_term get "rows") findIf {(_x select 0) == "junk"};
["pick", _junkRow] call PMCI_fnc_boardEvent;
[(PMCI_board get "ease") == 1.35 && {count ((_term get "codes") select 0) == 5} && {((_term get "log") select 0) isEqualTo ["junk"]}
    && {(_term get "effects") isEqualTo ["dud", "dud", "reset"]}, "an easy lock gives three brackets; a double click picks a row"] call TEST_fnc_assert;
TEST_box setVariable ["PMCI_lock", []];
TEST_messages = [];
call PMCI_fnc_boardTick;
[isNil "PMCI_board" && {("PMCI_fnc_lockOpen" call TEST_lockMessages) isEqualTo []}, "a box opened meanwhile ends the game without a request"] call TEST_fnc_assert;

// Lock picking on the board: picks counted and used up as they break.
PMCI_lockpickItem = "pmc_lockpick";
TEST_medic setVariable ["TEST_inv", ["pmc_lockpick", "pmc_lockpick", "ACE_fieldDressing"]];
[TEST_medic, TEST_box, "classic", 1, "", ""] call PMCI_fnc_lockSet;
[TEST_medic, TEST_box] call PMCI_fnc_lockHack;
private _pick = PMCI_board get "state";
_pick set ["sweets", [150]];
TEST_mouse = [512, 100];
["keyDown", [0, 57, false, false, false]] call PMCI_fnc_boardEvent;
for "_i" from 1 to 40 do {TEST_realTime = TEST_realTime + 0.05; call PMCI_fnc_boardTick};
[(_pick get "picks") == 1 && {(_pick get "broken") == 1} && {(TEST_medic getVariable ["TEST_inv", []]) isEqualTo ["pmc_lockpick", "ACE_fieldDressing"]} && {!isNil "PMCI_board"},
    "two picks carried; one breaks and is gone from the inventory"] call TEST_fnc_assert;
["keyDown", [0, 57, false, false, false]] call PMCI_fnc_boardEvent;
[!(_pick get "turning"), "the held key's auto-repeat does not turn the plug again after a pick broke"] call TEST_fnc_assert;
["keyUp", [0, 57]] call PMCI_fnc_boardEvent;
["keyDown", [0, 57, false, false, false]] call PMCI_fnc_boardEvent;
private _held = _pick get "turning";
["keyUp", [0, 57]] call PMCI_fnc_boardEvent;
["scrubDown"] call PMCI_fnc_boardEvent;
private _mouseHeld = _pick get "turning";
["scrubUp"] call PMCI_fnc_boardEvent;
[_held && {_mouseHeld} && {!(_pick get "turning")}, "the plug turns with the press key or the mouse held on the lock"] call TEST_fnc_assert;
TEST_mouse = [512 + 100 * cos 150, 300 - 100 * sin 150];
call PMCI_fnc_boardTick;
TEST_messages = [];
["keyDown", [0, 57, false, false, false]] call PMCI_fnc_boardEvent;
["keyUp", [0, 57]] call PMCI_fnc_boardEvent;
["keyDown", [0, 57, false, false, false]] call PMCI_fnc_boardEvent;
for "_i" from 1 to 80 do {TEST_realTime = TEST_realTime + 0.05; call PMCI_fnc_boardTick};
[isNil "PMCI_board" && {count ("PMCI_fnc_lockOpen" call TEST_lockMessages) == 1} && {(PMCI_lastResult select 2) == 0.8},
    "at the spot the lock opens; quality 80% after one broken pick"] call TEST_fnc_assert;
TEST_medic setVariable ["TEST_inv", []];
[TEST_medic, TEST_box] call PMCI_fnc_lockHack;
[isNil "PMCI_board", "no lockpick left: picking does not start"] call TEST_fnc_assert;
[TEST_medic, TEST_box, "classic", 2, "", ""] call PMCI_fnc_lockSet;
TEST_medic setVariable ["TEST_inv", ["pmc_lockpick"]];
[TEST_medic, TEST_box] call PMCI_fnc_lockHack;
private _oneShort = isNil "PMCI_board";
TEST_medic setVariable ["TEST_inv", ["pmc_lockpick", "pmc_lockpick"]];
[TEST_medic, TEST_box] call PMCI_fnc_lockHack;
private _hardPick = PMCI_board get "state";
(_hardPick get "sweets") params ["_s1", "_s2"];
[_oneShort && {count (_hardPick get "sweets") == 2} && {abs (_s1 - _s2) >= 40} && {_s2 >= 15 && {_s2 <= 165}} && {(_hardPick get "picks") == 2}
    && {abs ((_hardPick get "speed") - 0.6 * 0.75) < 0.001},
    "a hard classic lock takes two picks, needs two lockpicks, spots well apart; the plug turns slower"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;
TEST_medic setVariable ["TEST_inv", []];
PMCI_lockpickItem = "";
// Safe on the board: dragging the dial, setting a number with the hold button.
[TEST_medic, TEST_box, "safe", 1, "", "1234"] call PMCI_fnc_lockSet;
[TEST_medic, TEST_box] call PMCI_fnc_lockHack;
private _safeState = PMCI_board get "state";
private _first = (_safeState get "numbers") select 0;
TEST_mouse = [100, 200];
["scrubDown"] call PMCI_fnc_boardEvent;
call PMCI_fnc_boardTick;
TEST_mouse = [100 + _first / 0.06, 200];
call PMCI_fnc_boardTick;
["scrubUp"] call PMCI_fnc_boardEvent;
["holdDown"] call PMCI_fnc_boardEvent;
[(PMCI_board get "game") == "safe" && {count (_safeState get "numbers") == 4} && {(_safeState get "next") == 1} && {(_safeState get "mistakes") == 0}
    && {((_safeState get "numbers") findIf {_x < 0 || {_x > 99}}) < 0},
    "a normal safe has 4 numbers; dragging the mouse to the first and setting it counts"] call TEST_fnc_assert;
[false] call PMCI_fnc_finish;

// Pictures of the lock games: plug, pick and dial turn.
private _pickMarks = ["lockpick", ["init", nil, [[60], 5, 45, 1.2, 1, 3, 90]] call PMCI_fnc_lockpickModel] call PMCI_fnc_boardMarks;
private _dialState = ["init", nil, [[30], 2, 12, 1, 90, 1]] call PMCI_fnc_safeModel;
_dialState set ["dial", 25];
private _dialMarks = ["safe", _dialState] call PMCI_fnc_boardMarks;
[(["lockpick", _pick] call TEST_look) isEqualTo (["lock_scene", "", "", "", "", "", "", "", "", "", "", "lock_plug", "", "", "lock_pick"] apply {_x call TEST_tex} call TEST_full)
    && {(["terminal", _term] call TEST_look) isEqualTo ([("terminal_scene" call TEST_tex)] call TEST_full)}
    && {((["safe", _dialState] call TEST_look) select 5) == ("safe_dial" call TEST_tex)}
    && {(_pickMarks select 0) isEqualTo [11, [400, 188, 224, 224], 1, 0]} && {(_pickMarks select 1) isEqualTo [14, [288, 76, 448, 448], 1, 0]}
    && {abs (((_dialMarks select 0) select 3) - 90) < 0.001},
    "the lock games show their scenes; the pick points up at the start, the dial turns 3.6 degrees per number"] call TEST_fnc_assert;

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];
