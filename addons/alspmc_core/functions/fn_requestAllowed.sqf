params [["_unit", objNull, [objNull]]];
if (!isServer || {isNull _unit} || {!isPlayer _unit} || {!alive _unit}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != owner _unit}) exitWith {false};
missionNamespace getVariable ["ALSPMC_ready", false]
