// PMC Drugs checks in SQF-VM: the Stim1f weight curve and pool, the duty combination, debt
// and its payback from AE2 with the floor, overdose, thirst, CBA settings, the HUD colour
// and the Zeus muscle module's network handlers. ACE, CBA and the windows are stand-ins;
// nothing here runs ACE itself.
call compile preprocessFileLineNumbers "tests/vm_compat.sqf";
TEST_count = 0;
TEST_fnc_assert = {
    params ["_ok", "_label"];
    if (!_ok) then {diag_log ("TEST_FAIL: " + _label); exitcode__ 1};
    TEST_count = TEST_count + 1;
    diag_log ("TEST_PASS: " + _label);
};
TEST_near = {params ["_a", "_b", ["_eps", 0.001]]; abs (_a - _b) <= _eps};
TEST_allNear = {
    params ["_got", "_want", ["_eps", 0.001]];
    private _ok = count _got == count _want;
    {if (!_ok || {abs (_x - (_want select _forEachIndex)) > _eps}) then {_ok = false}} forEach _got;
    _ok
};
{
    missionNamespace setVariable ["PMCD_fnc_" + (_x select 1), (format ["pmc_drugs/%1/fn_%2.sqf", _x select 0, _x select 1]) call TEST_fnc_load];
} forEach [["Init", "settings"], ["Init", "init"], ["Core", "state"], ["Core", "unitLoad"], ["Core", "weightCoef"],
    ["Core", "effects"], ["Core", "duty"], ["Core", "step"], ["Core", "tick"], ["Core", "takeStim"], ["Core", "overdose"], ["Core", "thirst"],
    ["Core", "canTake"], ["Core", "notify"], ["Hud", "hudColor"], ["Zeus", "muscleCheck"], ["Zeus", "muscleSet"]];
// The icons and the panel are windows: not drawn here.
PMCD_fnc_hud = {};

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
ace_advanced_fatigue_anWattsPerATP = 8.77;
ace_advanced_fatigue_recoveryFactor = 1;
TEST_setLoad = {player setVariable ["ace_movement_totalLoad", (_this + 3.5) * 22.046]};
TEST_fresh = {
    player setVariable ["PMCD_state", nil];
    40 call TEST_setLoad;
    player setVariable ["TEST_inv", ["PMCD_Stim1f", "PMCD_Stim1f", "PMCD_Stim1f"]];
    ace_advanced_fatigue_anReserve = 500;
    ace_advanced_fatigue_ae2Reserve = 84000;
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
TEST_newState = {createHashMapFromArray [["stimPool", 0], ["stimDoses", 0], ["stimDamage", 0], ["overdoses", 0], ["debt", 0], ["debtStim", 0], ["debtFen", 0]]};

// --- Settings and start-up ------------------------------------------------------------------
call PMCD_fnc_settings;
private _names = TEST_settings apply {_x select 0};
private _server = TEST_settings select {(_x select 3) == 1};
private _own = (TEST_settings select {(_x select 3) == 0}) apply {_x select 0};
[count TEST_settings == 24 && {count _server == 19} && {_own isEqualTo ["PMCD_hudShow", "PMCD_hudX", "PMCD_hudY", "PMCD_hudSize", "PMCD_debugOn"]}
    && {(TEST_settings select {(_x select 0) == "PMCD_paybackMultiplier"}) isEqualTo [["PMCD_paybackMultiplier", "SLIDER", [8, 25, 15, 1], 1]]}
    && {(TEST_settings select {(_x select 0) == "PMCD_ae2Floor"}) isEqualTo [["PMCD_ae2Floor", "SLIDER", [0.15, 0.4, 0.25, 2], 1]]}
    && {PMCD_stimBaseDamage == 0.16} && {PMCD_stimPool == 900} && {PMCD_stimBevelA == 2} && {PMCD_stimBevelK == 1} && {PMCD_stimWeightMin == 5}
    && {PMCD_stimWeightMax == 80} && {PMCD_debtFactor == 1} && {PMCD_stimDuty == 0.5} && {!PMCD_debugOn}
    && {!("PMCD_stimTime40" in _names)} && {!("PMCD_debtPaybackFloor" in _names)},
    "24 CBA settings: 19 for the drug, forced by the server (new curve, pool, debt), 5 interface ones each player's own"] call TEST_fnc_assert;
call PMCD_fnc_init;
private _duty = ("ace_advanced_fatigue_fnc_addDutyFactor" call TEST_called) select 0 select 1;
[count ("CBA_fnc_addEventHandler" call TEST_called) == 3 && {(_duty select 0) == "PMCD_drugs"} && {(_duty select 1) isEqualType {}}
    && {count ("ace_field_rations_fnc_addStatusModifier" call TEST_called) == 1}
    && {((("ace_interact_menu_fnc_addActionToClass" call TEST_called) select 0 select 1) select [0, 3]) isEqualTo ["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"]]},
    "start-up: Zeus events, one duty factor for all drugs, the thirst modifier, the self-injection"] call TEST_fnc_assert;

