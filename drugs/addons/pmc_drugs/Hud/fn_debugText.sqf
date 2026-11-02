// -> the debug panel's structured text: everything the drugs read or change, for the
// player's unit. Values that do not exist (a module not loaded) show as "-".
private _unit = missionNamespace getVariable ["ACE_player", player];
private _num = {
    params ["_value", ["_digits", 2]];
    if (isNil "_value") exitWith {"-"};
    if (_value isEqualType 0) exitWith {_value toFixed _digits};
    str _value
};
private _g = {params ["_name", ["_digits", 2]]; [missionNamespace getVariable _name, _digits] call _num};
private _u = {params ["_name", ["_digits", 2]]; [_unit getVariable _name, _digits] call _num};
private _head = {format ["<t color='#ffd27f'>%1</t>", _this]};
private _lines = [];
private _state = _unit getVariable "PMCD_state";
if (isNil "_state") then {_state = createHashMap};
private _kg = [_unit] call PMCD_fnc_unitLoad;
private _wc = [_kg] call PMCD_fnc_weightCoef;
private _effects = [_state, CBA_missionTime] call PMCD_fnc_effects;
private _doses = _state getOrDefault ["doses", []];
private _base = missionNamespace getVariable ["PMCD_stimBaseDamage", 0.16];
private _poolMax = missionNamespace getVariable ["PMCD_stimPool", 900];
private _recovery = missionNamespace getVariable ["ace_advanced_fatigue_recoveryFactor", 1];
private _rate = (missionNamespace getVariable ["PMCD_paybackMultiplier", 15]) * _recovery;
private _floor = (missionNamespace getVariable ["PMCD_ae2Floor", 0.25]) * 84000;
private _ae2 = missionNamespace getVariable ["ace_advanced_fatigue_ae2Reserve", 0];
private _debt = _state getOrDefault ["debt", 0];
private _dec = 1;
private _inc = 1;
{if ((_x select 1) == "dec") then {_dec = _dec min (_x select 2)}; if ((_x select 1) == "inc") then {_inc = _inc max (_x select 2)}} forEach _effects;

_lines pushBack ("PMC DRUGS DEBUG" call _head);
_lines pushBack format ["unit %1  mission time %2 s  alive %3", name _unit, CBA_missionTime toFixed 0, alive _unit];
_lines pushBack ("Stim1f" call _head);
_lines pushBack format ["acting doses %1  doses taken %2  load %3 kg  wc %4", count _doses, _state getOrDefault ["stimDoses", 0], _kg toFixed 1, _wc toFixed 3];
{
    _x params ["_pool", "_name", "_done"];
    _lines pushBack format ["  %1: pool %2 / %3 eq.s  left %4 s at this load  damage so far %5", _name, _pool toFixed 0, _poolMax, (_pool / _wc) toFixed 0, _done toFixed 4];
} forEach _doses;
_lines pushBack format ["damage now %1 /s per dose (%2 in all)  whole dose at this load %3  duration at this load %4 min", (_base * _wc ^ 2 / _poolMax) toFixed 6,
    (_base * _wc ^ 2 / _poolMax * count _doses) toFixed 6, (_base * _wc) toFixed 3, (_poolMax / _wc / 60) toFixed 1];
_lines pushBack format ["pulse per dose +%1 bpm in %2 s  now from the doses +%3 bpm", ["PMCD_stimPulse", 0] call _g, ["PMCD_stimPulseRamp", 0] call _g,
    (missionNamespace getVariable ["PMCD_stimPulse", 75]) * count _doses];
_lines pushBack ("Fentropil" call _head);
([_state, CBA_missionTime] call PMCD_fnc_fenLevel) params ["_c", "_fenG"];
private _fenDoses = _state getOrDefault ["fenDoses", []];
_lines pushBack format ["doses taken %1  in the body %2 (minutes since each %3)  C %4  strength g(C) %5 (divider %6, cap %7)", _state getOrDefault ["fenTaken", 0],
    count _fenDoses, _fenDoses apply {((CBA_missionTime - _x) / 60) toFixed 1}, _c toFixed 3, _fenG toFixed 3, ["PMCD_fenDivider"] call _g, ["PMCD_fenCap"] call _g];
