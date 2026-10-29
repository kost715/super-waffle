// ACE "callbackSuccess" of the taken-over repairs, after the preparation bar.
// [caller, vehicle, hit point, action, items, item users, claimed objects]
private _args = +_this;
_args params ["_caller", "_vehicle", "_hitPoint", "_className", "", "", ["_claimed", []]];
private _hook = [_className, configFile >> "ACE_Repair" >> "Actions"] call PMCI_fnc_hookOf;
if (_hook isEqualTo []) exitWith {diag_log text format ["[PMCI] ERROR: no ACE callback known for repair %1", _className]};
(_hook select 1) params ["_game", "", "", "_success"];
_game = [_vehicle, _hitPoint, _game] call PMCI_fnc_repairGame;
if !((_hook select 0) == _className && {[_caller, _game] call PMCI_fnc_plays}) exitWith {[_success, _args] call PMCI_fnc_original};
// ACE released the spare wheel or track when its bar ended: hold it again during the game.
{[_caller, _x, false] call ace_common_fnc_claim} forEach _claimed;
[_game, _args, "repair"] call PMCI_fnc_boardOpen;