// --- Weight curve (spec 1.1) ------------------------------------------------------------------
[[[5, 20, 40, 70, 80, 0, 120] apply {[_x] call PMCD_fnc_weightCoef}, [1, 1.077, 1.242, 1.729, 2, 1, 2]] call TEST_allNear,
    "weight coefficient: 1.000 / 1.077 / 1.242 / 1.729 / 2.000 at 5 / 20 / 40 / 70 / 80 kg, clamped outside 5-80"] call TEST_fnc_assert;

// --- A dose at a steady load (spec 1.3) --------------------------------------------------------
// [load] -> [seconds of action, muscle damage of the dose], one second at a time.
TEST_dose = {
    params ["_kg", ["_meld", 1]];
    private _state = call TEST_newState;
    _state set ["stimPool", missionNamespace getVariable ["PMCD_stimPool", 900]];
    private _effects = [["stim", "dec", 0.5]];
    if (_meld != 1) then {_effects pushBack ["meld", "meta", _meld]};
    private _seconds = 0;
    private _damage = 0;
    while {(_state get "stimPool") > 0 && {_seconds < 2000}} do {
        _seconds = _seconds + 1;
        _damage = _damage + (([_state, 1, _effects, _kg, 84000, 8.77, 1] call PMCD_fnc_step) select 0);
    };
    [_seconds, _damage]
};
private _doses = [5, 20, 40, 70, 80] apply {[_x] call TEST_dose};
private _stim = ["stim", "dec", 0.5];
[[_doses apply {_x select 0}, [900, 836, 725, 521, 450], 1] call TEST_allNear
    && {[_doses apply {_x select 1}, [0.16, 0.172, 0.199, 0.277, 0.32], 0.002] call TEST_allNear},
    "a dose lasts 15.0 / 13.9 / 12.1 / 8.7 / 7.5 min and does 0.160 / 0.172 / 0.199 / 0.277 / 0.320 at 5 / 20 / 40 / 70 / 80 kg"] call TEST_fnc_assert;
TEST_breakAt = {
    params ["_perDose"];
    private _sum = 0;
    private _n = 0;
    while {_sum < 0.85 && {_n < 20}} do {_n = _n + 1; _sum = _sum + _perDose};
    _n
};
private _plainBreaks = _doses apply {[_x select 1] call TEST_breakAt};
private _meldBreaks = [5, 20, 40, 70, 80] apply {[([_x, 0.77] call TEST_dose) select 1] call TEST_breakAt};
[_plainBreaks isEqualTo [6, 5, 5, 4, 3] && {_meldBreaks isEqualTo [7, 7, 6, 4, 4]},
    "0.85 is reached on doses 6 / 5 / 5 / 4 / 3, with meldonium 7 / 7 / 6 / 4 / 4 (table of the spec)"] call TEST_fnc_assert;