_lines pushBack format ["duty %1  pathway boost x%2 (ACE base %3)  anim speed x%4 (on %5)  sway x%6  new pain x%7",
    (0.01 max (1 - (1 - (missionNamespace getVariable ["PMCD_fenDuty", 0.9])) * _fenG)) toFixed 3, (_state getOrDefault ["fenBoost", 1]) toFixed 4,
    (_state getOrDefault ["fenBase", []]) apply {_x toFixed 1}, (1 + (missionNamespace getVariable ["PMCD_fenAnim", 0.05]) * _fenG) toFixed 3,
    missionNamespace getVariable ["PMCD_fenAnimOn", true], (0 max (1 - (missionNamespace getVariable ["PMCD_fenSway", 0.15]) * _fenG)) toFixed 3,
    (0 max (1 - (missionNamespace getVariable ["PMCD_fenPain", 0.15]) * _fenG)) toFixed 3];
_lines pushBack format ["picture: colour corrections %1 (effect %2, priority %3)  pain last second %4", missionNamespace getVariable ["PMCD_fenVisualValues", "-"],
    missionNamespace getVariable ["PMCD_fenVisual", -1], missionNamespace getVariable ["PMCD_fenVisualPriority", "-"], (_state getOrDefault ["painSeen", 0]) toFixed 3];
_lines pushBack ("Meldonium" call _head);
([_state, CBA_missionTime] call PMCD_fnc_meldLevel) params ["_meldOn", "_meldAmount", "_meldEnd"];
(_state getOrDefault ["meldBack", [0, 0]]) params ["_muscleBack", "_acidBack"];
_lines pushBack format ["acting %1  doses taken %2  metabolite %3 (threshold 0.25)  ends in %4 min  muscle damage x%5  acidosis x%6",
    _meldOn, _state getOrDefault ["meldTaken", 0], _meldAmount toFixed 3, ((0 max (_meldEnd - CBA_missionTime)) / 60) toFixed 1, ["PMCD_meldMuscle"] call _g,
    ["PMCD_meldAcid"] call _g];
_lines pushBack format ["taken back from ACE per second: muscle damage %1  acidosis %2", _muscleBack toFixed 8, _acidBack toFixed 6];
_lines pushBack format ["AE2 recovery support (Fentropil + meldonium) +%1 mmol/s", (_state getOrDefault ["regen", 0]) toFixed 3];
_lines pushBack ("Duty and debt" call _head);
_lines pushBack format ["effects %1", _effects];
_lines pushBack format ["duty: decreasing %1  increasing %2  final %3", _dec toFixed 2, _inc toFixed 2, ([_effects] call PMCD_fnc_duty) toFixed 3];
_lines pushBack format ["debt %1 mmol: Stim1f pool %2, Fentropil pool %3  icon %4", _debt toFixed 0, (_state getOrDefault ["debtStim", 0]) toFixed 0,
    (_state getOrDefault ["debtFen", 0]) toFixed 0, _debt > 500];
(_state getOrDefault ["lastWork", [0, 0, 0, 0]]) params ["_workNow", "_nominal", "_savings", "_accrual"];
_lines pushBack format ["work now %1 W  nominal (no drugs) %2 W  saved %3 W  debt accrual %4 mmol/s", _workNow toFixed 1, _nominal toFixed 1,
    _savings toFixed 1, _accrual toFixed 2];
private _fenRate = _rate / ((missionNamespace getVariable ["PMCD_fenPaybackDivider", 3]) max 1);
(_state getOrDefault ["lastPay", ["", 0]]) params ["_payPool", "_payRate"];
_lines pushBack format ["payback: Stim1f pool %1 mmol/s (15 x RF %2), Fentropil pool %3 mmol/s (after Stim1f's)  AE2 floor %4  last second: %5 %6 mmol/s",
    _rate toFixed 1, _recovery toFixed 2, _fenRate toFixed 1, _floor toFixed 0, [_payPool, "none"] select (_payPool == ""), _payRate toFixed 2];
