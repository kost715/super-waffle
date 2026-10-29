// [mode, state, value] -> state. Repairing a component: first find the faulty part by
// testing parts (each test takes time; a good part tested is a mistake), then fix it by
// holding the working pressure in the zone until the gauge fills. Quality: how steadily
// the fix was held, minus 10% per mistake. The time limit fails.
//   "init" value [parts, faulty index, test time s, fix time s, time limit s, zone low, zone high]
//   "tick" value seconds;  "test" value part index;  "press" / "release" hold (fixing)
params ["_mode", "_state", "_value"];
private _busy = {(_state get "t") < (_state get "busyUntil")};
switch (_mode) do {
    case "init": {
        _value params ["_parts", "_faulty", "_testTime", "_fixTime", "_limit", "_low", "_high"];
        _state = createHashMapFromArray [["t", 0], ["parts", _parts], ["faulty", _faulty], ["testTime", _testTime], ["fixTime", _fixTime],
            ["limit", _limit], ["low", _low], ["high", _high], ["phase", "diagnose"], ["tested", []], ["mistakes", 0], ["busyUntil", 0],
            ["needle", 0], ["progress", 0], ["inside", 0], ["fixT", 0], ["holding", false], ["status", "running"], ["quality", 0]];
    };
    case "test": {
        if ((_state get "status") != "running" || {call _busy} || {(_state get "phase") != "diagnose"} || {_value in (_state get "tested")}) exitWith {};
        (_state get "tested") pushBack _value;
        _state set ["busyUntil", (_state get "t") + (_state get "testTime")];
        if (_value == (_state get "faulty")) then {_state set ["phase", "fix"]} else {_state set ["mistakes", (_state get "mistakes") + 1]};
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        if ((_state get "phase") == "fix" && {!(call _busy)}) then {
            _state set ["fixT", (_state get "fixT") + _value];
            _state set ["needle", 0 max (((_state get "needle") + ([-0.35, 0.45] select (_state get "holding")) * _value) min 1)];
            if ((_state get "needle") >= (_state get "low") && {(_state get "needle") <= (_state get "high")}) then {
                _state set ["progress", ((_state get "progress") + _value / (_state get "fixTime")) min 1];
                _state set ["inside", (_state get "inside") + _value];
            };
            if ((_state get "progress") >= 1) then {
                _state set ["status", "success"];
                _state set ["quality", 0.2 max ((0.4 + 0.6 * (_state get "inside") / (_state get "fixT") - 0.1 * (_state get "mistakes")) min 1)];
            };
        };
        if ((_state get "status") == "running" && {_t >= (_state get "limit")}) then {_state set ["status", "fail"]};
    };
    case "press": {_state set ["holding", true]};
    case "release": {_state set ["holding", false]};
};
_state
