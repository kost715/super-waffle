// [unit] -> nothing. Where the unit is local: a Stim1f taken while one is active. With ACE
// Medical the pulse climbs through a medication adjustment of +200 bpm reached in 30-50 s
// (about 5-8 bpm per second near the end, ACE's own quadratic build-up) past 220, where
// ACE's vitals send the unit into cardiac arrest: CPR and a medic can bring it back. The
// active phase keeps working; the overdose adds no muscle damage, debt or forced walking.
// Without ACE Medical the unit falls unconscious and dies after 60-120 s.
params ["_unit"];
if (!isNil "ace_medical_status_fnc_addMedicationAdjustment" && {missionNamespace getVariable ["ace_medical_enabled", false]}) exitWith {
    [_unit, "PMCD_Stim1f", 30 + random 20, 900, 200, 0, 0, 1] call ace_medical_status_fnc_addMedicationAdjustment;
};
_unit setUnconscious true;
[{params ["_unit"]; if (alive _unit) then {_unit setDamage 1}}, [_unit], 60 + random 60] call CBA_fnc_waitAndExecute;
