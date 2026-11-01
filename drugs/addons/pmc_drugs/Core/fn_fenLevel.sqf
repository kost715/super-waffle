// [state, mission time] -> [C, f]: the Fentropil concentration now and its effect level.
// Each dose (its injection time in the state's fenDoses) goes linearly 0 -> 1 over the
// build-up (CBA, 20 min), stays 1 over the plateau (50 min) and falls linearly 1 -> 0 over
// the wear-off (60 min). C is the sum of the doses, f(C) = 1 - 0.5^C: one dose's plateau
// 0.5, two doses 0.75, three 0.875. Every Fentropil effect scales with f.
params ["_state", "_now"];
private _rise = 60 * (missionNamespace getVariable ["PMCD_fenRise", 20]);
private _plateau = 60 * (missionNamespace getVariable ["PMCD_fenPlateau", 50]);
private _fall = 60 * (missionNamespace getVariable ["PMCD_fenFall", 60]);
private _c = 0;
{
    private _t = _now - _x;
    _c = _c + (switch (true) do {
        case (_t <= 0): {0};
        case (_t < _rise): {_t / _rise};
        case (_t <= _rise + _plateau): {1};
        case (_t < _rise + _plateau + _fall): {1 - (_t - _rise - _plateau) / _fall};
        default {0};
    });
} forEach (_state getOrDefault ["fenDoses", []]);
[_c, 1 - 0.5 ^ _c]
