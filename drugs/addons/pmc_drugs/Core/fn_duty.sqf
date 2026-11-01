// [effects] -> the duty factor of all active drugs together: the strongest decreasing
// factor times the strongest increasing one (1 where a group is empty). Registered with
// ACE Advanced Fatigue as one factor (PMCD_fnc_init).
params ["_effects"];
private _dec = 1;
private _inc = 1;
{
    _x params ["", "_kind", "_value"];
    if (_kind == "dec") then {_dec = _dec min _value};
    if (_kind == "inc") then {_inc = _inc max _value};
} forEach _effects;
_dec * _inc
