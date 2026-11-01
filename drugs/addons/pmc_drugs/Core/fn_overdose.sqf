// [unit] -> nothing. Where the unit is local: a Stim1f taken while one is active. With ACE
// Medical the pulse climbs through a medication adjustment of +200 bpm reached in 30-50 s
// (CBA settings; about 5-8 bpm per second near the end, ACE's own quadratic build-up) past 220, where
// ACE's vitals send the unit into cardiac arrest: CPR and a medic can bring it back. The
// active phase keeps working; the overdose adds no muscle damage, debt or forced walking.
// Without ACE Medical the unit falls unconscious and dies after 60-120 s.
params ["_unit"];
if (!isNil "ace_medical_status_fnc_addMedicationAdjustment" && {missionNamespace getVariable ["ace_medical_enabled", false]}) exitWith {
    private _from = missionNamespace getVariable ["PMCD_overdoseRampMin", 30];
    private _to = _from max (missionNamespace getVariable ["PMCD_overdoseRampMax", 50]);
    [_unit, "PMCD_Stim1f", _from + random (_to - _from), 900, missionNamespace getVariable ["PMCD_overdosePulse", 200], 0, 0, 1]
        call ace_medical_status_fnc_addMedicationAdjustment;
};
_unit setUnconscious true;
private _from = missionNamespace getVariable ["PMCD_overdoseDeathMin", 60];
private _to = _from max (missionNamespace getVariable ["PMCD_overdoseDeathMax", 120]);
[{params ["_unit"]; if (alive _unit) then {_unit setDamage 1}}, [_unit], _from + random (_to - _from)] call CBA_fnc_waitAndExecute;
