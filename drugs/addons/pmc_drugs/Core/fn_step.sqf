// [state, seconds, mission time, effects, AN reserve mmol, anWattsPerATP, payback floor]
// -> [muscle damage to add, new AN reserve]. Pure apart from the state it updates. One
// second (or so) of the drug state:
//  - Debt: only the active source - the strongest decreasing drug - runs it up, at
//      400 W x strongest increasing factor x (1 - its duty) / anWattsPerATP x 0.5 per s
//    (Stim1f at 0.5: 11.36 mmol/s at 8.8 W per mmol/s, 8 180 over 12 min).
//  - Muscle damage: an active Stim1f phase adds its dose's damage evenly over the phase,
//    x 0.77 while meldonium works.
//  - Payback: Stim1f debt first at 4.0 mmol/s, then Fentropil debt at 2.5 mmol/s, one at a
//    time, never while that source is active. It is taken from the AN reserve but never
//    below the floor (share of the 2 300 mmol full reserve); below it, it waits while ACE
//    refills the reserve.
params ["_state", "_dt", "_now", "_effects", "_anReserve", "_wattsPerATP", "_floor"];
private _maxInc = 1;
private _source = "";
private _sourceDuty = 1;
private _meldonium = false;
{
    _x params ["_name", "_kind", "_value"];
    if (_kind == "inc") then {_maxInc = _maxInc max _value};
    if (_kind == "dec" && {_value < _sourceDuty}) then {_source = _name; _sourceDuty = _value};
    if (_name == "meld") then {_meldonium = true};
} forEach _effects;
if (_source != "" && {_wattsPerATP > 0}) then {
    private _key = ["debtStim", "debtFen"] select (_source == "fen");
    _state set [_key, (_state get _key) + 400 * _maxInc * (1 - _sourceDuty) / _wattsPerATP * 0.5 * _dt];
};
private _active = _effects apply {_x select 0};
private _muscle = 0;
if ("stim" in _active) then {_muscle = (_state get "stimRate") * _dt * ([1, 0.77] select _meldonium)};
private _pay = switch (true) do {
    case ((_state get "debtStim") > 0): {[["debtStim", 4], []] select ("stim" in _active)};
    case ((_state get "debtFen") > 0): {[["debtFen", 2.5], []] select ("fen" in _active)};
    default {[]};
};
private _bottom = _floor * 2300;
if (_pay isNotEqualTo [] && {_anReserve > _bottom}) then {
    _pay params ["_key", "_rate"];
    private _paid = (_state get _key) min (_rate * _dt);
    _state set [_key, (_state get _key) - _paid];
    _anReserve = _bottom max (_anReserve - _paid);
};
[_muscle, _anReserve]
