// [mode, state, value] -> state. Patching a fuel tank: the hull patch weld (PMCI_fnc_weldModel)
// on a tank, with one rule more. The fuel must be drained first ("fix": the "Drain fuel"
// button or the fix key; draining takes `drain` seconds). The torch touching the crack while
// fuel is still in the tank - not drained, or still draining - sets it off: the game fails
// and "exploded" is set (PMCI_fnc_finish blows up the vehicle). A tank that was already
// empty needs no draining.
//   "init" value [seam, tolerance px, speed min px/s, speed max px/s, time limit s,
//                 heat per s when slow, drain time s, tank empty]
//   "tick" value seconds;  "fix" starts draining;  "mouse" value [x, y, distance, held, seconds]
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_seam", "_tolerance", "_slow", "_fast", "_limit", "_heatRate", "_drain", ["_empty", false]];
        _state = ["init", nil, [_seam, _tolerance, _slow, _fast, _limit, _heatRate]] call PMCI_fnc_weldModel;
        _state set ["drain", _drain];
        _state set ["drained", _empty];
        _state set ["draining", -1];
        _state set ["exploded", false];
    };
    case "fix": {
        if ((_state get "status") != "running" || {_state get "drained"} || {(_state get "draining") >= 0}) exitWith {};
        _state set ["draining", _state get "t"];
    };
    case "tick": {
        [_mode, _state, _value] call PMCI_fnc_weldModel;
        if ((_state get "draining") >= 0 && {!(_state get "drained")} && {(_state get "t") - (_state get "draining") >= (_state get "drain")}) then {
            _state set ["drained", true];
        };
    };
    case "mouse": {
        if ((_state get "status") != "running") exitWith {};
        _value params ["_x0", "_y0", "", "_held"];
        if (_held && {!(_state get "drained")}) then {
            // Anywhere on the crack, not only where the bead would go on.
            private _seam = _state get "seam";
            private _near = false;
            for "_i" from 1 to count _seam - 1 do {
                (_seam select (_i - 1)) params ["_ax", "_ay"];
                (_seam select _i) params ["_bx", "_by"];
                private _len2 = ((_bx - _ax) ^ 2 + (_by - _ay) ^ 2) max 1e-6;
                private _u = 0 max (((_x0 - _ax) * (_bx - _ax) + (_y0 - _ay) * (_by - _ay)) / _len2) min 1;
                if (((_x0 - _ax - _u * (_bx - _ax)) ^ 2 + (_y0 - _ay - _u * (_by - _ay)) ^ 2) <= (_state get "tolerance") ^ 2) exitWith {_near = true};
            };
            if (_near) then {
                _state set ["exploded", true];
                _state set ["status", "fail"];
            };
        };
        if ((_state get "status") == "running") then {[_mode, _state, _value] call PMCI_fnc_weldModel};
    };
};
_state
