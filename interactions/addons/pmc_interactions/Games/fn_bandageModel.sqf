// [mode, state, value] -> state. Packing a wound: holding pushes the pressure needle up,
// letting go lets it fall; the target zone drifts. Time inside the zone fills the
// bandage; quality is the share of time spent inside it. The time limit fails.
//   "init" value [zone width, time limit s, fill time s, drift noise]
//   "tick" value seconds;  "press" / "release" hold
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_width", "_limit", "_fill", ["_noise", 0.25]];
        _state = createHashMapFromArray [["t", 0], ["needle", 0.3], ["center", 0.5], ["width", _width], ["limit", _limit], ["fill", _fill],
            ["noise", _noise], ["progress", 0], ["inside", 0], ["holding", false], ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        // The zone sways between 0.3 and 0.7 (sin takes degrees: one sway per 9 s).
        _state set ["center", 0.5 + 0.2 * sin (_t * 40)];
        private _push = [-0.35, 0.45] select (_state get "holding");
        private _needle = (_state get "needle") + (_push + (_state get "noise") * (random 2 - 1)) * _value;
        _state set ["needle", 0 max (_needle min 1)];
        if (abs ((_state get "needle") - (_state get "center")) <= (_state get "width") / 2) then {
            _state set ["progress", ((_state get "progress") + _value / (_state get "fill")) min 1];
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
