// [mode, state, value] -> state. Changing a wheel: loosen the five nuts in a star (every
// second nut, starting anywhere), swap the wheel, tighten them in a star again. Removing
// a wheel ends once the nuts are loose. Each nut takes the nut time; a wrong nut costs
// the same time and counts as a mistake.
//   "init" value [nut time s, swap time s, remove only]
//   "tick" value seconds;  "nut" value index 0-4 around the hub;  "swap"
params ["_mode", "_state", "_value"];
private _busy = {(_state get "t") < (_state get "busyUntil")};
switch (_mode) do {
    case "init": {
        _value params ["_nutTime", "_swapTime", ["_remove", false]];
        _state = createHashMapFromArray [["t", 0], ["nutTime", _nutTime], ["swapTime", _swapTime], ["remove", _remove], ["phase", "loosen"], ["start", -1],
            ["step", 0], ["mistakes", 0], ["busyUntil", 0], ["done", []], ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["t", (_state get "t") + _value];
        if ((_state get "phase") == "done" && {!(call _busy)}) then {
            _state set ["status", "success"];
            _state set ["quality", 1];
        };
    };
    case "nut": {
        if ((_state get "status") != "running" || {call _busy} || {!((_state get "phase") in ["loosen", "tighten"])}) exitWith {};
        if ((_state get "step") == 0) then {_state set ["start", _value]};
        _state set ["busyUntil", (_state get "t") + (_state get "nutTime")];
        if (_value != ((_state get "start") + 2 * (_state get "step")) % 5) exitWith {_state set ["mistakes", (_state get "mistakes") + 1]};
        (_state get "done") pushBack _value;
        _state set ["step", (_state get "step") + 1];
        if ((_state get "step") == 5) then {
            _state set ["phase", ["done", "swap"] select ((_state get "phase") == "loosen" && {!(_state get "remove")})];
            _state set ["step", 0];
            _state set ["done", []];
        };
    };
    case "swap": {
        if ((_state get "status") != "running" || {call _busy} || {(_state get "phase") != "swap"}) exitWith {};
        _state set ["busyUntil", (_state get "t") + (_state get "swapTime")];
        _state set ["phase", "tighten"];
    };
};
_state
