// [mode, state, value] -> state. Opening a safe with a listening device: the dial (0-99)
// turns while the mouse is dragged sideways with the button held (right: the numbers go
// up). The combination's numbers are dialled turning up for the first, down for the
// second, and so on. While the dial turns the right way the device's needle shows how near
// it is to the number (full at the number, nothing `range` away); the press key sets the
// number. Set within the tolerance it counts, and the next number is dialled the other
// way; otherwise it is a mistake. One mistake too many or the time limit fail. Quality
// drops by 15% per mistake.
//   "init" value [numbers, tolerance, signal range, numbers per dragged px, time limit s,
//                 mistakes allowed]
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
        _value params ["_numbers", "_tolerance", "_range", "_gain", "_limit", "_allowed"];
        _state = createHashMapFromArray [["t", 0], ["numbers", _numbers], ["tolerance", _tolerance], ["range", _range], ["gain", _gain],
            ["limit", _limit], ["allowed", _allowed], ["dial", 0], ["dir", 0], ["next", 0], ["signal", 0], ["lastX", -1],
            ["mistakes", 0], ["status", "running"], ["quality", 0]];
    };
    case "mouse": {
        if ((_state get "status") != "running") exitWith {};
        _value params ["_x0", "", "", "_held"];
        if (_held && {(_state get "lastX") >= 0} && {_x0 != (_state get "lastX")}) then {
            private _step = (_x0 - (_state get "lastX")) * (_state get "gain");
            _state set ["dial", (((_state get "dial") + _step) % 100 + 100) % 100];
            _state set ["dir", [-1, 1] select (_step > 0)];
        };
        _state set ["lastX", [-1, _x0] select _held];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        private _want = [1, -1] select ((_state get "next") % 2);
        private _target = (_state get "numbers") select (_state get "next");
        private _signal = if ((_state get "dir") == _want) then {
            0 max (1 - ([_state get "dial", _target] call _apart) / (_state get "range"))
        } else {0};
        _state set ["signal", _signal];
        if (_t >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
    case "press": {
        if ((_state get "status") != "running") exitWith {};
        private _want = [1, -1] select ((_state get "next") % 2);
        private _target = (_state get "numbers") select (_state get "next");
        if ((_state get "dir") != _want || {([_state get "dial", _target] call _apart) > (_state get "tolerance")}) exitWith {
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
