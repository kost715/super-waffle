// [mode, state, value] -> state. Stitching, led like a weld seam: with the mouse button
// held, the needle is led along the zigzag through the stitch points (in above the wound,
// out below it, on to the next stitch); the thread follows where the needle is on the
// line and at the end of the thread laid so far. Too fast pulls the stitches loose and
// lowers the quality; the thread does not overheat, so slow is fine. "next" counts the
// points passed, a stitch per pair. Uses the weld model without heating.
//   "init" value [points [[x, y], ...] in scene pixels, tolerance px, speed min px/s,
//                 speed max px/s, time limit s]
//   "tick" value seconds;  "mouse" value [x, y, distance, held, seconds]
params ["_mode", "_state", "_value"];
if (_mode == "init") exitWith {
    _value params ["_points", "_tolerance", "_slow", "_fast", "_limit"];
    _state = ["init", nil, [_points, _tolerance, _slow, _fast, _limit, 0]] call PMCI_fnc_weldModel;
    _state set ["points", _points];
    _state set ["next", 0];
    _state
};
[_mode, _state, _value] call PMCI_fnc_weldModel;
// Points passed: every point whose place along the zigzag the thread has reached.
private _covered = _state get "covered";
private _total = _state get "total";
private _next = if (_covered > 0) then {1 + ({_x / _total <= _covered + 1e-6} count (_state get "lengths"))} else {0};
if ((_state get "status") == "success") then {_next = count (_state get "points")};
_state set ["next", _next];
_state
