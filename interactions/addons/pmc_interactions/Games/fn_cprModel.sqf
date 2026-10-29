// [mode, state, value] -> state. CPR as a rhythm: one press per compression; an interval
// within 100-120 per minute (plus the tolerance) is a good compression. At the end the
// quality is good compressions / expected ones; success needs the minimum quality.
// A compression faster than the accepted interval is counted as too fast ("lastFast" says
// whether the latest one was; PMCI_fnc_cprRibs may break a rib for it).
//   "init"  value [duration s, tolerance s, minimum quality] -> new state
//   "tick"  value seconds elapsed;  "press" value ignored
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_duration", "_tolerance", "_minimum"];
        _state = createHashMapFromArray [["t", 0], ["duration", _duration], ["tolerance", _tolerance], ["minimum", _minimum],
            ["last", -1], ["good", 0], ["presses", 0], ["fast", 0], ["lastFast", false], ["expected", 1 max (_duration * 110 / 60 - 1)],
            ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["t", (_state get "t") + _value];
        _state set ["quality", ((_state get "good") / (_state get "expected")) min 1];
        if ((_state get "t") >= (_state get "duration")) then {
            _state set ["status", ["fail", "success"] select ((_state get "quality") >= (_state get "minimum"))];
        };
    };
    case "press": {
        if ((_state get "status") != "running") exitWith {};
        private _t = _state get "t";
        private _last = _state get "last";
        private _tolerance = _state get "tolerance";
        if (_last >= 0 && {(_t - _last) >= 0.5 - _tolerance} && {(_t - _last) <= 0.6 + _tolerance}) then {_state set ["good", (_state get "good") + 1]};
        private _fast = _last >= 0 && {(_t - _last) < 0.5 - _tolerance};
        _state set ["lastFast", _fast];
        if (_fast) then {_state set ["fast", (_state get "fast") + 1]};
        _state set ["last", _t];
        _state set ["presses", (_state get "presses") + 1];
    };
};
_state
