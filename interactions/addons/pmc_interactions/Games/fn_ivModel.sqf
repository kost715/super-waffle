// [mode, state, value] -> state. Placing an IV: the needle tip follows the mouse with a
// slight tremor; holding the mouse button pushes the needle in while the tip stays on the
// vein. Slipping off the vein while pushing blows the vein: a miss, the needle comes out
// and must be pushed again. Too many misses or the time limit fail; quality drops by a
// quarter for every miss.
//   "init" value [vein [x0, y0, x1, y1] in scene pixels, tolerance px, insert time s,
//                 time limit s, misses allowed, tremor px]
//   "tick" value seconds;  "mouse" value [x, y, distance, held, seconds]
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_vein", "_tolerance", "_insert", "_limit", "_allowed", "_tremor"];
        _state = createHashMapFromArray [["t", 0], ["vein", _vein], ["tolerance", _tolerance], ["insert", _insert], ["limit", _limit],
            ["allowed", _allowed], ["tremor", _tremor], ["mouse", [0, 0]], ["tip", [0, 0]], ["held", false], ["pushing", false],
            ["depth", 0], ["misses", 0], ["lastMiss", []], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {
        _value params ["_x0", "_y0", "", "_held"];
        _state set ["mouse", [_x0, _y0]];
        // A fresh press starts pushing; letting go pulls the needle back out.
        if (_held && {!(_state get "held")}) then {_state set ["pushing", true]};
        if (!_held) then {_state set ["pushing", false]; _state set ["depth", 0]};
        _state set ["held", _held];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        (_state get "mouse") params ["_mx", "_my"];
        private _tremor = _state get "tremor";
        private _tip = [_mx + _tremor * sin (_t * 317), _my + _tremor * cos (_t * 241)];
        _state set ["tip", _tip];
        if (_state get "pushing") then {
            (_state get "vein") params ["_ax", "_ay", "_bx", "_by"];
            private _len = (_bx - _ax) ^ 2 + (_by - _ay) ^ 2;
            private _u = 0 max ((((_tip select 0) - _ax) * (_bx - _ax) + ((_tip select 1) - _ay) * (_by - _ay)) / (_len max 1e-6)) min 1;
            private _off = sqrt (((_tip select 0) - _ax - _u * (_bx - _ax)) ^ 2 + ((_tip select 1) - _ay - _u * (_by - _ay)) ^ 2);
            if (_off <= (_state get "tolerance")) then {
                _state set ["depth", ((_state get "depth") + _value / (_state get "insert")) min 1];
                if ((_state get "depth") >= 1) then {
                    _state set ["status", "success"];
                    _state set ["quality", 0.25 max (1 - 0.25 * (_state get "misses"))];
                };
            } else {
                _state set ["misses", (_state get "misses") + 1];
                _state set ["lastMiss", _tip];
                _state set ["pushing", false];
                _state set ["depth", 0];
                if ((_state get "misses") > (_state get "allowed")) then {_state set ["status", "fail"]};
            };
        };
        if ((_state get "status") == "running" && {_t >= (_state get "limit")}) then {_state set ["status", "fail"]};
    };
};
_state
