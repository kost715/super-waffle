// [state, seconds, work now W] -> nothing. Client, per second while meldonium acts: the
// part of ACE Advanced Fatigue's own growth it takes back, worked out from ACE's main-loop
// formulas for the work now (not from the change since the last second, which also holds
// ACE's recovery and the mod's own Stim1f damage - that one meldonium already cuts in
// PMCD_fnc_step, so it is never cut twice):
//  - natural muscle damage (work / peakPower)^3.2 x 0.00004 per second: 23% of it back
//    (CBA 0.77 kept);
//  - acidosis (anFatigue) AN power x maxPowerFatigueRatio x 1.1 per second: 25% of it back
//    (CBA 0.75 kept). The AN power is the work the aerobic pathways cannot cover.
params ["_state", "_dt", "_work"];
private _peak = missionNamespace getVariable ["ace_advanced_fatigue_peakPower", 0];
private _muscleBack = 0;
if (_peak > 0) then {
    _muscleBack = (1 - (missionNamespace getVariable ["PMCD_meldMuscle", 0.77])) * (_work / _peak) ^ 3.2 * 0.00004 * _dt;
    ace_advanced_fatigue_muscleDamage = 0 max ((missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]) - _muscleBack);
};
([_work] call PMCD_fnc_aeSplit) params ["", "", "", "_anPower"];
private _acidBack = (1 - (missionNamespace getVariable ["PMCD_meldAcid", 0.75])) * _anPower
    * (missionNamespace getVariable ["ace_advanced_fatigue_maxPowerFatigueRatio", 0]) * 1.1 * _dt;
if (_acidBack > 0) then {
    ace_advanced_fatigue_anFatigue = 0 max ((missionNamespace getVariable ["ace_advanced_fatigue_anFatigue", 0]) - _acidBack);
};
_state set ["meldBack", [_muscleBack / (_dt max 0.001), _acidBack / (_dt max 0.001)]];
