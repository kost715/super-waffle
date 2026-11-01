// [state, mission time] -> the drug effects active now: [[source, kind, value], ...].
//   kind "dec": a decreasing duty factor (value < 1) - its source runs up debt
//   kind "inc": an increasing duty factor (value > 1)
//   kind "meta": a metabolic effect (meldonium: value 0.77 on muscle damage)
// Stim1f for now; the other drugs of the spec add their entries here.
params ["_state", "_now"];
private _effects = [];
if ((_state get "stimPool") > 0) then {_effects pushBack ["stim", "dec", missionNamespace getVariable ["PMCD_stimDuty", 0.5]]};
_effects
