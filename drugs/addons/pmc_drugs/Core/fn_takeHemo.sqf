// [unit] -> taken. Where the unit is local, after the injection bar: one hemostatic is used.
// It acts for the set time from now (CBA, 6 min); another dose while it acts starts that
// time again, it does not add up.
params ["_unit"];
if !([_unit, "PMCD_Hemostatic"] call PMCD_fnc_canTake) exitWith {false};
_unit removeItem "PMCD_Hemostatic";
private _state = [_unit] call PMCD_fnc_state;
_state set ["hemoEnd", CBA_missionTime + 60 * (missionNamespace getVariable ["PMCD_hemoDuration", 6])];
_state set ["hemoTaken", (_state getOrDefault ["hemoTaken", 0]) + 1];
true
