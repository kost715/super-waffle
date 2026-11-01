// [unit] -> extra thirst for ACE Field Rations (a status modifier, added to the base). An
// active Stim1f phase makes the unit three times as thirsty: twice the base change on top.
// Field Rations calls modifiers from its update, where _currentWork is its base work.
params ["_unit"];
private _state = _unit getVariable "PMCD_state";
if (isNil "_state" || {CBA_missionTime >= (_state get "stimUntil")}) exitWith {0};
private _work = if (isNil "_currentWork") then {1} else {_currentWork};
2 * _work
