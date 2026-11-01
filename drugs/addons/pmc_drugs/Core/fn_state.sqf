// [unit] -> the unit's drug state: a hashmap kept on the unit, on its own machine, never
// sent over the network or saved. A new body starts clean (nothing carries over a respawn);
// a Zeus re-assigns muscle damage with the module if the story needs it.
//   stimDoses   Stim1f doses taken by this body (each is numbered: PMCD_Stim1f_<n>)
//   doses       the Stim1f doses still acting: [[action pool left (equivalent seconds),
//               name of its pulse effect in ACE Medical, muscle damage it has added], ...];
//               each drains by wc per second (PMCD_fnc_step) and ends on its own
//   debt        debt in mmol, one pool for all drugs, paid back from the AE2 reserve
//   debtStim, debtFen  debt run up by each source (record only)
//   lastWork    [work now, nominal, savings, debt rate] of the last second (debug panel)
params ["_unit"];
private _state = _unit getVariable "PMCD_state";
if (isNil "_state") then {
    _state = createHashMapFromArray [["stimDoses", 0], ["doses", []], ["debt", 0], ["debtStim", 0], ["debtFen", 0], ["lastWork", [0, 0, 0, 0]]];
    _unit setVariable ["PMCD_state", _state];
};
_state
