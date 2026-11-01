// [state, seconds, effects, load kg, work now W, AE2 reserve mmol, anWattsPerATP,
//  recoveryFactor] -> [muscle damage to add, new AE2 reserve, names of the pulse effects
// of doses that ended]. Pure apart from the state it updates. One second (or so) of the
// drug state (CBA settings, defaults of the spec):
//  - Stim1f doses: each acting dose drains its own pool (900 equivalent seconds) by the
//    weight coefficient wc of the load now (PMCD_fnc_weightCoef) per second and adds muscle
//    damage at base (0.16) x wc^2 / pool per second, times meldonium's factor (0.77) while
//    it works. At a steady load a dose lasts pool / wc and does base x wc in all. Doses
//    taken together act side by side, each to its own end.
//  - Debt: the work saved this second by the active source (the strongest decreasing drug,
//    duty d): work now x (1 - d) / d, the work now coming from ACE with every duty factor
//    in it (PMCD_fnc_currentWork), then / anWattsPerATP x factor (1.0) mmol per second.
//    Standing still costs ACE its resting work, so a stimulated soldier at rest runs up
//    little; one sprinting under a heavy load runs up a lot. One pool.
//  - Payback: while no decreasing drug is active, the debt is taken from the AE2 reserve
//    at 15 x recoveryFactor mmol/s, never below the floor (25% of 84 000 mmol): at the
//    floor it only takes what ACE regenerated. The AN reserve is not touched.
params ["_state", "_dt", "_effects", "_kg", "_work", "_ae2", "_wattsPerATP", "_recovery"];
private _source = "";
private _sourceDuty = 1;
private _duty = 1;
private _inc = 1;
private _meldonium = 1;
{
    _x params ["_name", "_kind", "_value"];
    if (_kind == "inc") then {_inc = _inc max _value};
    if (_kind == "dec" && {_value < _sourceDuty}) then {_source = _name; _sourceDuty = _value};
    if (_name == "meld") then {_meldonium = _value};
} forEach _effects;
_duty = _sourceDuty * _inc;
private _savings = 0;
private _rate = 0;
if (_source != "" && {_wattsPerATP > 0} && {_sourceDuty > 0}) then {
    _savings = _work * (1 - _sourceDuty) / _sourceDuty;
    _rate = _savings / _wattsPerATP * (missionNamespace getVariable ["PMCD_debtFactor", 1]);
    _state set ["debt", (_state get "debt") + _rate * _dt];
    private _key = ["debtStim", "debtFen"] select (_source == "fen");
    _state set [_key, (_state get _key) + _rate * _dt];
};
_state set ["lastWork", [_work, _work / (_duty max 0.01), _savings, _rate]];
private _muscle = 0;
private _ended = [];
private _doses = _state get "doses";
if (_doses isNotEqualTo []) then {
    private _wc = [_kg] call PMCD_fnc_weightCoef;
    private _perSecond = (missionNamespace getVariable ["PMCD_stimBaseDamage", 0.16]) * _wc ^ 2 / (missionNamespace getVariable ["PMCD_stimPool", 900]);
    {
        _x params ["_pool", "_name", "_done"];
        // The last second of a dose counts only the part of it the pool still had.
        private _used = _dt min (_pool / _wc);
        private _add = _perSecond * _used * _meldonium;
        _muscle = _muscle + _add;
        _x set [0, 0 max (_pool - _wc * _used)];
        _x set [2, _done + _add];
        if ((_x select 0) <= 0) then {_ended pushBack _name};
    } forEach _doses;
    _state set ["doses", _doses select {(_x select 0) > 0}];
};
if (_source == "" && {(_state get "debt") > 0}) then {
    private _floor = (missionNamespace getVariable ["PMCD_ae2Floor", 0.25]) * 84000;
    private _paid = ((_state get "debt") min ((missionNamespace getVariable ["PMCD_paybackMultiplier", 15]) * _recovery * _dt)) min (0 max (_ae2 - _floor));
    _state set ["debt", (_state get "debt") - _paid];
    _ae2 = _ae2 - _paid;
};
[_muscle, _ae2, _ended]
