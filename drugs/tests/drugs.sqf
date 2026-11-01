// PMC Drugs checks in SQF-VM: the Stim1f tables, the duty combination, debt, payback with
// its floor, distributed muscle damage, overdose, thirst and the Zeus muscle module's
// network handlers. ACE, CBA and the window are stand-ins; nothing here runs ACE itself.
call compile preprocessFileLineNumbers "tests/vm_compat.sqf";
TEST_count = 0;
TEST_fnc_assert = {
    params ["_ok", "_label"];
    if (!_ok) then {diag_log ("TEST_FAIL: " + _label); exitcode__ 1};
    TEST_count = TEST_count + 1;
    diag_log ("TEST_PASS: " + _label);
};
TEST_near = {params ["_a", "_b", ["_eps", 0.001]]; abs (_a - _b) <= _eps};
{
    missionNamespace setVariable ["PMCD_fnc_" + (_x select 1), (format ["pmc_drugs/%1/fn_%2.sqf", _x select 0, _x select 1]) call TEST_fnc_load];
} forEach [["Init", "settings"], ["Init", "init"], ["Core", "state"], ["Core", "unitLoad"], ["Core", "loadClass"], ["Core", "stimDose"],
    ["Core", "effects"], ["Core", "duty"], ["Core", "step"], ["Core", "tick"], ["Core", "takeStim"], ["Core", "overdose"], ["Core", "thirst"],
    ["Core", "canTake"], ["Core", "notify"], ["Zeus", "muscleCheck"], ["Zeus", "muscleSet"]];

// Stand-ins: record every call.
TEST_calls = [];
{
    missionNamespace setVariable [_x, compile format ["TEST_calls pushBack ['%1', +_this]; 0", _x]];
} forEach ["CBA_fnc_targetEvent", "CBA_fnc_addEventHandler", "CBA_fnc_addPerFrameHandler", "ace_advanced_fatigue_fnc_addDutyFactor",
    "ace_field_rations_fnc_addStatusModifier", "ace_interact_menu_fnc_addActionToClass", "ace_common_fnc_displayTextStructured",
    "ace_medical_status_fnc_addMedicationAdjustment", "CBA_fnc_waitAndExecute"];
ace_interact_menu_fnc_createAction = {TEST_calls pushBack ["createAction", +_this]; +_this};
TEST_called = {params ["_name"]; TEST_calls select {(_x select 0) == _name}};
TEST_settings = [];
CBA_fnc_addSetting = {
    params ["_name", "_type", "_title", "_category", "_value", ["_global", 0]];
    TEST_settings pushBack [_name, _type, _value, _global];
    missionNamespace setVariable [_name, if (_type == "SLIDER") then {_value select 2} else {_value}];
};
TEST_hasInterface = true;
ACE_player = player;
CBA_missionTime = 0;
ace_medical_enabled = true;
ace_advanced_fatigue_anWattsPerATP = 8.8;
TEST_fresh = {
    player setVariable ["PMCD_state", nil];
    player setVariable ["ace_movement_totalLoad", (40 + 3.5) * 22.046];
    player setVariable ["TEST_inv", ["PMCD_Stim1f", "PMCD_Stim1f", "PMCD_Stim1f"]];
    ace_advanced_fatigue_anReserve = 500;
    ace_advanced_fatigue_muscleDamage = 0;
    PMCD_lastTick = 0;
    CBA_missionTime = 0;
    TEST_calls = [];
};
// One second of the loop at a time, as the per-frame handler runs it.
TEST_run = {
    params ["_seconds"];
    for "_i" from 1 to _seconds do {CBA_missionTime = CBA_missionTime + 1; call PMCD_fnc_tick};
};

