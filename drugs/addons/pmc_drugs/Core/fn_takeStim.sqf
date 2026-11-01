// [unit] -> taken. Where the unit is local, after the injection bar: one Stim1f is used.
// With no Stim1f phase active a new phase starts (also while debt is being paid back:
// the new debt comes on top) with a full pool of action (CBA, 900 equivalent seconds;
// its length and damage follow the load as it goes, PMCD_fnc_step), and the AN reserve is
// filled. A dose during an active phase is an overdose (PMCD_fnc_overdose); the active
// phase goes on unchanged.
params ["_unit"];
if !([_unit] call PMCD_fnc_canTake) exitWith {false};
_unit removeItem "PMCD_Stim1f";
private _state = [_unit] call PMCD_fnc_state;
if ((_state get "stimPool") > 0) exitWith {
    _state set ["overdoses", (_state get "overdoses") + 1];
    [_unit] call PMCD_fnc_overdose;
    true
};
_state set ["stimDoses", (_state get "stimDoses") + 1];
_state set ["stimPool", missionNamespace getVariable ["PMCD_stimPool", 900]];
_state set ["stimDamage", 0];
// ACE Advanced Fatigue's full AN reserve (AN_MAXRESERVE), unless switched off in CBA.
if (_unit isEqualTo ACE_player && {missionNamespace getVariable ["PMCD_stimFillAN", true]}) then {ace_advanced_fatigue_anReserve = 2300};
true
