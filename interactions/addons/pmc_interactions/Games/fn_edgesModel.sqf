// [mode, state, value] -> state. Closing a cut or laceration with strips: a marker runs
// back and forth along the wound; a press while it is over a still open stretch closes
// that stretch, a press anywhere else is a miss. All stretches closed succeeds; one miss
// too many or the time limit fails. Quality drops by a fifth for every miss.
//   "init" value [stretches [[from, to], ...] along the wound 0-1, marker speed per s,
//                 time limit s, misses allowed]
//   "tick" value seconds;  "press" places a strip
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_stretches", "_speed", "_limit", "_allowed"];
        _state = createHashMapFromArray [["t", 0], ["pos", 0], ["dir", 1], ["stretches", _stretches], ["speed", _speed], ["limit", _limit],
            ["allowed", _allowed], ["closed", []], ["misses", 0], ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        _state set ["t", (_state get "t") + _value];
        private _pos = (_state get "pos") + (_state get "dir") * (_state get "speed") * _value;
        if (_pos > 1) then {_pos = 2 - _pos; _state set ["dir", -1]};
        if (_pos < 0) then {_pos = -_pos; _state set ["dir", 1]};
        _state set ["pos", _pos];
        if ((_state get "t") >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
    case "press": {
        if ((_state get "status") != "running") exitWith {};
        private _pos = _state get "pos";
        private _closed = _state get "closed";
        // The open stretch under the marker, if any.
        private _hit = -1;
        {
            if (!(_forEachIndex in _closed) && {_pos >= (_x select 0)} && {_pos <= (_x select 1)}) exitWith {_hit = _forEachIndex};
        } forEach (_state get "stretches");
        if (_hit < 0) exitWith {
            _state set ["misses", (_state get "misses") + 1];
            if ((_state get "misses") > (_state get "allowed")) then {_state set ["status", "fail"]};
        };
        _closed pushBack _hit;
        if (count _closed == count (_state get "stretches")) then {
            _state set ["status", "success"];
            _state set ["quality", 0.2 max (1 - 0.2 * (_state get "misses"))];
        };
    };
};
_state
