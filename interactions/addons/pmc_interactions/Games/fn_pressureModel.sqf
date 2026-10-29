// [mode, state, value] -> state. Direct pressure on a large wound (avulsion, crush):
// holding presses harder, letting go eases off, and every pulse beat knocks the pressure
// down. Time inside the zone fills the gauge; quality is the share of time inside it.
// The zone does not move: the challenge is the rhythm of the pulse. The time limit fails.
//   "init" value [zone low, zone high, hold time s, time limit s, pulse per min, pulse kick]
//   "tick" value seconds;  "press" / "release" hold
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_low", "_high", "_hold", "_limit", "_rate", "_kick"];
        _state = createHashMapFromArray [["t", 0], ["needle", 0.2], ["low", _low], ["high", _high], ["hold", _hold], ["limit", _limit],
            ["rate", _rate], ["kick", _kick], ["beat", 0], ["progress", 0], ["inside", 0], ["holding", false], ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        private _needle = (_state get "needle") + ([-0.3, 0.5] select (_state get "holding")) * _value;
        private _beat = (_state get "beat") + _value * (_state get "rate") / 60;
        if (_beat >= 1) then {
            _beat = _beat - 1;
            _needle = _needle - (_state get "kick");
        };
        _state set ["beat", _beat];
        _state set ["needle", 0 max (_needle min 1)];
        if ((_state get "needle") >= (_state get "low") && {(_state get "needle") <= (_state get "high")}) then {
            _state set ["progress", ((_state get "progress") + _value / (_state get "hold")) min 1];
            _state set ["inside", (_state get "inside") + _value];
        };
        _state set ["quality", ((_state get "inside") / _t) min 1];
        if ((_state get "progress") >= 1) exitWith {_state set ["status", "success"]};
        if (_t >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
    case "press": {_state set ["holding", true]};
    case "release": {_state set ["holding", false]};
};
_state