// --- Settings and start-up ------------------------------------------------------------------
call PMCD_fnc_settings;
private _floorSetting = TEST_settings select {(_x select 0) == "PMCD_debtPaybackFloor"};
[count TEST_settings == 31 && {(TEST_settings findIf {(_x select 3) != 1}) < 0} && {_floorSetting isEqualTo [["PMCD_debtPaybackFloor", "SLIDER", [0.3, 0.5, 0.4, 2], 1]]}
    && {PMCD_debtPaybackFloor == 0.4} && {PMCD_stimDuty == 0.5} && {PMCD_stimTime40 == 12} && {PMCD_stimDamage2_70 == 0.35} && {PMCD_stimFillAN}
    && {PMCD_overdosePulse == 200} && {PMCD_paybackStim == 4} && {PMCD_debtBaseWork == 400},
    "31 CBA settings, all forced by the server, defaults of the spec (payback floor 0.30-0.50, default 0.40)"] call TEST_fnc_assert;
call PMCD_fnc_init;
private _duty = ("ace_advanced_fatigue_fnc_addDutyFactor" call TEST_called) select 0 select 1;
[count ("CBA_fnc_addEventHandler" call TEST_called) == 3 && {count ("ace_advanced_fatigue_fnc_addDutyFactor" call TEST_called) == 1}
    && {(_duty select 0) == "PMCD_drugs"} && {(_duty select 1) isEqualType {}} && {count ("ace_field_rations_fnc_addStatusModifier" call TEST_called) == 1}
    && {((("ace_interact_menu_fnc_addActionToClass" call TEST_called) select 0 select 1) select [0, 3]) isEqualTo ["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"]]},
    "start-up: Zeus events, one duty factor for all drugs (code), the thirst modifier, the self-injection under Equipment"] call TEST_fnc_assert;

// --- Stim1f tables --------------------------------------------------------------------------
[([10, 30, 31, 55, 56, 90] apply {[_x] call PMCD_fnc_loadClass}) isEqualTo [0, 0, 1, 1, 2, 2], "loads go to the nearest of 20 / 40 / 70 kg"] call TEST_fnc_assert;
private _table = [];
for "_dose" from 1 to 6 do {_table pushBack ([0, 1, 2] apply {([_dose, _x] call PMCD_fnc_stimDose) select 1})};
[_table isEqualTo [[0.15, 0.2, 0.25], [0.25, 0.3, 0.35], [0.2, 0.25, 0.3], [0.15, 0.2, 0.25], [0.15, 0.2, 0.25], [0.15, 0.2, 0.25]]
    && {([0, 1, 2] apply {([1, _x] call PMCD_fnc_stimDose) select 0}) isEqualTo [840, 720, 600]},
    "Stim1f: muscle damage per dose and load as in the spec; 14 / 12 / 10 min"] call TEST_fnc_assert;
// The dose at which the cumulated damage reaches 0.85 (where ACE's own fatigue stops sprinting).
TEST_blockAt = {
    params ["_class", "_factor"];
    private _sum = 0;
    private _dose = 0;
    while {_sum < 0.85 && {_dose < 20}} do {_dose = _dose + 1; _sum = _sum + (([_dose, _class] call PMCD_fnc_stimDose) select 1) * _factor};
    _dose
};
[([0, 1, 2] apply {[_x, 1] call TEST_blockAt}) isEqualTo [5, 4, 3] && {([0, 1, 2] apply {[_x, 0.77] call TEST_blockAt}) isEqualTo [7, 5, 4]},
    "0.85 is reached at doses 5 / 4 / 3, with meldonium 7 / 5 / 4 (70 kg: 4th, as corrected)"] call TEST_fnc_assert;

// --- Duty combination (section 4) -----------------------------------------------------------
private _stim = ["stim", "dec", 0.5];
private _fen = ["fen", "dec", 0.9];
private _hemo = ["hemo", "inc", 1.3];
private _matrix = [[_stim], [_fen], [_hemo], [_stim, _hemo], [_fen, _hemo], [_stim, _fen, _hemo], []] apply {[_x] call PMCD_fnc_duty};
[[_matrix, [0.5, 0.9, 1.3, 0.65, 1.17, 0.65, 1]] call {
    params ["_got", "_want"];
    private _ok = true;
    {if !([_x, _want select _forEachIndex] call TEST_near) then {_ok = false}} forEach _got;
    _ok
}, "duty: the strongest decreasing factor times the strongest increasing one (matrix of the spec)"] call TEST_fnc_assert;

