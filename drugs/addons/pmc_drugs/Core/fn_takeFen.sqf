// [unit] -> taken. Where the unit is local, after the injection bar: one Fentropil is used
// and a dose starts at this moment. Its concentration builds up, stays and wears off on its
// own (PMCD_fnc_fenLevel); doses add up with diminishing effect, f(C) = 1 - 0.5^C. No
// overdose: a second dose only takes the effect from 0.5 to 0.75.
params ["_unit"];
if !([_unit, "PMCD_Fentropil"] call PMCD_fnc_canTake) exitWith {false};
_unit removeItem "PMCD_Fentropil";
private _state = [_unit] call PMCD_fnc_state;
_state set ["fenTaken", (_state get "fenTaken") + 1];
(_state get "fenDoses") pushBack CBA_missionTime;
true
