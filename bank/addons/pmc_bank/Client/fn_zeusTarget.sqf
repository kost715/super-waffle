// [logic] -> object the Zeus module was placed on, objNull if none. Waits up to 1 s
// for the attachment; call from scheduled code.
params [["_logic", objNull, [objNull]]];
private _target = objNull;
private _until = diag_tickTime + 1;
waitUntil {
    _target = _logic getVariable ["bis_fnc_curatorAttachObject_object", attachedTo _logic];
    !isNull _target || {diag_tickTime > _until}
};
_target
