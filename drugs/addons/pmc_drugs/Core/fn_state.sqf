// [unit] -> the unit's drug state: a hashmap kept on the unit, on its own machine, never
// sent over the network or saved. A new body starts clean (nothing carries over a respawn);
// a Zeus re-assigns muscle damage with the module if the story needs it.
//   stimUntil  mission time the active Stim1f phase ends (-1: none yet)
//   stimDoses  Stim1f doses taken by this body
//   stimRate   muscle damage per second of the active phase (PMCD_fnc_stimDose)
//   debtStim, debtFen  debt in mmol of AN reserve, paid back by PMCD_fnc_step
params ["_unit"];
private _state = _unit getVariable "PMCD_state";
if (isNil "_state") then {
    _state = createHashMapFromArray [["stimUntil", -1], ["stimDoses", 0], ["stimRate", 0], ["debtStim", 0], ["debtFen", 0]];
    _unit setVariable ["PMCD_state", _state];
};
_state
