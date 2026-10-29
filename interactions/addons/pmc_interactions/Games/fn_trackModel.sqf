// [mode, state, value] -> state. Joining a track: the loose link swings up and down; a
// press while its pin hole lines up (within the tolerance) holds it in place. Then the
// pin is driven in: a power marker runs up and down, and each press in the green zone is
// a good hit. Enough hits succeed. A press at the wrong moment is a miss; one miss too
// many or the time limit fail. Quality drops by 15% per miss.
//   "init" value [swing px, tolerance px, swings per s, hits, zone low, zone high,
//                 marker runs per s, time limit s, misses allowed]
//   "tick" value seconds;  "press" one press
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_swing", "_tolerance", "_rate", "_hits", "_low", "_high", "_speed", "_limit", "_allowed"];
        _state = createHashMapFromArray [["t", 0], ["swing", _swing], ["tolerance", _tolerance], ["rate", _rate], ["hits", _hits],
            ["low", _low], ["high", _high], ["speed", _speed], ["limit", _limit], ["allowed", _allowed], ["phase", "align"],
            ["offset", 0], ["power", 0], ["pinAt", 0], ["done", 0], ["misses", 0], ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        if ((_state get "phase") == "align") then {
            _state set ["offset", (_state get "swing") * sin (_t * 360 * (_state get "rate"))];
        } else {
            // Triangle wave 0 -> 1 -> 0, from the moment the link was held.
            private _p = ((_t - (_state get "pinAt")) * (_state get "speed")) % 2;
            _state set ["power", [_p, 2 - _p] select (_p > 1)];
        };
        if (_t >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
    case "press": {
        if ((_state get "status") != "running") exitWith {};
        private _hit = if ((_state get "phase") == "align") then {
            abs (_state get "offset") <= (_state get "tolerance")
        } else {
            (_state get "power") >= (_state get "low") && {(_state get "power") <= (_state get "high")}
        };
        if (!_hit) exitWith {
            _state set ["misses", (_state get "misses") + 1];
            if ((_state get "misses") > (_state get "allowed")) then {_state set ["status", "fail"]};
        };
        if ((_state get "phase") == "align") exitWith {
            _state set ["phase", "pin"];
            _state set ["offset", 0];
            _state set ["pinAt", _state get "t"];
        };
        _state set ["done", (_state get "done") + 1];
        if ((_state get "done") >= (_state get "hits")) then {
            _state set ["status", "success"];
            _state set ["quality", 0.2 max (1 - 0.15 * (_state get "misses"))];
        };
    };
};
_state
