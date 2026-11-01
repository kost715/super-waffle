// [Zeus unit, unit, value 0-1] -> nothing. The unit's machine, from the Zeus window: sets
// the muscle damage, if the unit is this machine's player and the sender a Zeus. The player
// reads one neutral line (worn / recovered, no numbers); the Zeus gets the new value back.
params ["_zeus", "_unit", "_value"];
if (isNull _zeus || {!(_unit isEqualTo ACE_player)} || {isNull getAssignedCuratorLogic _zeus} || {!(_value isEqualType 0)}) exitWith {};
private _old = missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0];
private _new = 0 max (_value min 1);
ace_advanced_fatigue_muscleDamage = _new;
if (_new != _old) then {[["STR_PMCD_MUSCLE_RECOVERED", "STR_PMCD_MUSCLE_WORN"] select (_new > _old)] call PMCD_fnc_notify};
["PMCD_muscleShow", [_unit, _new], _zeus] call CBA_fnc_targetEvent;
