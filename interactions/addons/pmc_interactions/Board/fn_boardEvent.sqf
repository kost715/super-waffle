#include "..\ui_defines.hpp"
// [event, value] -> handled. Client. Input from the board: keys (Space holds, Enter
// fixes, Esc gives up), the hold button, the fix button, nut and swap buttons.
params ["_event", ["_value", 0]];
if (isNil "PMCI_board") exitWith {false};
private _game = PMCI_board get "game";
private _model = missionNamespace getVariable format ["PMCI_fnc_%1Model", _game];
private _state = PMCI_board get "state";
switch (_event) do {
    case "onLoad": {uiNamespace setVariable ["PMCI_display", _value]; call PMCI_fnc_boardDraw};
    case "onUnload": {
        uiNamespace setVariable ["PMCI_display", displayNull];
        // Closed by Esc or anything else while the game still ran: it is given up.
        if ((_state get "status") == "running") then {[false] call PMCI_fnc_finish};
    };
    case "keyDown": {
        _value params ["", "_key"];
        if (_key == 57) exitWith {
            if (_game == "cpr") then {if !(PMCI_board getOrDefault ["spaceDown", false]) then {["press", _state] call _model; PMCI_board set ["depth", 1]}} else {["press", _state] call _model};
            PMCI_board set ["spaceDown", true];
            true
        };
        if (_key in [28, 156] && {_game == "tourniquet"}) exitWith {["fix", _state] call _model; true};
        false
    };
    case "keyUp": {
        _value params ["", "_key"];
        if (_key == 57) exitWith {PMCI_board set ["spaceDown", false]; ["release", _state] call _model; true};
        false
    };
    case "holdDown": {
        ["press", _state] call _model;
        if (_game == "cpr") then {PMCI_board set ["depth", 1]};
    };
    case "holdUp": {["release", _state] call _model};
    case "fix": {["fix", _state] call _model};
    case "nut": {["nut", _state, _value] call _model};
    case "swap": {["swap", _state] call _model};
    case "cancel": {closeDialog 2};
};
true