_lines pushBack format ["payback time at full rate %1 min (Stim1f %2, Fentropil %3)",
    (((_state getOrDefault ["debtStim", 0]) / (_rate max 0.001) + (_state getOrDefault ["debtFen", 0]) / (_fenRate max 0.001)) / 60) toFixed 1,
    ((_state getOrDefault ["debtStim", 0]) / (_rate max 0.001) / 60) toFixed 1, ((_state getOrDefault ["debtFen", 0]) / (_fenRate max 0.001) / 60) toFixed 1];
_lines pushBack ("ACE Advanced Fatigue" call _head);
_lines pushBack format ["muscleDamage %1  muscleFactor %2  icon colour %3", ["ace_advanced_fatigue_muscleDamage", 4] call _g,
    (sqrt (1 - (missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]))) toFixed 3,
    [missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]] call PMCD_fnc_hudColor];
_lines pushBack format ["AE1 %1 / 4000000  AE2 %2 / 84000 (%3 pct)  AN %4 / 2300 (%5 pct)", ["ace_advanced_fatigue_ae1Reserve", 0] call _g, _ae2 toFixed 0,
    (_ae2 / 840) toFixed 1, ["ace_advanced_fatigue_anReserve", 0] call _g, ((missionNamespace getVariable ["ace_advanced_fatigue_anReserve", 0]) / 23) toFixed 1];
_lines pushBack format ["anFatigue %1  respiratoryRate %2  animDuty %3  aeReservePct %4  anReservePct %5", ["ace_advanced_fatigue_anFatigue", 3] call _g,
    ["ace_advanced_fatigue_respiratoryRate", 3] call _g, ["ace_advanced_fatigue_animDuty", 2] call _g,
    ["ace_advanced_fatigue_aeReservePercentage", 3] call _g, ["ace_advanced_fatigue_anReservePercentage", 3] call _g];
_lines pushBack format ["peakPower %1  VO2Max %2  VO2MaxPower %3  maxPowerFatigueRatio %4", ["ace_advanced_fatigue_peakPower", 1] call _g,
    ["ace_advanced_fatigue_VO2Max", 1] call _g, ["ace_advanced_fatigue_VO2MaxPower", 1] call _g, ["ace_advanced_fatigue_maxPowerFatigueRatio", 7] call _g];
_lines pushBack format ["pathways AE1 %1 W  AE2 %2 W  AN %3 W  wattsPerATP AE %4  AN %5", ["ace_advanced_fatigue_ae1PathwayPower", 1] call _g,
    ["ace_advanced_fatigue_ae2PathwayPower", 1] call _g, ["ace_advanced_fatigue_anPathwayPower", 1] call _g,
    ["ace_advanced_fatigue_aeWattsPerATP", 3] call _g, ["ace_advanced_fatigue_anWattsPerATP", 3] call _g];
_lines pushBack format ["settings: performance %1  recovery %2  load %3  terrain %4  swayFactor %5", ["ace_advanced_fatigue_performanceFactor"] call _g,
    ["ace_advanced_fatigue_recoveryFactor"] call _g, ["ace_advanced_fatigue_loadFactor"] call _g, ["ace_advanced_fatigue_terrainGradientFactor"] call _g,
    ["ace_advanced_fatigue_swayFactor"] call _g];
private _duties = missionNamespace getVariable ["ace_advanced_fatigue_dutyList", createHashMap];
_lines pushBack format ["duty factors %1  anim exclusions %2", (keys _duties) apply {
    private _factor = _duties get _x;
    format ["%1=%2", _x, if (_factor isEqualType 0) then {_factor} else {(_unit call _factor) toFixed 3}]
}, missionNamespace getVariable ["ace_advanced_fatigue_setAnimExclusions", "-"]];
_lines pushBack format ["sprint allowed %1  forced walk %2  anim speed %3  aim coef %4  speed %5 m/s", isSprintAllowed _unit, isForcedWalk _unit,
    (getAnimSpeedCoef _unit) toFixed 2, (getCustomAimCoef _unit) toFixed 2, (vectorMagnitude velocity _unit) toFixed 1];