// --- Debt -----------------------------------------------------------------------------------
TEST_debtOver = {
    params ["_effects", "_seconds"];
    private _state = createHashMapFromArray [["stimUntil", -1], ["stimDoses", 0], ["stimRate", 0], ["debtStim", 0], ["debtFen", 0]];
    for "_i" from 1 to _seconds do {[_state, 1, 0, _effects, 2300, 8.8, 0.4] call PMCD_fnc_step};
    _state
};
private _plain = [[_stim], 720] call TEST_debtOver;
private _boosted = [[_stim, _hemo], 720] call TEST_debtOver;
private _cognitive = [[_fen], 3600] call TEST_debtOver;
private _masked = [[_stim, _fen], 60] call TEST_debtOver;
[[_plain get "debtStim", 8181.8, 1] call TEST_near && {[_boosted get "debtStim", 10636.4, 1] call TEST_near}
    && {[_cognitive get "debtFen", 8181.8, 1] call TEST_near} && {(_masked get "debtFen") == 0} && {[_masked get "debtStim", 681.8, 0.1] call TEST_near},
    "debt calibration: 8 180 per Stim1f cycle, 10 636 with a hemostatic, the same per Fentropil hour; Fentropil under Stim1f runs none up"] call TEST_fnc_assert;

// --- Payback --------------------------------------------------------------------------------
private _pay = createHashMapFromArray [["stimUntil", -1], ["stimDoses", 0], ["stimRate", 0], ["debtStim", 100], ["debtFen", 50]];
// (anWattsPerATP 0: no new debt in this step, only the hold is checked)
private _held = ([_pay, 1, 0, [_stim], 2000, 0, 0.4] call PMCD_fnc_step) select 1;
private _first = ([_pay, 1, 0, [], 2000, 8.8, 0.4] call PMCD_fnc_step) select 1;
private _afterFirst = [_pay get "debtStim", _pay get "debtFen"];
_pay set ["debtStim", 1];
[_pay, 1, 0, [], 2000, 8.8, 0.4] call PMCD_fnc_step;
private _fenStep = ([_pay, 1, 0, [], 2000, 8.8, 0.4] call PMCD_fnc_step) select 1;
[_held == 2000 && {(_pay get "debtStim") == 0} && {_first == 1996} && {_afterFirst isEqualTo [96, 50]} && {_fenStep == 1997.5} && {(_pay get "debtFen") == 47.5},
    "payback: none while Stim1f works; then 4.0 mmol/s from the AN reserve, Stim1f debt first, Fentropil's after at 2.5"] call TEST_fnc_assert;
_pay set ["debtFen", 50];
private _floor = ([_pay, 1, 0, [], 921, 8.8, 0.4] call PMCD_fnc_step) select 1;
private _below = ([_pay, 1, 0, [], 900, 8.8, 0.4] call PMCD_fnc_step) select 1;
private _paused = _pay get "debtFen";
private _fenOn = ([_pay, 1, 0, [_fen], 2000, 8.8, 0.4] call PMCD_fnc_step) select 1;
[_floor == 920 && {_below == 900} && {_paused == 47.5} && {_fenOn == 2000},
    "the floor: payback never takes the reserve under 40% (920 mmol) and waits below it; none while Fentropil works"] call TEST_fnc_assert;

// --- Taking Stim1f on the loop ---------------------------------------------------------------
call TEST_fresh;
[player] call PMCD_fnc_takeStim;
private _state = player getVariable "PMCD_state";
private _filled = ace_advanced_fatigue_anReserve;
[_filled == 2300 && {(_state get "stimUntil") == 720} && {(_state get "stimDoses") == 1} && {count (player getVariable ["TEST_inv", []]) == 2}
    && {[_state get "stimRate", 0.2 / 720, 1e-9] call TEST_near},
    "a first dose at 40 kg: one injector used, the AN reserve filled, 12 min of Stim1f, 0.20 muscle damage to come"] call TEST_fnc_assert;
