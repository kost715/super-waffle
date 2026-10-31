// [mode, state, value] -> state. Hacking a code lock with a terminal device: the device
// dumps the lock's memory, rows of junk with candidate codes in it, and one of them is
// the code. A wrong code costs an attempt and tells how many of its digits stand in the
// right place (likeness). A row of junk is an input error and costs an attempt too, so
// rows cannot simply be clicked through. A bracket pair in the junk, tried once each,
// removes a dud code or restores the attempts. The right code succeeds; the last attempt used or the time
// limit fail. Quality is the share of attempts left.
//   "init" value [codes, answer index, rows, attempts, bracket effects, time limit s]
//       rows: one per memory row, ["code", code index] | ["bracket", bracket index] | ["junk", -1]
//       bracket effects: "dud" or "reset" per bracket
//   "tick" value seconds;  "pick" value row index
// The log keeps what the terminal answered: ["no", code, likeness], ["ok", code],
// ["dud", code], ["reset"], ["junk"].
params ["_mode", "_state", "_value"];
switch (_mode) do {
    case "init": {
        _value params ["_codes", "_answer", "_rows", "_attempts", "_effects", "_limit"];
        _state = createHashMapFromArray [["t", 0], ["codes", _codes], ["answer", _answer], ["rows", _rows], ["attempts", _attempts],
            ["left", _attempts], ["effects", _effects], ["limit", _limit], ["tried", []], ["removed", []], ["used", []], ["log", []],
            ["status", "running"], ["quality", 0]];
    };
    case "tick": {
        if ((_state get "status") != "running") exitWith {};
        private _t = (_state get "t") + _value;
        _state set ["t", _t];
        if (_t >= (_state get "limit")) then {_state set ["status", "fail"]};
    };
    case "pick": {
        if ((_state get "status") != "running") exitWith {};
        ((_state get "rows") param [_value, ["junk", -1]]) params ["_kind", "_index"];
        private _codes = _state get "codes";
        private _log = _state get "log";
        switch (_kind) do {
            case "code": {
                if (_index in (_state get "tried") || {_index in (_state get "removed")}) exitWith {};
                private _code = _codes select _index;
                if (_index == (_state get "answer")) exitWith {
                    _log pushBack ["ok", _code];
                    _state set ["status", "success"];
                    _state set ["quality", 0.2 max ((_state get "left") / (_state get "attempts"))];
                };
                private _answer = _codes select (_state get "answer");
                private _likeness = 0;
                for "_k" from 0 to count _code - 1 do {
                    if ((_code select [_k, 1]) == (_answer select [_k, 1])) then {_likeness = _likeness + 1};
                };
                (_state get "tried") pushBack _index;
                _log pushBack ["no", _code, _likeness];
                _state set ["left", (_state get "left") - 1];
                if ((_state get "left") <= 0) then {_state set ["status", "fail"]};
            };
            case "bracket": {
                if (_index in (_state get "used")) exitWith {};
                (_state get "used") pushBack _index;
                // A dud is the first code still in the dump that is not the answer; with
                // none left the bracket restores the attempts instead.
                private _dud = -1;
                if (((_state get "effects") param [_index, "dud"]) == "dud") then {
                    {
                        if (_dud < 0 && {_forEachIndex != (_state get "answer")} && {!(_forEachIndex in (_state get "tried"))}
                            && {!(_forEachIndex in (_state get "removed"))}) then {_dud = _forEachIndex};
                    } forEach _codes;
                };
                if (_dud >= 0) then {
                    (_state get "removed") pushBack _dud;
                    _log pushBack ["dud", _codes select _dud];
                } else {
                    _state set ["left", _state get "attempts"];
                    _log pushBack ["reset"];
                };
            };
            default {
                _log pushBack ["junk"];
                _state set ["left", (_state get "left") - 1];
                if ((_state get "left") <= 0) then {_state set ["status", "fail"]};
            };
        };
    };
};
_state
