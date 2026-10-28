// Zeus module "Bank journal": opens every account's operations, with export.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!local _logic || {!_activated}) exitWith {};
deleteVehicle _logic;
[player] remoteExecCall ["PMCB_fnc_zeusLog", 2];
