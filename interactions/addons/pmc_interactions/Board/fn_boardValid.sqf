// -> true while the board may go on: the player can still act and stays with the
// patient, vehicle or box, and the situation still calls for the action.
if (isNil "PMCI_board") exitWith {false};
private _args = PMCI_board get "args";
_args params ["_unit", "_target", "_part"];
if (!alive _unit || {_unit getVariable ["ACE_isUnconscious", false]} || {isNull _target}) exitWith {false};
if (_unit distance _target > ([5, 8] select ((PMCI_board get "kind") == "repair"))) exitWith {false};
// Locks: the box is still locked (another player may have opened it meanwhile).
if ((PMCI_board get "kind") == "lock") exitWith {(_target getVariable ["PMCI_lock", []]) isNotEqualTo []};
// Repairs: the vehicle stands still and the spare wheel or track is still there.
if ((PMCI_board get "kind") == "repair") exitWith {
    alive _target && {(abs speed _target) < 1} && {((_args param [6, []]) findIf {!alive _x}) < 0}
};
switch (PMCI_board get "game") do {
    // ACE's own CPR condition: the patient is out and this medic is the one doing CPR.
    case "cpr": {alive _target && {_target getVariable ["ACE_isUnconscious", false]} && {(_target getVariable ["ace_medical_CPR_provider", objNull]) isEqualTo _unit}};
    default {alive _target};
}
