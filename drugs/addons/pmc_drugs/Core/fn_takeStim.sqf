// [unit] -> taken. Where the unit is local, after the injection bar: one Stim1f is used.
// Every dose is the same, whenever it is taken: a new dose starts with a full pool of
// action (CBA, 900 equivalent seconds; its length and damage follow the load as it goes,
// PMCD_fnc_step), the AN reserve is filled, and the dose puts its own pulse rise into ACE
// Medical (CBA, +75 bpm, reached in 10 s) for as long as it acts. Doses taken together add
// up: two make +150, and above 220 bpm ACE's own vitals stop the heart.
params ["_unit"];
if !([_unit] call PMCD_fnc_canTake) exitWith {false};
_unit removeItem "PMCD_Stim1f";
private _state = [_unit] call PMCD_fnc_state;
private _number = (_state get "stimDoses") + 1;
_state set ["stimDoses", _number];
private _name = format ["PMCD_Stim1f_%1", _number];
private _pool = missionNamespace getVariable ["PMCD_stimPool", 900];
(_state get "doses") pushBack [_pool, _name, 0];
// Its own debt pool: paid back from the moment this dose ends (PMCD_fnc_step).
(_state get "stimDebts") pushBack [_name, 0, false];
// ACE Advanced Fatigue's full AN reserve (AN_MAXRESERVE), unless switched off in CBA.
if (_unit isEqualTo ACE_player && {missionNamespace getVariable ["PMCD_stimFillAN", true]}) then {ace_advanced_fatigue_anReserve = 2300};
// The pulse rise: ACE makes a medication's effect fade over its time in the body, so the
// time given is far longer than any dose acts (100 x the pool: under 1% fade); the mod
// takes the effect out itself when the dose ends (PMCD_fnc_pulseEnd).
if (!isNil "ace_medical_status_fnc_addMedicationAdjustment" && {missionNamespace getVariable ["ace_medical_enabled", false]}) then {
    [_unit, _name, missionNamespace getVariable ["PMCD_stimPulseRamp", 10], 100 * _pool, missionNamespace getVariable ["PMCD_stimPulse", 75], 0, 0, 1]
        call ace_medical_status_fnc_addMedicationAdjustment;
};
true
