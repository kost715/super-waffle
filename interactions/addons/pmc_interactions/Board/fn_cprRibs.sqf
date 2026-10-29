// Client, after each CPR compression: one faster than the accepted rhythm may break a rib
// (CBA chance, at most PMCI_ribMax per CPR). The rib is an ACE wound on the patient's
// chest, made where the patient is local (PMCI_fnc_events).
if (isNil "PMCI_board") exitWith {};
private _state = PMCI_board get "state";
if !(_state getOrDefault ["lastFast", false]) exitWith {};
private _ribs = PMCI_board getOrDefault ["ribs", 0];
if (_ribs >= (missionNamespace getVariable ["PMCI_ribMax", 1]) || {random 1 >= (missionNamespace getVariable ["PMCI_ribChance", 0.15])}) exitWith {};
PMCI_board set ["ribs", _ribs + 1];
PMCI_board set ["crackAt", _state get "t"];
(PMCI_board get "args") params ["_medic", "_patient"];
["PMCI_ribFracture", [_patient, _medic], _patient] call CBA_fnc_targetEvent;
