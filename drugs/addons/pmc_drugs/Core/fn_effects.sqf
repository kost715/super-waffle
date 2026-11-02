// [state, mission time] -> the drug effects active now: [[source, kind, value], ...].
//   kind "dec": a decreasing duty factor (value < 1) - its source runs up debt
//   kind "inc": an increasing duty factor (value > 1)
//   kind "meta": a metabolic effect (meldonium: value 0.77 on muscle damage)
// Stim1f: one entry however many doses act (duty takes the strongest). Fentropil: duty
// 1 - (1 - 0.9) x g(C) while any of it is in the body (PMCD_fnc_fenLevel). Meldonium: on or
// off (PMCD_fnc_meldLevel). The other drugs of the spec add their entries here.
params ["_state", "_now"];
private _effects = [];
if ((_state get "doses") isNotEqualTo []) then {_effects pushBack ["stim", "dec", missionNamespace getVariable ["PMCD_stimDuty", 0.5]]};
private _g = ([_state, _now] call PMCD_fnc_fenLevel) select 1;
if (_g > 0) then {_effects pushBack ["fen", "dec", 0.01 max (1 - (1 - (missionNamespace getVariable ["PMCD_fenDuty", 0.9])) * _g)]};
if (([_state, _now] call PMCD_fnc_meldLevel) select 0) then {_effects pushBack ["meld", "meta", missionNamespace getVariable ["PMCD_meldMuscle", 0.77]]};
_effects
