// [mode, state, value] -> state. Cleaning an abrasion, then covering it: scrubbing (mouse
// held and moving) over a dirt spot wears it away by the distance scrubbed. Once every
// spot is clean, holding covers the wound with a dressing. Quality falls as time passes
// beyond 40% of the limit; the time limit fails.
//   "init" value [spots [[x, y, radius], ...] in scene pixels, dirt per scrubbed pixel,
//                 time limit s, cover time s]
//   "tick" value seconds;  "scrub" value [x, y, distance] in scene pixels;
//   "press" / "release" hold (covering)
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_spots", "_rate", "_limit", "_cover"];
        _state = createHashMapFromArray [["t", 0], ["spots", _spots], ["dirt", _spots apply {1}], ["rate", _rate], ["limit", _limit],
            ["cover", _cover], ["phase", "clean"], ["covered", 0], ["holding", false], ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        _state set ["quality", 1 min (1 - 0.8 * (0 max (_t / (_state get "limit") - 0.4)))];
        if ((_state get "phase") == "cover" && {_state get "holding"}) then {
            _state set ["covered", ((_state get "covered") + _value / (_state get "cover")) min 1];
        };
        if ((_state get "covered") >= 1) exitWith {_state set ["status", "success"]};
        if (_t >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
    case "scrub": {
        if ((_state get "status") != "running" || {(_state get "phase") != "clean"}) exitWith {};
        _value params ["_x0", "_y0", "_distance"];
        private _dirt = _state get "dirt";
        {
            _x params ["_sx", "_sy", "_r"];
            if (((_x0 - _sx) ^ 2 + (_y0 - _sy) ^ 2) <= _r ^ 2) then {
                _dirt set [_forEachIndex, 0 max ((_dirt select _forEachIndex) - _distance * (_state get "rate"))];
            };
        } forEach (_state get "spots");
        if ((_dirt findIf {_x > 0.05}) < 0) then {
            _state set ["dirt", _dirt apply {0}];
            _state set ["phase", "cover"];
        };
    };
    case "press": {_state set ["holding", true]};
    case "release": {_state set ["holding", false]};
};
_state
