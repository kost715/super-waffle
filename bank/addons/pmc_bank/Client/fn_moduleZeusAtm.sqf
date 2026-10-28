// Zeus module "ATM", placed on an object: makes it an ATM, or an ordinary object again.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!local _logic || {!_activated}) exitWith {};
[_logic] spawn {
    params ["_logic"];
    private _target = [_logic] call PMCB_fnc_zeusTarget;
    [player, _target] remoteExecCall ["PMCB_fnc_zeusAtm", 2];
    deleteVehicle _logic;
};
