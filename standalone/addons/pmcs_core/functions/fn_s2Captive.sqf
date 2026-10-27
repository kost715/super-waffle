// Runs on every machine: setCaptive needs the unit to be local.
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params [["_g", grpNull, [grpNull]], ["_on", false, [true]]];
{if (local _x && {!((captive _x) isEqualTo _on)}) then {_x setCaptive _on}} forEach units _g;
