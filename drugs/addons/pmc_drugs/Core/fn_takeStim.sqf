// [unit] -> taken. Where the unit is local, after the injection bar: one Stim1f is used.
// With no Stim1f phase active a new phase starts (also while debt is being paid back:
// the new debt comes on top): its length and muscle damage follow the dose number and
// the load (PMCD_fnc_stimDose), and the AN reserve is filled. A dose during an active
// phase is an overdose (PMCD_fnc_overdose); the active phase goes on unchanged.
params ["_unit"];
if !([_unit] call PMCD_fnc_canTake) exitWith {false};
_unit removeItem "PMCD_Stim1f";
private _state = [_unit] call PMCD_fnc_state;
private _now = CBA_missionTime;
if (_now < (_state get "stimUntil")) exitWith {[_unit] call PMCD_fnc_overdose; true};
private _dose = (_state get "stimDoses") + 1;
_state set ["stimDoses", _dose];
([_dose, [[_unit] call PMCD_fnc_unitLoad] call PMCD_fnc_loadClass] call PMCD_fnc_stimDose) params ["_duration", "_damage"];
_state set ["stimUntil", _now + _duration];
_state set ["stimRate", _damage / _duration];
// ACE Advanced Fatigue's full AN reserve (AN_MAXRESERVE), unless switched off in CBA.
if (_unit isEqualTo ACE_player && {missionNamespace getVariable ["PMCD_stimFillAN", true]}) then {ace_advanced_fatigue_anReserve = 2300};
true