_lines pushBack ("ACE Medical" call _head);
_lines pushBack format ["heart rate %1  pain %2  pain suppress %3  blood %4 l  SpO2 %5  peripheral res. %6", ["ace_medical_heartRate", 0] call _u,
    ["ace_medical_pain", 3] call _u, ["ace_medical_painSuppress", 3] call _u, ["ace_medical_bloodVolume", 2] call _u, ["ace_medical_spo2", 0] call _u,
    ["ace_medical_peripheralResistance", 0] call _u];
_lines pushBack format ["cardiac arrest %1  unconscious %2", ["ace_medical_inCardiacArrest"] call _u, ["ACE_isUnconscious"] call _u];
_lines pushBack format ["medications %1", (_unit getVariable ["ace_medical_medications", []]) apply {
    _x params ["_name", "_added", "_toMax", "_maxTime", "_hr"];
    format ["%1 (%2 s ago, HR %3)", _name, (CBA_missionTime - _added) toFixed 0, _hr]
}];
_lines pushBack ("Field Rations" call _head);
_lines pushBack format ["thirst %1  hunger %2", ["acex_field_rations_thirst", 1] call _u, ["acex_field_rations_hunger", 1] call _u];
_lines pushBack ("PMC Drugs settings" call _head);
_lines pushBack format ["duty %1  pool %2  base damage %3  bevel a %4 k %5  weight %6-%7 kg  thirst x%8  fill AN %9", ["PMCD_stimDuty"] call _g,
    ["PMCD_stimPool", 0] call _g, ["PMCD_stimBaseDamage", 3] call _g, ["PMCD_stimBevelA"] call _g, ["PMCD_stimBevelK"] call _g,
    ["PMCD_stimWeightMin", 0] call _g, ["PMCD_stimWeightMax", 0] call _g, ["PMCD_stimThirst", 1] call _g, ["PMCD_stimFillAN"] call _g];
_lines pushBack format ["debt: factor %1  payback x%2  Fentropil pool /%3  AE2 floor %4  pulse per dose +%5 bpm in %6 s", ["PMCD_debtFactor"] call _g,
    ["PMCD_paybackMultiplier", 1] call _g, ["PMCD_fenPaybackDivider", 1] call _g, ["PMCD_ae2Floor"] call _g, ["PMCD_stimPulse", 0] call _g,
    ["PMCD_stimPulseRamp", 0] call _g];
_lines pushBack format ["Fentropil at C 1: duty %1  power +%2  AE2 support +%3  sway -%4  anim +%5  new pain -%6  dose %7 / %8 / %9 min  picture %10 / %11",
    ["PMCD_fenDuty"] call _g, ["PMCD_fenPower", 3] call _g, ["PMCD_fenRegen"] call _g, ["PMCD_fenSway"] call _g, ["PMCD_fenAnim", 3] call _g,
    ["PMCD_fenPain"] call _g, ["PMCD_fenRise", 0] call _g, ["PMCD_fenPlateau", 0] call _g, ["PMCD_fenFall", 0] call _g,
    ["PMCD_fenContrast", 3] call _g, ["PMCD_fenSaturation", 3] call _g];
_lines pushBack format ["meldonium: duration %1 min  muscle x%2  acidosis x%3  AE2 support +%4", ["PMCD_meldDuration", 0] call _g, ["PMCD_meldMuscle"] call _g,
    ["PMCD_meldAcid"] call _g, ["PMCD_meldRegen"] call _g];
format ["<t size='0.8' font='EtelkaMonospacePro' shadow='2'>%1</t>", _lines joinString "<br/>"]
