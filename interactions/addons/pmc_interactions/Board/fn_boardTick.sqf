// Per frame, client: feeds the mouse, advances the game, watches the situation,
// redraws, ends the game.
if (isNil "PMCI_board") exitWith {};
private _now = diag_tickTime;
private _dt = (_now - (PMCI_board get "last")) min 0.25;
PMCI_board set ["last", _now];
private _state = PMCI_board get "state";
private _game = PMCI_board get "game";
private _model = missionNamespace getVariable format ["PMCI_fnc_%1Model", _game];
// Mouse games: where the mouse is, how far it moved since the last frame, whether the
// button is held. Cleaning only counts the path while scrubbing.
if (_game in ["clean", "iv", "suture", "splint", "weld", "lockpick", "safe"]) then {
    private _mouse = call PMCI_fnc_boardMouse;
    (PMCI_board getOrDefault ["mouse", _mouse]) params ["_fromX", "_fromY"];
    private _distance = sqrt (((_mouse select 0) - _fromX) ^ 2 + ((_mouse select 1) - _fromY) ^ 2);
    private _held = PMCI_board getOrDefault ["scrubbing", false];
    if (_game == "clean") then {
        if (_held && {_distance > 0}) then {["scrub", _state, [_mouse select 0, _mouse select 1, _distance]] call _model};
    } else {
        ["mouse", _state, [_mouse select 0, _mouse select 1, _distance, _held, _dt]] call _model;
    };
    PMCI_board set ["mouse", _mouse];
};
["tick", _state, _dt] call _model;
// A pick broken in the lock is gone from the inventory at once.
if (_game == "lockpick" && {(_state get "broken") > (PMCI_board getOrDefault ["used", 0])}) then {
    PMCI_board set ["used", _state get "broken"];
    [(PMCI_board get "args") select 0, ["classic"] call PMCI_fnc_lockTool] call PMCI_fnc_itemTake;
};
PMCI_board set ["depth", 0 max ((PMCI_board get "depth") - _dt * 3)];
// A lock game that ended stays open 1.5 s to show its result, whatever happens meanwhile.
if ((PMCI_board get "kind") == "lock" && {(_state get "status") != "running"}) exitWith {
    private _closeAt = PMCI_board getOrDefault ["closeAt", -1];
    if (_closeAt < 0) then {PMCI_board set ["closeAt", _now + 1.5]};
    if (_closeAt >= 0 && {_now >= _closeAt}) exitWith {[(_state get "status") == "success"] call PMCI_fnc_finish};
    call PMCI_fnc_boardDraw;
};
if !(call PMCI_fnc_boardValid) exitWith {[false] call PMCI_fnc_finish};
if ((_state get "status") != "running") exitWith {[(_state get "status") == "success"] call PMCI_fnc_finish};
call PMCI_fnc_boardDraw;
