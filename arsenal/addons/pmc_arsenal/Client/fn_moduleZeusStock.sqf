// Zeus module "Arsenal stock", placed on an arsenal object: opens the window to
// remove items from its storage or change their counts.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!local _logic || {!_activated}) exitWith {};
[_logic] spawn {
    params ["_logic"];
    private _target = objNull;
    private _until = diag_tickTime + 1;
    waitUntil {
        _target = _logic getVariable ["bis_fnc_curatorAttachObject_object", attachedTo _logic];
        !isNull _target || {diag_tickTime > _until}
    };
    [player, _target] remoteExecCall ["PMCA_fnc_zeusStock", 2];
    deleteVehicle _logic;
};
