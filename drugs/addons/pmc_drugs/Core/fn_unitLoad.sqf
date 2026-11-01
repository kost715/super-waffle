// [unit] -> the unit's gear load in kg, as ACE Advanced Fatigue counts it (ACE's total
// load when ACE Movement has it, the engine's otherwise, less 3.5 kg of underwear).
params ["_unit"];
private _load = _unit getVariable "ace_movement_totalLoad";
if (isNil "_load") then {_load = loadAbs _unit};
0 max (_load / 22.046 - 3.5)
