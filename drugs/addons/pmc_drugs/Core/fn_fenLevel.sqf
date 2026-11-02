// [state, mission time] -> [C, g]: the Fentropil concentration now and its effect strength.
// Each dose (its injection time in the state's fenDoses) goes linearly 0 -> 1 over the
// build-up (CBA, 20 min), stays 1 over the plateau (50 min) and falls linearly 1 -> 0 over
// the wear-off (60 min). C is the sum of the doses. The strength is one continuous curve:
// g(C) = (1 - r^C) / (1 - r), r = 1 / divider (CBA, 1.5): g(1) = 1 gives the CBA values,
// each further unit of C adds divider times less than the one before (g(2) = 1.67,
// g(3) = 2.11), capped at 2.1 (CBA). More Fentropil past the cap only lasts longer.
// Every Fentropil effect is 1 + (its CBA value - 1) x g.
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
private _r = 1 / ((missionNamespace getVariable ["PMCD_fenDivider", 1.5]) max 1.01);
[_c, 0 max ((1 - _r ^ _c) / (1 - _r)) min (missionNamespace getVariable ["PMCD_fenCap", 2.1])]
