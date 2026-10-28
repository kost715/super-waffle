// Zeus module "Treasurer", placed on a player: allows or forbids them to withdraw
// from the group's account.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!local _logic || {!_activated}) exitWith {};
[_logic] spawn {
    params ["_logic"];
    private _target = [_logic] call PMCB_fnc_zeusTarget;
    [player, _target] remoteExecCall ["PMCB_fnc_zeusTreasurer", 2];
    deleteVehicle _logic;
};
