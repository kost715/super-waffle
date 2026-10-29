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
    ["Board", "boardMarks"], ["Board", "cprRibs"], ["Init", "events"]];
PMCI_fnc_boardDraw = {};
PMCI_fnc_boardLayout = {};

// ACE stand-ins: record every call.
TEST_calls = [];
{
    missionNamespace setVariable [_x, compile format ["TEST_calls pushBack ['%1', +_this]; 0", _x]];
} forEach ["ace_medical_treatment_fnc_bandage", "ace_medical_treatment_fnc_tourniquet", "ace_medical_treatment_fnc_cprSuccess",
    "ace_medical_treatment_fnc_cprFailure", "ace_repair_fnc_doReplaceWheel", "ace_repair_fnc_doRemoveWheel", "ace_common_fnc_claim",
    "ace_common_fnc_addToInventory", "ace_common_fnc_adjustMagazineAmmo", "CBA_fnc_removePerFrameHandler", "CBA_fnc_targetEvent",
    "ace_medical_fnc_addDamageToUnit"];
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
[count TEST_settings == 21 && {"PMCI_enable_wheel" in _names} && {"PMCI_enable_edges" in _names} && {"PMCI_ribChance" in _names}
    && {(TEST_settings findIf {(_x select 2) != 1}) < 0},
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
