// [mode, state, value] -> state. Opening a safe with a listening device: the dial (0-99)
// turns while the mouse is dragged sideways with the button held (right: the numbers go
// up). The combination's numbers are dialled turning up for the first, down for the
// second, and so on; the dial is blocked the other way, so a number passed by can only be
// reached by going round again. The device's needle shows how near the dial is to the
// number (full at the number, nothing `range` away) and trembles by up to `noise`; the
// press key sets the number. Set within the tolerance it counts; otherwise it is a
// mistake. One mistake too many or the time limit fail. Quality drops by 15% per mistake.
//   "init" value [numbers, tolerance, signal range, numbers per dragged px, time limit s,
//                 mistakes allowed, needle noise 0-1]
//   "tick" value seconds;  "press" sets the number;
//   "mouse" value [x, y, distance, held, seconds]
params ["_mode", "_state", "_value"];
// Distance between two dial positions, around the dial.
private _apart = {
    params ["_a", "_b"];
    private _d = abs (_a - _b) % 100;
    _d min (100 - _d)
};
switch (_mode) do {
    case "init": {
        _value params ["_numbers", "_tolerance", "_range", "_gain", "_limit", "_allowed", ["_noise", 0]];
        _state = createHashMapFromArray [["t", 0], ["numbers", _numbers], ["tolerance", _tolerance], ["range", _range], ["gain", _gain],
            ["limit", _limit], ["allowed", _allowed], ["noise", _noise], ["dial", 0], ["next", 0], ["signal", 0], ["lastX", -1],
            ["blockedAt", -10], ["mistakes", 0], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {
        if ((_state get "status") != "running") exitWith {};
        _value params ["_x0", "", "", "_held"];
        if (_held && {(_state get "lastX") >= 0} && {_x0 != (_state get "lastX")}) then {
            private _step = (_x0 - (_state get "lastX")) * (_state get "gain");
            if (_step * ([1, -1] select ((_state get "next") % 2)) > 0) then {
                _state set ["dial", (((_state get "dial") + _step) % 100 + 100) % 100];
            } else {
                _state set ["blockedAt", _state get "t"];
            };
        };
        _state set ["lastX", [-1, _x0] select _held];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        private _target = (_state get "numbers") select (_state get "next");
        private _signal = 0 max (1 - ([_state get "dial", _target] call _apart) / (_state get "range"));
        _signal = _signal + (_state get "noise") * sin (_t * 2900) * cos (_t * 1700);
        _state set ["signal", 0 max (_signal min 1)];
        if (_t >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
    case "press": {
        if ((_state get "status") != "running") exitWith {};
        private _target = (_state get "numbers") select (_state get "next");
        if (([_state get "dial", _target] call _apart) > (_state get "tolerance")) exitWith {
            _state set ["mistakes", (_state get "mistakes") + 1];
            if ((_state get "mistakes") > (_state get "allowed")) then {_state set ["status", "fail"]};
        };
        _state set ["next", (_state get "next") + 1];
        _state set ["signal", 0];
        if ((_state get "next") >= count (_state get "numbers")) then {
            _state set ["status", "success"];
            _state set ["quality", 0.2 max (1 - 0.15 * (_state get "mistakes"))];
        };
    };
};
_state
