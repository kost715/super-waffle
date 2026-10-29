// [mode, state, value] -> state. Setting a fracture before the splint: the broken part sits
// at an angle; dragging the mouse sideways with the button held turns it, while muscle
// spasm keeps pushing it away from straight. Held within the tolerance long enough, it is
// set and splinted; leaving the tolerance restarts the count. Quality falls with time.
//   "init" value [start angle deg, tolerance deg, hold time s, time limit s,
//                 spasm deg/s, deg per dragged pixel]
//   "tick" value seconds;  "mouse" value [x, y, distance, held, seconds]
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_angle", "_tolerance", "_hold", "_limit", "_spasm", "_gain"];
        _state = createHashMapFromArray [["t", 0], ["angle", _angle], ["tolerance", _tolerance], ["hold", _hold], ["limit", _limit],
            ["spasm", _spasm], ["gain", _gain], ["lastX", -1], ["aligned", 0], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {
        _value params ["_x0", "", "", "_held"];
        if (_held && {(_state get "lastX") >= 0}) then {
            _state set ["angle", -45 max (((_state get "angle") - (_x0 - (_state get "lastX")) * (_state get "gain")) min 45)];
        };
        _state set ["lastX", [-1, _x0] select _held];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        // The spasm pulls away from straight, a little harder in waves.
        private _angle = _state get "angle";
        private _away = [-1, 1] select (_angle >= 0);
        _angle = _angle + _away * (_state get "spasm") * (1 + 0.5 * sin (_t * 120)) * _value;
        _state set ["angle", -45 max (_angle min 45)];
        if (abs (_state get "angle") <= (_state get "tolerance")) then {
            _state set ["aligned", (_state get "aligned") + _value];
        } else {
            _state set ["aligned", 0];
        };
        if ((_state get "aligned") >= (_state get "hold")) exitWith {
            _state set ["status", "success"];
            _state set ["quality", 1 min (1 - 0.6 * (0 max (_t / (_state get "limit") - 0.3)))];
        };
        if (_t >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
};
_state
