// [unit] -> taken. Where the unit is local, after the injection bar: one meldonium is used.
// What is left of the metabolite now (PMCD_fnc_meldLevel) plus the new dose sets when the
// effect ends: half-life x log2(amount / 0.25).
params ["_unit"];
if !([_unit, "PMCD_Meldonium"] call PMCD_fnc_canTake) exitWith {false};
_unit removeItem "PMCD_Meldonium";
private _state = [_unit] call PMCD_fnc_state;
private _now = CBA_missionTime;
private _amount = (([_state, _now] call PMCD_fnc_meldLevel) select 1) + 1;
private _half = 30 * (missionNamespace getVariable ["PMCD_meldDuration", 90]);
_state set ["meld", [_amount, _now, _now + _half * (ln (_amount / 0.25) / ln 2)]];
_state set ["meldTaken", (_state getOrDefault ["meldTaken", 0]) + 1];
true
