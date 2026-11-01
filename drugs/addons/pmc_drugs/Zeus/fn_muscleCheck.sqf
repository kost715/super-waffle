// [Zeus unit, unit] -> nothing. The unit's machine, from the Zeus window: answers the
// Zeus with the muscle damage, if the unit is this machine's player and the asker a Zeus.
params ["_zeus", "_unit"];
if (isNull _zeus || {!(_unit isEqualTo ACE_player)} || {isNull getAssignedCuratorLogic _zeus}) exitWith {};
["PMCD_muscleShow", [_unit, missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]], _zeus] call CBA_fnc_targetEvent;
