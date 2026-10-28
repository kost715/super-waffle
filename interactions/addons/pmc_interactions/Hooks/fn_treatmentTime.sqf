// [trained] -> treatment time. Replaces "treatmentTime"/"treatmentTimeTrained" of the
// taken-over ACE treatments; ACE calls it with its own _this = [medic, patient, body
// part, treatment]. A short preparation bar before the game, ACE's own time otherwise.
params [["_trained", false]];
private _args = _this param [1, []];
_args params ["_medic", "_patient", "_bodyPart", "_classname"];
private _hook = [_classname, configFile >> "ace_medical_treatment_actions"] call PMCI_fnc_hookOf;
if (_hook isEqualTo []) exitWith {10};
(_hook select 1) params ["_game", "_time", "_timeTrained"];
if ([_medic, _game] call PMCI_fnc_plays) exitWith {missionNamespace getVariable ["PMCI_prepTime", 1]};
private _value = if (_trained && {_timeTrained != ""} && {!isNil _timeTrained}) then {[_timeTrained, _args] call PMCI_fnc_original} else {[_time, _args] call PMCI_fnc_original};
if (isNil "_value") then {10} else {_value}
