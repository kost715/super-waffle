params [["_unit", objNull, [objNull]], ["_mutating", false, [true]], ["_computer", objNull, [objNull]]];
if (!isServer || {!(missionNamespace getVariable ["PMCS_ready", false])} || {isNull _unit} || {
    !isPlayer _unit || {!alive _unit}
}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != owner _unit}) exitWith {false};
if (!_mutating) exitWith {true};
[_unit] call PMCS_fnc_isAdmin && {!isNull _computer} && {_computer in PMCS_terminals} && {
    _unit distance _computer <= 4.5
}