call PMCD_fnc_init;
private _factor = ((("ace_advanced_fatigue_fnc_addDutyFactor" call TEST_called) select 0) select 1) select 1;
[(player call _factor) == 0.5, "ACE's fatigue gets duty 0.5 from the drug factor while Stim1f works"] call TEST_fnc_assert;
TEST_calls = [];
[720] call TEST_run;
private _debtAfter = _state get "debtStim";
// SQF numbers are 32-bit floats: 720 small steps add up to 0.2 within 1e-4.
[[ace_advanced_fatigue_muscleDamage, 0.2, 1e-4] call TEST_near && {[_debtAfter, 8181.8, 1] call TEST_near} && {(player call _factor) == 1},
    "over the 12 min the damage comes in evenly (0.20 in all) and the debt runs up; then duty is back to 1"] call TEST_fnc_assert;
ace_advanced_fatigue_anReserve = 2000;
[10] call TEST_run;
[[_state get "debtStim", _debtAfter - 40, 0.001] call TEST_near && {ace_advanced_fatigue_anReserve == 1960},
    "after the phase the debt is paid from the AN reserve, 4 mmol per second"] call TEST_fnc_assert;
[player] call PMCD_fnc_takeStim;
[(_state get "stimDoses") == 2 && {ace_advanced_fatigue_anReserve == 2300} && {[_state get "debtStim", _debtAfter - 40, 0.001] call TEST_near}
    && {[_state get "stimRate", 0.3 / 720, 1e-9] call TEST_near},
    "a dose during payback: allowed, the reserve refilled, the old debt kept, the second dose's damage (0.30) ahead"] call TEST_fnc_assert;
_state set ["meldTest", true];
private _beforeMeld = ace_advanced_fatigue_muscleDamage;
private _meldStep = ([_state, 10, CBA_missionTime + 1, [_stim, ["meld", "meta", 0.77]], 2300, 8.8, 0.4] call PMCD_fnc_step) select 0;
[[_meldStep, 0.3 / 720 * 10 * 0.77, 1e-9] call TEST_near, "under meldonium each tick of Stim1f damage counts x0.77"] call TEST_fnc_assert;

// --- Overdose -------------------------------------------------------------------------------
private _phaseEnd = _state get "stimUntil";
TEST_calls = [];
[player] call PMCD_fnc_takeStim;
private _adjust = ("ace_medical_status_fnc_addMedicationAdjustment" call TEST_called) select 0 select 1;
[count _adjust == 8 && {(_adjust select 0) isEqualTo player} && {(_adjust select 1) == "PMCD_Stim1f"} && {(_adjust select 2) >= 30 && {(_adjust select 2) <= 50}}
    && {(_adjust select 4) == 200} && {(_state get "stimUntil") == _phaseEnd} && {(_state get "stimDoses") == 2} && {count (player getVariable ["TEST_inv", []]) == 0},
    "a dose during the active phase is an overdose: ACE medication +200 bpm in 30-50 s; the phase, doses and damage stay as they were"] call TEST_fnc_assert;
[!([player] call PMCD_fnc_takeStim), "without an injector nothing is taken"] call TEST_fnc_assert;

// --- Thirst ---------------------------------------------------------------------------------
CBA_missionTime = _phaseEnd - 1;
private _currentWork = 1.5;
private _thirsty = [player] call PMCD_fnc_thirst;
CBA_missionTime = _phaseEnd;
private _calm = [player] call PMCD_fnc_thirst;
[_thirsty == 3 && {_calm == 0}, "an active Stim1f triples thirst (twice the base work on top); none after it"] call TEST_fnc_assert;

