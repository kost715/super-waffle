params ["_key"];
// Reuse native camera setup and teardown. Its default orbit watches the phone
// display, so only that orbit handler is replaced while a desktop is open.
[_key] call ALS_fnc_propView;
if (isNil "ALS_propCam") exitWith {ALSPMC_desktopCamera = false};
ALS_propCam params ["_cam", "_nativeHandler"];
[_nativeHandler] call CBA_fnc_removePerFrameHandler;
private _house = [_key] call ALS_fnc_houseObj;
if (isNull _house) exitWith {[""] call ALS_fnc_propView};
private _center = getPosATL _house;
(boundingBoxReal _house) params ["_lo", "_hi"];
private _radius = (((_hi vectorDiff _lo) select 0) max ((_hi vectorDiff _lo) select 1) max 8) * 1.6;
private _handler = [{
    params ["_args"];
    _args params ["_camera", "_center", "_radius"];
    if (isNull (uiNamespace getVariable ["ALSPMC_desktopDisp", displayNull])) exitWith {
        if (!isNil "ALS_propCam") then {[""] call ALS_fnc_propView};
        ALSPMC_desktopCamera = false;
    };
    private _angle = diag_tickTime * 9;
    _camera camSetPos (_center vectorAdd [sin _angle * _radius, cos _angle * _radius, _radius * 0.5]);
    _camera camCommit 0;
}, 0, [_cam, _center, _radius]] call CBA_fnc_addPerFrameHandler;
ALS_propCam = [_cam, _handler];
ALSPMC_desktopCamera = true;
