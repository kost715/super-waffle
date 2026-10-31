// ACE "repairingTime" of the taken-over repairs: [caller, vehicle, hit point, action].
params ["_caller", "_vehicle", "_hitPoint", "_className"];
private _hook = [_className, configFile >> "ACE_Repair" >> "Actions"] call PMCI_fnc_hookOf;
if (_hook isEqualTo []) exitWith {10};
(_hook select 1) params ["_game", "_time"];
_game = [_vehicle, _hitPoint, _game] call PMCI_fnc_repairGame;
// Only the class itself plays: PatchWheel inherits this time from ReplaceWheel.
if ((_hook select 0) == _className && {[_caller, _game] call PMCI_fnc_plays}) exitWith {missionNamespace getVariable ["PMCI_prepTime", 1]};
private _value = [_time, _this] call PMCI_fnc_original;
if (isNil "_value") then {10} else {_value}
