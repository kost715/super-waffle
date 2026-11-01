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
private _pool = _state getOrDefault ["stimPool", 0];
private _base = missionNamespace getVariable ["PMCD_stimBaseDamage", 0.16];
private _poolMax = missionNamespace getVariable ["PMCD_stimPool", 900];
private _recovery = missionNamespace getVariable ["ace_advanced_fatigue_recoveryFactor", 1];
private _rate = (missionNamespace getVariable ["PMCD_paybackMultiplier", 15]) * _recovery;
private _floor = (missionNamespace getVariable ["PMCD_ae2Floor", 0.25]) * 84000;
private _ae2 = missionNamespace getVariable ["ace_advanced_fatigue_ae2Reserve", 0];
private _debt = _state getOrDefault ["debt", 0];
private _wpa = missionNamespace getVariable ["ace_advanced_fatigue_anWattsPerATP", 0];
private _dec = 1;
private _inc = 1;
{if ((_x select 1) == "dec") then {_dec = _dec min (_x select 2)}; if ((_x select 1) == "inc") then {_inc = _inc max (_x select 2)}} forEach _effects;

_lines pushBack ("PMC DRUGS DEBUG" call _head);
_lines pushBack format ["unit %1  mission time %2 s  alive %3", name _unit, CBA_missionTime toFixed 0, alive _unit];
_lines pushBack ("Stim1f" call _head);
_lines pushBack format ["active %1  pool %2 / %3 eq.s  doses %4  overdoses %5", _pool > 0, _pool toFixed 0, _poolMax, _state getOrDefault ["stimDoses", 0], _state getOrDefault ["overdoses", 0]];
_lines pushBack format ["load %1 kg  wc %2  time left %3 s (at this load)  dose damage so far %4", _kg toFixed 1, _wc toFixed 3,
    (_pool / _wc) toFixed 0, (_state getOrDefault ["stimDamage", 0]) toFixed 4];
_lines pushBack format ["damage now %1 /s  whole dose at this load %2  duration at this load %3 min", (_base * _wc ^ 2 / _poolMax) toFixed 6,
    (_base * _wc) toFixed 3, (_poolMax / _wc / 60) toFixed 1];
_lines pushBack ("Duty and debt" call _head);
_lines pushBack format ["effects %1", _effects];
_lines pushBack format ["duty: decreasing %1  increasing %2  final %3", _dec toFixed 2, _inc toFixed 2, ([_effects] call PMCD_fnc_duty) toFixed 3];
_lines pushBack format ["debt %1 mmol (Stim1f %2, Fentropil %3)  icon %4", _debt toFixed 0, (_state getOrDefault ["debtStim", 0]) toFixed 0,
    (_state getOrDefault ["debtFen", 0]) toFixed 0, _debt > 500];
_lines pushBack format ["accrual now %1 mmol/s  payback %2 mmol/s (15 x RF %3)  AE2 floor %4  paying %5",
    ([0, (missionNamespace getVariable ["PMCD_debtBaseWork", 400]) * _inc * (1 - _dec) / (_wpa max 0.001) * (missionNamespace getVariable ["PMCD_debtFactor", 1])] select (_dec < 1)) toFixed 2,
    _rate toFixed 1, _recovery toFixed 2, _floor toFixed 0, _dec >= 1 && {_debt > 0} && {_ae2 > _floor}];
_lines pushBack format ["payback time at full rate %1 min", (_debt / (_rate max 0.001) / 60) toFixed 1];
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
_lines pushBack format ["debt: base work %1 W  factor %2  payback x%3  AE2 floor %4  overdose: +%5 bpm in %6-%7 s", ["PMCD_debtBaseWork", 0] call _g,
    ["PMCD_debtFactor"] call _g, ["PMCD_paybackMultiplier", 1] call _g, ["PMCD_ae2Floor"] call _g, ["PMCD_overdosePulse", 0] call _g,
    ["PMCD_overdoseRampMin", 0] call _g, ["PMCD_overdoseRampMax", 0] call _g];
format ["<t size='0.8' font='EtelkaMonospacePro' shadow='2'>%1</t>", _lines joinString "<br/>"]
