// [mode, state, value] -> state. Picking a lock with a pick and a tension wrench: the mouse
// moves the pick around the top half of the keyhole (0 = right, 90 = up, 180 = left);
// holding the press key turns the plug. The plug turns all the way only with the pick at
// the hidden sweet spot (within the zone of it); further away it stops earlier, past zone +
// falloff it does not turn at all. The pick stays where it is while the plug turns. Forcing
// the plug against its stop strains the pick: after `life` seconds of strain in all it
// breaks, one pick is used up and the plug springs back. The plug turned fully opens the
// lock; the last pick broken or the time limit fail. Quality drops by 20% per broken pick.
//   "init" value [sweet spot deg, zone deg, falloff deg, turn per s, pick life s,
//                 picks (-1: any number), time limit s]
//   "tick" value seconds;  "press" / "release" the turning key;
//   "mouse" value [x, y, distance, held, seconds] in scene pixels, keyhole at (512, 300)
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_sweet", "_zone", "_falloff", "_speed", "_life", "_picks", "_limit"];
        _state = createHashMapFromArray [["t", 0], ["sweet", _sweet], ["zone", _zone], ["falloff", _falloff], ["speed", _speed],
            ["life", _life], ["picks", _picks], ["limit", _limit], ["angle", 90], ["turn", 0], ["turning", false], ["strained", false],
            ["wear", 0], ["broken", 0], ["brokeAt", -10], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {
        if ((_state get "status") != "running" || {_state get "turning"}) exitWith {};
        _value params ["_x0", "_y0"];
        // Below the keyhole the pick stays at the nearer end of its half circle.
        private _angle = if (_y0 >= 300) then {[0, 180] select (_x0 < 512)} else {(300 - _y0) atan2 (_x0 - 512)};
        _state set ["angle", 0 max (_angle min 180)];
    };
    case "press": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["turning", true];
    };
    case "release": {
        _state set ["turning", false];
        _state set ["strained", false];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        if (_state get "turning") then {
            private _off = abs ((_state get "angle") - (_state get "sweet"));
            private _stop = 0 max (1 - (0 max (_off - (_state get "zone"))) / (_state get "falloff"));
            private _turn = (_state get "turn") + (_state get "speed") * _value;
            if (_stop < 1 && {_turn >= _stop}) then {
                _state set ["turn", _stop];
                _state set ["strained", true];
                _state set ["wear", (_state get "wear") + _value];
                if ((_state get "wear") >= (_state get "life")) then {
                    _state set ["broken", (_state get "broken") + 1];
                    _state set ["brokeAt", _t];
                    _state set ["wear", 0];
                    _state set ["turn", 0];
                    _state set ["turning", false];
                    _state set ["strained", false];
                    if ((_state get "picks") > 0) then {
                        _state set ["picks", (_state get "picks") - 1];
                        if ((_state get "picks") == 0) then {_state set ["status", "fail"]};
                    };
                };
            } else {
                _state set ["turn", _turn min 1];
                _state set ["strained", false];
            };
        } else {
            _state set ["turn", 0 max ((_state get "turn") - 2 * (_state get "speed") * _value)];
        };
        if ((_state get "status") != "running") exitWith {};
        if ((_state get "turn") >= 1) exitWith {
            _state set ["status", "success"];
            _state set ["quality", 0.2 max (1 - 0.2 * (_state get "broken"))];
        };
        if (_t >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
};
_state
