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
    ["Board", "boardOpen"], ["Board", "boardEvent"], ["Board", "boardTick"], ["Board", "boardValid"], ["Board", "finish"], ["Board", "boardLook"]];
PMCI_fnc_boardDraw = {};
PMCI_fnc_boardLayout = {};

// ACE stand-ins: record every call.
TEST_calls = [];
{
    missionNamespace setVariable [_x, compile format ["TEST_calls pushBack ['%1', +_this]; 0", _x]];
} forEach ["ace_medical_treatment_fnc_bandage", "ace_medical_treatment_fnc_tourniquet", "ace_medical_treatment_fnc_cprSuccess",
    "ace_medical_treatment_fnc_cprFailure", "ace_repair_fnc_doReplaceWheel", "ace_repair_fnc_doRemoveWheel", "ace_common_fnc_claim",
    "ace_common_fnc_addToInventory", "ace_common_fnc_adjustMagazineAmmo", "CBA_fnc_removePerFrameHandler"];
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
[count TEST_settings == 13 && {"PMCI_enable_wheel" in _names} && {(TEST_settings findIf {(_x select 2) != 1}) < 0},
    "settings: difficulty, preparation bar, and for each game on/off plus its tuning, forced by the server"] call TEST_fnc_assert;
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
    ([TEST_medic, objNull, "HitLFWheel", "RemoveWheel"] call PMCI_fnc_repairTime) == 10} && {
    ([TEST_ai, objNull, "HitLFWheel", "ReplaceWheel"] call PMCI_fnc_repairTime) == 10},
    "wheel change: preparation bar for the player; removing a wheel and AI keep ACE's time"] call TEST_fnc_assert;

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
[count ("ace_repair_fnc_doReplaceWheel" call TEST_called) == 1 && {isNil "PMCI_board"}, "removing a wheel keeps ACE's behaviour"] call TEST_fnc_assert;

// --- Board pictures ---------------------------------------------------------------------------------
// Layers: scene, hands, beat, windlass, gauze, wheel, nut 0-4.
TEST_tex = {if (_this == "") then {""} else {format ["\pmc_interactions\data\%1_ca.paa", _this]}};
TEST_look = {params ["_game", "_state", ["_depth", 0], ["_hint", false]]; [_game, _state, _depth, _hint] call PMCI_fnc_boardLook};
TEST_none = ["", "", "", "", "", "", "", "", "", "", ""];
private _c = ["init", nil, [15, 0.05, 0.5]] call PMCI_fnc_cprModel;
private _look = ["cpr", _c, 1] call TEST_look;
[_look isEqualTo (["cpr_scene", "cpr_hands_down", "cpr_beat_on", "", "", "", "", "", "", "", ""] apply {_x call TEST_tex}),
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
[(["wheel", _w] call TEST_look) isEqualTo (["", "", "", "", "", "wheel_old", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight"] apply {_x call TEST_tex}),
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
[(_w get "status") == "success" && {(["wheel", _w] call TEST_look) isEqualTo (["", "", "", "", "", "wheel_new", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight", "wheel_nut_tight"] apply {_x call TEST_tex})},
    "a finished change shows the new wheel with all nuts tight"] call TEST_fnc_assert;
[(["unknown", _w] call TEST_look) isEqualTo TEST_none, "an unknown game shows no pictures"] call TEST_fnc_assert;

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

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];
