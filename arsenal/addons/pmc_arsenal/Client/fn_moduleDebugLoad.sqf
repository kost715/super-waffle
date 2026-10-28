// Zeus module "Load box into arsenal", placed on a box: runs on the Zeus who placed
// it and asks the server to make the box's contents unlimited in the arsenal nearby.
params [["_logic", objNull, [objNull]], "", ["_activated", true]];
if (!local _logic || {!_activated}) exitWith {};
[_logic] spawn {
    params ["_logic"];
    private _box = objNull;
    private _until = diag_tickTime + 1;
    waitUntil {
        _box = _logic getVariable ["bis_fnc_curatorAttachObject_object", attachedTo _logic];
        !isNull _box || {diag_tickTime > _until}
    };
    [player, _box] remoteExecCall ["PMCA_fnc_debugLoad", 2];
    deleteVehicle _logic;
};
