#include "..\ui_defines.hpp"
// [event, value] -> handled. Client. Input from the board: keys (the "press" key presses
// or holds, the "fix" key fixes, both set in CBA's controls; Esc gives up), the hold button, the fix button, nut and swap buttons,
// the mouse on the scene (scrubbing, aiming, stitching, setting a bone, welding, turning a
// lock's plug or a safe's dial) and the terminal's rows (picked by a double click or the press key).
params ["_event", ["_value", 0]];
if (isNil "PMCI_board") exitWith {false};
private _game = PMCI_board get "game";
private _model = missionNamespace getVariable format ["PMCI_fnc_%1Model", _game];
private _state = PMCI_board get "state";
// One press per key stroke for CPR compressions, placing strips, driving a pin and the
// locks (a broken pick needs a new press); the others hold.
private _press = {
    if (_game == "terminal") exitWith {["pick", _state, PMCI_board getOrDefault ["selected", -1]] call _model};
    ["press", _state] call _model;
    if (_game == "cpr") then {
        PMCI_board set ["depth", 1];
        call PMCI_fnc_cprRibs;
    };
};
switch (_event) do {
    case "onLoad": {uiNamespace setVariable ["PMCI_display", _value]; [_value] call PMCI_fnc_boardLayout; call PMCI_fnc_boardDraw};
    case "onUnload": {
        uiNamespace setVariable ["PMCI_display", displayNull];
        // Closed by Esc or anything else while the game still ran: it is given up. The RPT
        // line tells a player's Esc apart from another window closing the board.
        if ((_state get "status") == "running") then {
            diag_log text format ["[PMCI] board %1 closed while running (Esc, Cancel or another window)", _game];
            [false] call PMCI_fnc_finish;
        };
    };
    case "keyDown": {
        _value params ["", "_key", ["_shift", false], ["_ctrl", false], ["_alt", false]];
        if (["press", _key, [_shift, _ctrl, _alt]] call PMCI_fnc_keyIs) exitWith {
            // Holding the key repeats keyDown; a tapping game only counts the first.
            if !(_game in ["cpr", "edges", "track", "lockpick", "terminal", "safe"] && {PMCI_board getOrDefault ["spaceDown", false]}) then {call _press};
            PMCI_board set ["spaceDown", true];
            true
        };
        if (_game == "tourniquet" && {["fix", _key, [_shift, _ctrl, _alt]] call PMCI_fnc_keyIs}) exitWith {["fix", _state] call _model; true};
        false
    };
    case "keyUp": {
        _value params ["", "_key"];
        if (["press", _key] call PMCI_fnc_keyIs) exitWith {PMCI_board set ["spaceDown", false]; ["release", _state] call _model; true};
        false
    };
    case "holdDown": {call _press};
    case "holdUp": {["release", _state] call _model};
    case "fix": {["fix", _state] call _model};
    case "nut": {[["nut", "test"] select (_game == "diagnose"), _state, _value] call _model};
    case "swap": {["swap", _state] call _model};
    case "scrubDown": {
        private _mouse = call PMCI_fnc_boardMouse;
        PMCI_board set ["scrubbing", true];
        PMCI_board set ["mouse", _mouse];
        // The plug of a lock also turns while the mouse is held on the scene.
        if (_game == "lockpick") then {["press", _state] call _model};
    };
    case "scrubUp": {
        if (_game == "lockpick" && {PMCI_board getOrDefault ["scrubbing", false]}) then {["release", _state] call _model};
        PMCI_board set ["scrubbing", false];
    };
    case "select": {PMCI_board set ["selected", _value]};
    case "pick": {
        PMCI_board set ["selected", _value];
        ["pick", _state, _value] call _model;
    };
    case "cancel": {closeDialog 2};
};
true
