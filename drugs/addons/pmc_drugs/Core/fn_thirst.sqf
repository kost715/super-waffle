// [unit] -> extra thirst for ACE Field Rations (a status modifier, added to the base). An
// active Stim1f phase makes the unit three times as thirsty (CBA setting): twice the base
// change on top.
// Field Rations calls modifiers from its update, where _currentWork is its base work.
params ["_unit"];
private _state = _unit getVariable "PMCD_state";
if (isNil "_state" || {(_state get "stimPool") <= 0}) exitWith {0};
private _work = if (isNil "_currentWork") then {1} else {_currentWork};
((missionNamespace getVariable ["PMCD_stimThirst", 3]) - 1) * _work
