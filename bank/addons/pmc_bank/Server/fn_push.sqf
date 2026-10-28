// [owner, unit] -> nothing. Server. Sends a player the current ATM state.
params ["_owner", "_unit"];
if (isNull _unit) exitWith {};
[[_unit] call PMCB_fnc_state] remoteExecCall ["PMCB_fnc_receive", _owner];
