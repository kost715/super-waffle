// [mode, state, value] -> state. Stitching: the needle follows the mouse; a click near the
// highlighted stitch point passes the needle there and the next point lights up. Points go
// across the wound in pairs, one stitch per pair. A click far from the point is a miss.
// Quality: half from how close the clicks were, minus 15% per miss.
//   "init" value [points [[x, y], ...] in scene pixels, radius px, time limit s, misses allowed]
//   "tick" value seconds;  "mouse" value [x, y, ...];  "click" value [x, y]
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_points", "_radius", "_limit", "_allowed"];
        _state = createHashMapFromArray [["t", 0], ["points", _points], ["radius", _radius], ["limit", _limit], ["allowed", _allowed],
            ["next", 0], ["accuracy", 0], ["misses", 0], ["mouse", [0, 0]], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {_state set ["mouse", [_value select 0, _value select 1]]};
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["t", (_state get "t") + _value];
        if ((_state get "t") >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
    case "click": {
        if ((_state get "status") != "running") exitWith {};
        _value params ["_x0", "_y0"];
        private _points = _state get "points";
        ((_points select (_state get "next"))) params ["_px", "_py"];
        private _distance = sqrt ((_x0 - _px) ^ 2 + (_y0 - _py) ^ 2);
        if (_distance > (_state get "radius")) exitWith {
            _state set ["misses", (_state get "misses") + 1];
            if ((_state get "misses") > (_state get "allowed")) then {_state set ["status", "fail"]};
        };
        _state set ["accuracy", (_state get "accuracy") + 1 - _distance / (_state get "radius")];
        _state set ["next", (_state get "next") + 1];
        if ((_state get "next") == count _points) then {
            _state set ["status", "success"];
            _state set ["quality", 0.2 max ((0.5 + 0.5 * (_state get "accuracy") / count _points - 0.15 * (_state get "misses")) min 1)];
        };
    };
};
_state
