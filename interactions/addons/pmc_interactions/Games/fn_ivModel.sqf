// [mode, state, value] -> state. Placing an IV: the needle tip follows the mouse with a
// slight tremor. A fresh press with the tip on the vein pierces it there: from then on the
// needle stays at that point and slides in while the button is held, as long as the hand
// stays steady (the mouse within the tolerance of where it pressed). A press
// off the vein, or the mouse moving away while pushing, blows the vein: a miss, the needle
// comes out and must be pushed again with a fresh press. Too many misses or the time limit
// fail; quality drops by a quarter for every miss.
//   "init" value [vein [x0, y0, x1, y1] in scene pixels, tolerance px, insert time s,
//                 time limit s, misses allowed, tremor px]
//   "tick" value seconds;  "mouse" value [x, y, distance, held, seconds]
// "entry" is where the needle pierced the vein ([] while it is out); "tip" is where the
// needle's tip is drawn: at the trembling mouse, or sliding in from the entry.
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_vein", "_tolerance", "_insert", "_limit", "_allowed", "_tremor"];
        _state = createHashMapFromArray [["t", 0], ["vein", _vein], ["tolerance", _tolerance], ["insert", _insert], ["limit", _limit],
            ["allowed", _allowed], ["tremor", _tremor], ["mouse", [0, 0]], ["tip", [0, 0]], ["held", false], ["pushing", false],
            ["depth", 0], ["entry", []], ["anchor", []], ["misses", 0], ["lastMiss", []], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {
        _value params ["_x0", "_y0", "", "_held"];
        _state set ["mouse", [_x0, _y0]];
        // A fresh press starts pushing; letting go pulls the needle back out.
        if (_held && {!(_state get "held")}) then {_state set ["pushing", true]};
        if (!_held) then {_state set ["pushing", false]; _state set ["depth", 0]; _state set ["entry", []]};
        _state set ["held", _held];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        (_state get "mouse") params ["_mx", "_my"];
        private _tremor = _state get "tremor";
        private _hand = [_mx + _tremor * sin (_t * 317), _my + _tremor * cos (_t * 241)];
        _state set ["tip", _hand];
        if (_state get "pushing") then {
            private _miss = false;
            if ((_state get "entry") isEqualTo []) then {
                // The press: the tip must be on the vein; the needle goes in at the nearest point.
                (_state get "vein") params ["_ax", "_ay", "_bx", "_by"];
                private _len = (_bx - _ax) ^ 2 + (_by - _ay) ^ 2;
                private _u = 0 max ((((_hand select 0) - _ax) * (_bx - _ax) + ((_hand select 1) - _ay) * (_by - _ay)) / (_len max 1e-6)) min 1;
                private _on = [_ax + _u * (_bx - _ax), _ay + _u * (_by - _ay)];
                if ((_hand distance2D _on) <= (_state get "tolerance")) then {
                    _state set ["entry", _on];
                    _state set ["anchor", [_mx, _my]];
                } else {_miss = true};
            } else {
                // Pushing: the hand (the mouse) must stay where it pressed.
                if (([_mx, _my] distance2D (_state get "anchor")) > (_state get "tolerance")) then {_miss = true};
            };
            if (_miss) exitWith {
                _state set ["misses", (_state get "misses") + 1];
                _state set ["lastMiss", _hand];
                _state set ["pushing", false];
                _state set ["depth", 0];
                _state set ["entry", []];
                if ((_state get "misses") > (_state get "allowed")) then {_state set ["status", "fail"]};
            };
            _state set ["depth", ((_state get "depth") + _value / (_state get "insert")) min 1];
            // The needle slides in along its own line (it comes from the upper right at 40 degrees).
            (_state get "entry") params ["_ex", "_ey"];
            _state set ["tip", [_ex - 30 * (_state get "depth") * cos 40, _ey + 30 * (_state get "depth") * sin 40]];
            if ((_state get "depth") >= 1) then {
                _state set ["status", "success"];
                _state set ["quality", 0.25 max (1 - 0.25 * (_state get "misses"))];
            };
        };
        if ((_state get "status") == "running" && {_t >= (_state get "limit")}) then {_state set ["status", "fail"]};
    };
};
_state
