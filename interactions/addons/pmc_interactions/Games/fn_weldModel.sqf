// [mode, state, value] -> state. Welding a patch over a hull crack: with the mouse button
// held, the torch lays the bead along the seam where it is on the line and at the end of
// the bead laid so far. Too fast leaves a weak bead (it counts, but lowers the quality);
// too slow, or standing still on the seam, heats the plate until it burns through, which
// fails. The whole seam laid succeeds; quality is the share laid at a good speed.
//   "init" value [seam [[x, y], ...] in scene pixels, tolerance px, speed min px/s,
//                 speed max px/s, time limit s, heat per s when slow]
//   "tick" value seconds;  "mouse" value [x, y, distance, held, seconds]
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_seam", "_tolerance", "_slow", "_fast", "_limit", "_heatRate"];
        private _lengths = [];
        private _total = 0;
        for "_i" from 1 to count _seam - 1 do {
            private _a = _seam select (_i - 1);
            private _b = _seam select _i;
            _total = _total + sqrt (((_b select 0) - (_a select 0)) ^ 2 + ((_b select 1) - (_a select 1)) ^ 2);
            _lengths pushBack _total;
        };
        _state = createHashMapFromArray [["t", 0], ["seam", _seam], ["lengths", _lengths], ["total", _total], ["tolerance", _tolerance],
            ["slow", _slow], ["fast", _fast], ["limit", _limit], ["heatRate", _heatRate], ["covered", 0], ["good", 0], ["heat", 0],
            ["mouse", [0, 0]], ["held", false], ["onSeam", false], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {
        if ((_state get "status") != "running") exitWith {};
        _value params ["_x0", "_y0", "_distance", "_held", ["_dt", 0]];
        _state set ["mouse", [_x0, _y0]];
        _state set ["held", _held];
        _state set ["onSeam", false];
        if (!_held) exitWith {};
        // Nearest point of the seam: its position along the seam (0-1) and the distance to it.
        private _seam = _state get "seam";
        private _best = [1e9, 0];
        for "_i" from 1 to count _seam - 1 do {
            (_seam select (_i - 1)) params ["_ax", "_ay"];
            (_seam select _i) params ["_bx", "_by"];
            private _len2 = ((_bx - _ax) ^ 2 + (_by - _ay) ^ 2) max 1e-6;
            private _u = 0 max (((_x0 - _ax) * (_bx - _ax) + (_y0 - _ay) * (_by - _ay)) / _len2) min 1;
            private _off = sqrt ((_x0 - _ax - _u * (_bx - _ax)) ^ 2 + (_y0 - _ay - _u * (_by - _ay)) ^ 2);
            if (_off < (_best select 0)) then {
                private _start = if (_i > 1) then {(_state get "lengths") select (_i - 2)} else {0};
                _best = [_off, (_start + _u * sqrt _len2) / (_state get "total")];
            };
        };
        _best params ["_off", "_along"];
        private _covered = _state get "covered";
        if (_off > (_state get "tolerance") || {_along < _covered - 0.03} || {_along > _covered + 0.06}) exitWith {};
        _state set ["onSeam", true];
        private _speed = if (_dt > 0) then {_distance / _dt} else {0};
        if (_speed < (_state get "slow")) then {
            _state set ["heat", (_state get "heat") + (_state get "heatRate") * _dt];
            if ((_state get "heat") >= 1) then {_state set ["status", "fail"]};
        } else {
            _state set ["heat", 0 max ((_state get "heat") - _dt)];
        };
        if (_along > _covered) then {
            if (_speed <= (_state get "fast")) then {_state set ["good", (_state get "good") + _along - _covered]};
            _state set ["covered", _along min 1];
        };
        if ((_state get "covered") >= 0.98) then {
            _state set ["status", "success"];
            _state set ["quality", 0.2 max (((_state get "good") / (_state get "covered")) min 1)];
        };
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["t", (_state get "t") + _value];
        // The plate cools while the torch is away.
        if !(_state get "onSeam") then {_state set ["heat", 0 max ((_state get "heat") - _value * 0.5)]};
        if ((_state get "t") >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
};
_state
