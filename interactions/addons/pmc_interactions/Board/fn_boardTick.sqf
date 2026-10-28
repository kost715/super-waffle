// Per frame, client: advances the game, watches the situation, redraws, ends the game.
if (isNil "PMCI_board") exitWith {};
private _now = diag_tickTime;
private _dt = (_now - (PMCI_board get "last")) min 0.25;
PMCI_board set ["last", _now];
private _state = PMCI_board get "state";
["tick", _state, _dt] call (missionNamespace getVariable format ["PMCI_fnc_%1Model", PMCI_board get "game"]);
PMCI_board set ["depth", 0 max ((PMCI_board get "depth") - _dt * 3)];
if !(call PMCI_fnc_boardValid) exitWith {[false] call PMCI_fnc_finish};
if ((_state get "status") != "running") exitWith {[(_state get "status") == "success"] call PMCI_fnc_finish};
call PMCI_fnc_boardDraw;
