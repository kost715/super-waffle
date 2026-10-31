// [mode, state, value] -> state. Picking a lock with picks and a tension wrench: the mouse
// moves the active pick around the top half of the keyhole (0 = right, 90 = up, 180 =
// left); holding the press key turns the plug. A hard lock has two picks, each with its
// own hidden sweet spot; the fix key switches between them, and the other pick stays
// where it was left. The plug turns all the way only with every pick at its spot (within
// the zone of it); further away a pick stops it earlier, past zone + falloff it does not
// turn at all, and the pick that stops it soonest is the one under strain. The picks stay
// where they are while the plug turns. Forcing the plug against its stop strains that pick:
// after `life` seconds of strain in all it breaks, one pick is used up and the plug springs
// back. The plug turned fully opens the lock; too few picks left to fill the lock, or the
// time limit, fail. Quality drops by 20% per broken pick.
//   "init" value [sweet spots deg (one per pick in the lock), zone deg, falloff deg,
//                 turn per s, pick life s, picks carried (-1: any number), time limit s]
//   "tick" value seconds;  "press" / "release" the turning key;  "fix" switches the pick;
//   "mouse" value [x, y, distance, held, seconds] in scene pixels, keyhole at (512, 300);
//           only a mouse that moved turns the pick
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_sweets", "_zone", "_falloff", "_speed", "_life", "_picks", "_limit"];
        // Two picks start apart, so both can be seen.
        private _angles = [[90], [60, 120]] select (count _sweets > 1);
        _state = createHashMapFromArray [["t", 0], ["sweets", _sweets], ["zone", _zone], ["falloff", _falloff], ["speed", _speed],
            ["life", _life], ["picks", _picks], ["limit", _limit], ["angles", _angles], ["active", 0], ["turn", 0], ["turning", false],
            ["strained", -1], ["wear", 0], ["broken", 0], ["brokeAt", -10], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {
        if ((_state get "status") != "running" || {_state get "turning"}) exitWith {};
        _value params ["_x0", "_y0", ["_distance", 0]];
        if (_distance <= 0) exitWith {};
        // Below the keyhole the pick stays at the nearer end of its half circle.
        private _angle = if (_y0 >= 300) then {[0, 180] select (_x0 < 512)} else {(300 - _y0) atan2 (_x0 - 512)};
        (_state get "angles") set [_state get "active", 0 max (_angle min 180)];
    };
    case "fix": {
        if ((_state get "status") != "running" || {_state get "turning"}) exitWith {};
        _state set ["active", ((_state get "active") + 1) % count (_state get "sweets")];
    };
    case "press": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["turning", true];
    };
    case "release": {
        _state set ["turning", false];
        _state set ["strained", -1];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        if (_state get "turning") then {
            // The pick furthest from its spot decides where the plug stops.
            private _stop = 2;
            private _weakest = 0;
            {
                private _off = abs (((_state get "angles") select _forEachIndex) - _x);
                private _pickStop = 0 max (1 - (0 max (_off - (_state get "zone"))) / (_state get "falloff"));
                if (_pickStop < _stop) then {_stop = _pickStop; _weakest = _forEachIndex};
            } forEach (_state get "sweets");
            private _turn = (_state get "turn") + (_state get "speed") * _value;
            if (_stop < 1 && {_turn >= _stop}) then {
                _state set ["turn", _stop];
                _state set ["strained", _weakest];
                _state set ["wear", (_state get "wear") + _value];
                if ((_state get "wear") >= (_state get "life")) then {
                    _state set ["broken", (_state get "broken") + 1];
                    _state set ["brokeAt", _t];
                    _state set ["wear", 0];
                    _state set ["turn", 0];
                    _state set ["turning", false];
                    _state set ["strained", -1];
                    if ((_state get "picks") >= 0) then {
                        _state set ["picks", 0 max ((_state get "picks") - 1)];
                        if ((_state get "picks") < count (_state get "sweets")) then {_state set ["status", "fail"]};
                    };
                };
            } else {
                _state set ["turn", _turn min 1];
                _state set ["strained", -1];
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