// Load changed mid-dose: the rest goes at the new load's rate.
private _swap = call TEST_newState;
_swap set ["stimPool", 900];
private _lightTotal = 0;
for "_i" from 1 to 300 do {_lightTotal = _lightTotal + (([_swap, 1, [["stim", "dec", 0.5]], 70, 84000, 8.77, 1] call PMCD_fnc_step) select 0)};
private _left = _swap get "stimPool";
while {(_swap get "stimPool") > 0} do {_lightTotal = _lightTotal + (([_swap, 1, [["stim", "dec", 0.5]], 5, 84000, 8.77, 1] call PMCD_fnc_step) select 0)};
private _wc70 = [70] call PMCD_fnc_weightCoef;
[[_left, 900 - 300 * _wc70, 0.01] call TEST_near && {[_lightTotal, 0.16 * _wc70 ^ 2 / 900 * 300 + 0.16 * _left / 900, 0.001] call TEST_near}
    && {[_swap get "stimDamage", _lightTotal, 1e-4] call TEST_near},
    "dropping the load mid-dose: the pool drains slower from then on and the damage follows the lighter load"] call TEST_fnc_assert;

private _tail = call TEST_newState;
_tail set ["stimPool", 1];
private _tailDamage = ([_tail, 1, [_stim], 80, 84000, 8.77, 1] call PMCD_fnc_step) select 0;
[[_tailDamage, 0.16 * 4 / 900 * 0.5, 1e-7] call TEST_near && {(_tail get "stimPool") == 0},
    "the last second of a dose counts only the part the pool still had (1 eq.s left at wc 2: half a second)"] call TEST_fnc_assert;

// --- Duty combination ----------------------------------------------------------------------------
private _fen = ["fen", "dec", 0.9];
private _hemo = ["hemo", "inc", 1.3];
[[[[_stim], [_fen], [_hemo], [_stim, _hemo], [_fen, _hemo], [_stim, _fen, _hemo], []] apply {[_x] call PMCD_fnc_duty},
    [0.5, 0.9, 1.3, 0.65, 1.17, 0.65, 1]] call TEST_allNear,
    "duty: the strongest decreasing factor times the strongest increasing one"] call TEST_fnc_assert;

// --- Debt (spec 2.1): the whole saved work ---------------------------------------------------------
TEST_debtOver = {
    params ["_effects", "_seconds"];
    private _state = call TEST_newState;
    for "_i" from 1 to _seconds do {[_state, 1, _effects, 40, 84000, 8.77, 1] call PMCD_fnc_step};
    _state
};
private _plain = [[_stim], 720] call TEST_debtOver;
private _boosted = [[_stim, _hemo], 720] call TEST_debtOver;
private _masked = [[_stim, _fen], 60] call TEST_debtOver;
[[_plain get "debt", 16420, 2] call TEST_near && {[_boosted get "debt", 16420 * 1.3, 3] call TEST_near} && {(_plain get "debtStim") == (_plain get "debt")}
    && {(_masked get "debtFen") == 0} && {[_masked get "debt", 200 * 60 / 8.77, 0.1] call TEST_near},
    "debt: 16 420 mmol for 12 min of Stim1f (x1.3 with a hemostatic); one pool; Fentropil under Stim1f runs none up"] call TEST_fnc_assert;

// --- Payback from AE2 (spec 2.2) ----------------------------------------------------------------------
private _pay = call TEST_newState;
_pay set ["debt", 1000];
private _held = ([_pay, 1, [_stim], 40, 60000, 0, 1] call PMCD_fnc_step) select 1;
private _first = ([_pay, 1, [], 40, 60000, 8.77, 1] call PMCD_fnc_step) select 1;
private _afterFirst = _pay get "debt";
private _fast = ([_pay, 1, [], 40, 60000, 8.77, 1.44] call PMCD_fnc_step) select 1;
[_held == 60000 && {_first == 59985} && {_afterFirst == 985} && {[_fast, 60000 - 21.6, 0.01] call TEST_near},
    "payback: none while a drug works; then 15 x recoveryFactor mmol/s from AE2 (15 at RF 1, 21.6 at 1.44)"] call TEST_fnc_assert;
