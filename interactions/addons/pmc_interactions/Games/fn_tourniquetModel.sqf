// [mode, state, value] -> state. Tightening a tourniquet: holding raises the pressure;
// fixing it inside the band stops the bleeding. Past full pressure, or fixing outside
// the band, it slips back to zero; too many slips or the time limit fail.
//   "init" value [band low, band high, speed per s, time limit s, slips allowed]
//   "tick" value seconds;  "press" / "release" hold;  "fix"
params ["_mode", "_state", "_value"];
private _slip = {
    _state set ["p", 0];
    _state set ["slips", (_state get "slips") + 1];
    if ((_state get "slips") > (_state get "allowed")) then {_state set ["status", "fail"]};
};
switch (_mode) do {
    case "init": {
        _value params ["_low", "_high", "_speed", "_limit", "_allowed"];
        _state = createHashMapFromArray [["t", 0], ["p", 0], ["low", _low], ["high", _high], ["speed", _speed], ["limit", _limit],
            ["allowed", _allowed], ["slips", 0], ["holding", false], ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["t", (_state get "t") + _value];
        if (_state get "holding") then {
            _state set ["p", (_state get "p") + (_state get "speed") * _value];
            if ((_state get "p") > 1) then {call _slip};
        };
        if ((_state get "status") == "running" && {(_state get "t") >= (_state get "limit")}) then {_state set ["status", "fail"]};
    };
    case "press": {_state set ["holding", true]};
    case "release": {_state set ["holding", false]};
    case "fix": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["holding", false];
        private _p = _state get "p";
        if (_p >= (_state get "low") && {_p <= (_state get "high")}) then {
            _state set ["status", "success"];
            _state set ["quality", 1];
        } else {call _slip};
    };
};
_state
