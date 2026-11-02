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
//    little; one sprinting under a heavy load runs up a lot. Pools: each Stim1f dose its
//    own (stimDebts), Fentropil one (debtFen); under Stim1f only Stim1f runs up debt.
//    While Stim1f doses overlap, the saving is the oldest acting dose's: it is the one
//    giving the duty, a newer dose only takes over when it ends. debtStim is the Stim1f
//    pools together, "debt" all of them.
//  - Payback from the AE2 reserve, never below the floor (25% of 84 000 mmol: at the floor
//    it only takes what ACE regenerated); the AN reserve is not touched. One pool at a time,
//    in order: the Stim1f doses by number, each from the moment its own dose ends (a newer
//    dose acting does not hold it back), at 15 x recoveryFactor mmol/s; then Fentropil, 3
//    times slower (CBA), once every Stim1f pool is paid, no Stim1f acts and no Fentropil is
//    in the body.
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
    if (_source == "fen") then {
        _state set ["debtFen", (_state get "debtFen") + _rate * _dt];
    } else {
        // The oldest acting Stim1f dose (its own pool, made when it was taken).
        private _owner = ((_state get "doses") param [0, [0, ""]]) select 1;
        private _debts = _state getOrDefault ["stimDebts", []];
        private _at = _debts findIf {(_x select 0) == _owner};
        if (_at < 0) then {_at = _debts pushBack [_owner, 0, false]};
        (_debts select _at) set [1, ((_debts select _at) select 1) + _rate * _dt];
        _state set ["stimDebts", _debts];
    };
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
private _stimActs = _effects findIf {(_x select 0) == "stim"} >= 0;
private _fenActs = _effects findIf {(_x select 0) == "fen"} >= 0;
private _debts = _state getOrDefault ["stimDebts", []];
// A Stim1f pool is due once its dose has ended (ended this second included).
{
    if ((_x select 0) in _ended) then {_x set [2, true]};
} forEach _debts;
private _floor = (missionNamespace getVariable ["PMCD_ae2Floor", 0.25]) * 84000;
private _full = (missionNamespace getVariable ["PMCD_paybackMultiplier", 15]) * _recovery * _dt;
private _room = 0 max (_ae2 - _floor);
private _paidFrom = "";
private _paid = 0;
private _due = _debts findIf {(_x select 2) && {(_x select 1) > 0}};
if (_due >= 0) then {
    private _pool = _debts select _due;
    _paid = ((_pool select 1) min _full) min _room;
    _pool set [1, (_pool select 1) - _paid];
    _paidFrom = _pool select 0;
} else {
    // No pool is due: the Stim1f pools left belong to acting doses, so with no Stim1f acting
    // every one of them is paid.
    if (!_stimActs && {!_fenActs} && {(_state get "debtFen") > 0}) then {
        _paid = ((_state get "debtFen") min (_full / ((missionNamespace getVariable ["PMCD_fenPaybackDivider", 3]) max 1))) min _room;
        _state set ["debtFen", (_state get "debtFen") - _paid];
        _paidFrom = "debtFen";
    };
};
_ae2 = _ae2 - _paid;
// Paid pools of ended doses are done with.
_debts = _debts select {!(_x select 2) || {(_x select 1) > 0}};
_state set ["stimDebts", _debts];
private _stimTotal = 0;
{_stimTotal = _stimTotal + (_x select 1)} forEach _debts;
_state set ["debtStim", _stimTotal];
_state set ["lastPay", [_paidFrom, _paid / (_dt max 0.001)]];
_state set ["debt", _stimTotal + (_state get "debtFen")];
[_muscle, _ae2, _ended]
