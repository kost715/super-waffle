// Per frame, client: advances the game (and the scrubbing), watches the situation,
// redraws, ends the game.
if (isNil "PMCI_board") exitWith {};
private _now = diag_tickTime;
private _dt = (_now - (PMCI_board get "last")) min 0.25;
PMCI_board set ["last", _now];
private _state = PMCI_board get "state";
private _model = missionNamespace getVariable format ["PMCI_fnc_%1Model", PMCI_board get "game"];
["tick", _state, _dt] call _model;
// Scrubbing: the mouse path since the last frame wears the dirt under it.
if (PMCI_board getOrDefault ["scrubbing", false]) then {
    private _mouse = call PMCI_fnc_boardMouse;
    (PMCI_board get "mouse") params ["_fromX", "_fromY"];
    private _distance = sqrt (((_mouse select 0) - _fromX) ^ 2 + ((_mouse select 1) - _fromY) ^ 2);
    if (_distance > 0) then {["scrub", _state, [_mouse select 0, _mouse select 1, _distance]] call _model};
    PMCI_board set ["mouse", _mouse];
};
PMCI_board set ["depth", 0 max ((PMCI_board get "depth") - _dt * 3)];
if !(call PMCI_fnc_boardValid) exitWith {[false] call PMCI_fnc_finish};
if ((_state get "status") != "running") exitWith {[(_state get "status") == "success"] call PMCI_fnc_finish};
call PMCI_fnc_boardDraw;