private _edge = ([_pay, 1, [], 40, 21005, 8.77, 1] call PMCD_fnc_step) select 1;
private _paidAtEdge = _afterFirst - 21.6 - (_pay get "debt");
private _below = ([_pay, 1, [], 40, 20000, 8.77, 1] call PMCD_fnc_step) select 1;
private _ticks = [];
private _ae2 = 21000;
for "_i" from 1 to 5 do {
    _ae2 = _ae2 + 6;  // what ACE regenerated in a second
    _ae2 = ([_pay, 1, [], 40, _ae2, 8.77, 1] call PMCD_fnc_step) select 1;
    _ticks pushBack _ae2;
};
[_edge == 21000 && {[_paidAtEdge, 5, 0.01] call TEST_near} && {_below == 20000} && {_ticks isEqualTo [21000, 21000, 21000, 21000, 21000]},
    "the AE2 floor (25% = 21 000): payback never goes under it and waits below; at the floor it takes only what regrew, steadily"] call TEST_fnc_assert;

// --- Taking Stim1f on the loop ---------------------------------------------------------------------
call TEST_fresh;
[player] call PMCD_fnc_takeStim;
private _state = player getVariable "PMCD_state";
private _filled = ace_advanced_fatigue_anReserve;
[_filled == 2300 && {(_state get "stimPool") == 900} && {(_state get "stimDoses") == 1} && {count (player getVariable ["TEST_inv", []]) == 2},
    "a dose: one injector used, the AN reserve filled, a full pool of 900"] call TEST_fnc_assert;
call PMCD_fnc_init;
private _factor = ((("ace_advanced_fatigue_fnc_addDutyFactor" call TEST_called) select 0) select 1) select 1;
[(player call _factor) == 0.5, "ACE's fatigue gets duty 0.5 from the drug factor while Stim1f works"] call TEST_fnc_assert;
TEST_calls = [];
ace_advanced_fatigue_ae2Reserve = 84000;
[730] call TEST_run;
// SQF numbers are 32-bit floats: hundreds of small steps add up within 1e-3.
[[ace_advanced_fatigue_muscleDamage, 0.199, 0.002] call TEST_near && {(_state get "stimPool") == 0} && {(player call _factor) == 1}
    && {ace_advanced_fatigue_anReserve == 2300} && {(_state get "debt") > 15000} && {ace_advanced_fatigue_ae2Reserve < 84000},
    "over 12 min at 40 kg: 0.199 muscle damage, the debt runs up; then duty is back to 1, payback takes from AE2, AN untouched"] call TEST_fnc_assert;
private _debtNow = _state get "debt";
ace_advanced_fatigue_ae2Reserve = 50000;
[10] call TEST_run;
[[_state get "debt", _debtNow - 150, 0.01] call TEST_near && {ace_advanced_fatigue_ae2Reserve == 49850}, "payback goes on at 15 mmol/s from AE2"] call TEST_fnc_assert;
[player] call PMCD_fnc_takeStim;
[(_state get "stimDoses") == 2 && {ace_advanced_fatigue_anReserve == 2300} && {[_state get "debt", _debtNow - 150, 0.01] call TEST_near}
    && {(_state get "stimPool") == 900} && {(_state get "stimDamage") == 0},
    "a dose during payback: allowed, a new pool, the reserve refilled, the old debt kept"] call TEST_fnc_assert;

// --- Overdose -------------------------------------------------------------------------------------
TEST_calls = [];
[player] call PMCD_fnc_takeStim;
private _adjust = ("ace_medical_status_fnc_addMedicationAdjustment" call TEST_called) select 0 select 1;
[count _adjust == 8 && {(_adjust select 1) == "PMCD_Stim1f"} && {(_adjust select 2) >= 30 && {(_adjust select 2) <= 50}} && {(_adjust select 4) == 200}
    && {(_state get "stimPool") == 900} && {(_state get "stimDoses") == 2} && {(_state get "overdoses") == 1} && {count (player getVariable ["TEST_inv", []]) == 0},
    "a dose during the action is an overdose: ACE medication +200 bpm in 30-50 s; the action goes on unchanged"] call TEST_fnc_assert;
[!([player] call PMCD_fnc_takeStim), "without an injector nothing is taken"] call TEST_fnc_assert;

// --- Thirst ---------------------------------------------------------------------------------------
private _currentWork = 1.5;
private _thirsty = [player] call PMCD_fnc_thirst;
_state set ["stimPool", 0];
private _calm = [player] call PMCD_fnc_thirst;
[_thirsty == 3 && {_calm == 0}, "an active Stim1f triples thirst (twice the base work on top); none after it"] call TEST_fnc_assert;