// --- CBA settings change the drug --------------------------------------------------------------
PMCD_stimTime40 = 5;
PMCD_stimDamage1_40 = 0.5;
PMCD_stimDamage4_70 = 0.05;
PMCD_loadLight = 45;
private _tuned = [[1, 1] call PMCD_fnc_stimDose, [9, 2] call PMCD_fnc_stimDose, [40] call PMCD_fnc_loadClass];
PMCD_stimDuty = 0.3;
private _dutyTuned = [[createHashMapFromArray [["stimUntil", 10]], 0] call PMCD_fnc_effects] call PMCD_fnc_duty;
PMCD_debtBaseWork = 800;
PMCD_debtFactor = 1;
PMCD_paybackStim = 10;
private _tunedDebt = createHashMapFromArray [["stimUntil", -1], ["stimDoses", 0], ["stimRate", 0], ["debtStim", 0], ["debtFen", 0]];
[_tunedDebt, 1, 0, [["stim", "dec", 0.3]], 2300, 8.8, 0.4] call PMCD_fnc_step;
private _tunedAccrued = _tunedDebt get "debtStim";
private _tunedPay = ([_tunedDebt, 1, 0, [], 2000, 8.8, 0.4] call PMCD_fnc_step) select 1;
PMCD_stimThirst = 5;
player setVariable ["PMCD_state", createHashMapFromArray [["stimUntil", 1e9]]];
private _currentWork = 1;
private _tunedThirst = [player] call PMCD_fnc_thirst;
PMCD_overdosePulse = 250;
PMCD_overdoseRampMin = 40;
PMCD_overdoseRampMax = 40;
TEST_calls = [];
[player] call PMCD_fnc_overdose;
private _tunedOd = ("ace_medical_status_fnc_addMedicationAdjustment" call TEST_called) select 0 select 1;
[_tuned isEqualTo [[300, 0.5], [600, 0.05], 0] && {[_dutyTuned, 0.3] call TEST_near} && {[_tunedAccrued, 800 * 0.7 / 8.8, 0.01] call TEST_near}
    && {_tunedPay == 1990} && {_tunedThirst == 4} && {(_tunedOd select 2) == 40} && {(_tunedOd select 4) == 250},
    "CBA settings change durations, damage, load columns, duty, debt and payback, thirst and the overdose"] call TEST_fnc_assert;
call PMCD_fnc_settings;

// --- Zeus module: check and set on the player's machine ----------------------------------------
call TEST_fresh;
private _zeus = "B_Soldier_F" createVehicle [5, 0, 0];
ace_advanced_fatigue_muscleDamage = 0.37;
[_zeus, player] call PMCD_fnc_muscleCheck;
private _ignored = TEST_calls isEqualTo [];
_zeus setVariable ["TEST_curator", _zeus];
[_zeus, player] call PMCD_fnc_muscleCheck;
[_ignored && {(("CBA_fnc_targetEvent" call TEST_called) select 0 select 1) isEqualTo ["PMCD_muscleShow", [player, 0.37], _zeus]},
    "check: only a Zeus gets the value, sent back to the Zeus's machine"] call TEST_fnc_assert;
TEST_calls = [];
[_zeus, player, 1.7] call PMCD_fnc_muscleSet;
private _worn = ("ace_common_fnc_displayTextStructured" call TEST_called) select 0 select 1 select 0;
[_zeus, player, -2] call PMCD_fnc_muscleSet;
private _healed = ("ace_common_fnc_displayTextStructured" call TEST_called) select 1 select 1 select 0;
[ace_advanced_fatigue_muscleDamage == 0 && {_worn == "STR_PMCD_MUSCLE_WORN"} && {_healed == "STR_PMCD_MUSCLE_RECOVERED"}
    && {(("CBA_fnc_targetEvent" call TEST_called) apply {(_x select 1) select 1}) isEqualTo [[player, 1], [player, 0]]},
    "set: clamped to 0-1, a neutral line for the player (worn / recovered), the new value back to the Zeus"] call TEST_fnc_assert;
TEST_calls = [];
[_zeus, _zeus, 0.5] call PMCD_fnc_muscleSet;
[TEST_calls isEqualTo [] && {ace_advanced_fatigue_muscleDamage == 0}, "a machine only answers for its own player"] call TEST_fnc_assert;

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];
