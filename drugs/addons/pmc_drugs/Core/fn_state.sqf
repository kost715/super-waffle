// [unit] -> the unit's drug state: a hashmap kept on the unit, on its own machine, never
// sent over the network or saved. A new body starts clean (nothing carries over a respawn);
// a Zeus re-assigns muscle damage with the module if the story needs it.
//   stimPool    equivalent seconds of Stim1f action left (0: not active); it drains by
//               wc per second, so a heavier load ends the dose sooner (PMCD_fnc_step)
//   stimDoses   Stim1f doses taken by this body (for the record and the debug panel)
//   stimDamage  muscle damage the current or last dose has added
//   overdoses   Stim1f doses taken during an active phase
//   debt        debt in mmol, one pool for all drugs, paid back from the AE2 reserve
//   debtStim, debtFen  debt run up by each source (record only)
params ["_unit"];
private _state = _unit getVariable "PMCD_state";
if (isNil "_state") then {
    _state = createHashMapFromArray [["stimPool", 0], ["stimDoses", 0], ["stimDamage", 0], ["overdoses", 0], ["debt", 0],
        ["debtStim", 0], ["debtFen", 0]];
    _unit setVariable ["PMCD_state", _state];
};
_state
