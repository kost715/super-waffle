// [state, seconds, effects, load kg, AE2 reserve mmol, anWattsPerATP, recoveryFactor]
// -> [muscle damage to add, new AE2 reserve]. Pure apart from the state it updates. One
// second (or so) of the drug state (CBA settings, defaults of the spec):
//  - Stim1f: the weight coefficient wc of the load now (PMCD_fnc_weightCoef) drains the
//    dose's pool (900 equivalent seconds) by wc per second and adds muscle damage at
//    base (0.16) x wc^2 / pool per second, times meldonium's factor (0.77) while it works.
//    A dose at a steady load lasts pool / wc and does base x wc in all (40 kg: 12.1 min,
//    0.199); a load changed meanwhile changes both from then on.
//  - Debt: only the active source - the strongest decreasing drug - runs it up, at
//      base work (400 W) x strongest increasing factor x (1 - its duty) / anWattsPerATP
//    x factor (1.0) per second: 16 420 mmol for 12 min of Stim1f at 8.77. One pool.
//  - Payback: while no decreasing drug is active, the debt is taken from the AE2 reserve
//    at 15 x recoveryFactor mmol/s, but never below the floor (25% of the 84 000 mmol
//    AE2 maximum): at the floor it only takes what ACE regenerated, so it neither stops
//    and starts every second nor digs under it. The AN reserve is not touched.
params ["_state", "_dt", "_effects", "_kg", "_ae2", "_wattsPerATP", "_recovery"];
private _maxInc = 1;
private _source = "";
private _sourceDuty = 1;
private _meldonium = 1;
{
    _x params ["_name", "_kind", "_value"];
    if (_kind == "inc") then {_maxInc = _maxInc max _value};
    if (_kind == "dec" && {_value < _sourceDuty}) then {_source = _name; _sourceDuty = _value};
    if (_name == "meld") then {_meldonium = _value};
} forEach _effects;
if (_source != "" && {_wattsPerATP > 0}) then {
    private _debt = (missionNamespace getVariable ["PMCD_debtBaseWork", 400]) * _maxInc * (1 - _sourceDuty) / _wattsPerATP
        * (missionNamespace getVariable ["PMCD_debtFactor", 1]) * _dt;
    _state set ["debt", (_state get "debt") + _debt];
    private _key = ["debtStim", "debtFen"] select (_source == "fen");
    _state set [_key, (_state get _key) + _debt];
};
private _muscle = 0;
if ((_state get "stimPool") > 0) then {
    private _wc = [_kg] call PMCD_fnc_weightCoef;
    // The last second of a dose counts only the part of it the pool still had.
    private _used = _dt min ((_state get "stimPool") / _wc);
    _muscle = (missionNamespace getVariable ["PMCD_stimBaseDamage", 0.16]) * _wc ^ 2 / (missionNamespace getVariable ["PMCD_stimPool", 900])
        * _used * _meldonium;
    _state set ["stimPool", 0 max ((_state get "stimPool") - _wc * _used)];
    _state set ["stimDamage", (_state get "stimDamage") + _muscle];
};
if (_source == "" && {(_state get "debt") > 0}) then {
    private _floor = (missionNamespace getVariable ["PMCD_ae2Floor", 0.25]) * 84000;
    private _paid = ((_state get "debt") min ((missionNamespace getVariable ["PMCD_paybackMultiplier", 15]) * _recovery * _dt)) min (0 max (_ae2 - _floor));
    _state set ["debt", (_state get "debt") - _paid];
    _ae2 = _ae2 - _paid;
};
[_muscle, _ae2]
