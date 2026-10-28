// ACE "callbackSuccess" of the taken-over treatments, after the preparation bar.
// [medic, patient, body part, treatment, item user, used item, create litter]
// Opens the game for the player; otherwise applies ACE's own result at once.
private _args = +_this;
_args params ["_medic", "_patient", "_bodyPart", "_classname"];
private _hook = [_classname, configFile >> "ace_medical_treatment_actions"] call PMCI_fnc_hookOf;
if (_hook isEqualTo []) exitWith {diag_log text format ["[PMCI] ERROR: no ACE callback known for treatment %1", _classname]};
(_hook select 1) params ["_game", "", "", "_success"];
if !([_medic, _game] call PMCI_fnc_plays) exitWith {[_success, _args] call PMCI_fnc_original};
[_game, _args, "medical"] call PMCI_fnc_boardOpen;
