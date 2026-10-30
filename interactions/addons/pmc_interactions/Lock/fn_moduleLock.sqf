// Zeus module "Lock", placed on a box (any object with an inventory): opens the window to
// choose the lock, its difficulty and its key or code (PMCI_fnc_lockSetup).
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
    deleteVehicle _logic;
    if (isNull _target || {getNumber (configOf _target >> "maximumLoad") <= 0}) exitWith {["STR_PMCI_LOCK_ERR_OBJECT"] call PMCI_fnc_lockNotify};
    PMCI_lockSetup = createHashMapFromArray [["box", _target]];
    createDialog "PMCI_RscLockSetup";
};