// --- Settings change the drug ---------------------------------------------------------------------
PMCD_stimBaseDamage = 0.2;
PMCD_stimPool = 600;
PMCD_stimBevelK = 2;
PMCD_paybackMultiplier = 20;
PMCD_ae2Floor = 0.4;
PMCD_debtFactor = 0.5;
private _tunedWc = [80] call PMCD_fnc_weightCoef;
private _tunedDose = [80] call TEST_dose;
private _tunedPay = call TEST_newState;
_tunedPay set ["debt", 1000];
private _tunedAe2 = ([_tunedPay, 1, [], 40, 40000, 8.77, 1] call PMCD_fnc_step) select 1;
private _tunedFloor = ([_tunedPay, 1, [], 40, 33610, 8.77, 1] call PMCD_fnc_step) select 1;
private _tunedDebt = [[_stim], 10] call TEST_debtOver;
[_tunedWc == 3 && {(_tunedDose select 0) == 200} && {[_tunedDose select 1, 0.6, 0.002] call TEST_near} && {_tunedAe2 == 39980} && {_tunedFloor == 33600}
    && {[_tunedDebt get "debt", 100 * 10 / 8.77, 0.01] call TEST_near},
    "CBA settings change the curve, the pool, the damage, the payback rate and floor, and the debt factor"] call TEST_fnc_assert;
call PMCD_fnc_settings;

// --- Muscle icon colour (spec section 5 of the first spec) -----------------------------------------------
private _colours = [0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.675, 0.849, 0.85, 1] apply {[_x] call PMCD_fnc_hudColor};
[(_colours select 0) isEqualTo [] && {[_colours select 1, [1, 0.95, 0.6, 1]] call TEST_allNear} && {[_colours select 2, [1, 0.75, 0.35, 1]] call TEST_allNear}
    && {[_colours select 3, [1, 0.55, 0.1, 1]] call TEST_allNear} && {[_colours select 4, [0.95, 0.325, 0.09, 1]] call TEST_allNear}
    && {[_colours select 5, [0.9, 0.1, 0.08, 1]] call TEST_allNear} && {[_colours select 6, [0.625, 0.06, 0.05, 1]] call TEST_allNear}
    && {(((_colours select 7) select 0) - 0.35) < 0.01} && {(_colours select 8) isEqualTo [0, 0, 0, 1]} && {(_colours select 9) isEqualTo [0, 0, 0, 1]},
    "muscle icon: hidden under 0.1, pale yellow - orange - red - dark red smoothly, black from 0.85"] call TEST_fnc_assert;

// --- Zeus module: check and set on the player's machine --------------------------------------------
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
    "set: clamped to 0-1, a neutral line for the player, the new value back to the Zeus"] call TEST_fnc_assert;
TEST_calls = [];
[_zeus, _zeus, 0.5] call PMCD_fnc_muscleSet;
[TEST_calls isEqualTo [] && {ace_advanced_fatigue_muscleDamage == 0}, "a machine only answers for its own player"] call TEST_fnc_assert;

// --- Debug panel text --------------------------------------------------------------------------------
PMCD_fnc_debugText = "pmc_drugs/Hud/fn_debugText.sqf" call TEST_fnc_load;
call TEST_fresh;
[player] call PMCD_fnc_takeStim;
ace_advanced_fatigue_dutyList = createHashMapFromArray [["PMCD_drugs", {0.5}], ["other", 0.9]];
private _panel = call PMCD_fnc_debugText;
diag_log _panel;
[_panel isEqualType "" && {(_panel find "pool 900 / 900") >= 0} && {(_panel find "wc 1.242") >= 0} && {(_panel find "final 0.500") >= 0}
    && {(_panel find "PMCD_drugs=0.500") >= 0} && {(_panel find "heart rate -") >= 0} && {(_panel find "AE2 84000") >= 0},
    "the debug panel shows the drug, fatigue, medical and settings values, '-' where a value does not exist"] call TEST_fnc_assert;

diag_log format ["TEST_COMPLETE: %1 assertions", TEST_count];
