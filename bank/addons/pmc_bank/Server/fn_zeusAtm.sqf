// [Zeus unit, object] -> nothing. Zeus module -> server. Makes the object an ATM,
// or turns an ATM back into an ordinary object.
if (!isServer) exitWith {};
call PMCB_fnc_serverLoad;
params [["_zeus", objNull, [objNull]], ["_object", objNull, [objNull]]];
private _owner = [_zeus, false] call PMCB_fnc_caller;
if (_owner < 0 || {!([_zeus] call PMCB_fnc_isZeus)}) exitWith {};
if (isNull _object || {_object isKindOf "CAManBase"}) exitWith {["STR_PMCB_ERR_NO_OBJECT", []] remoteExecCall ["PMCB_fnc_notify", _owner]};
private _enable = !(_object in PMCB_atms);
[_object, _enable] call PMCB_fnc_registerAtm;
[["STR_PMCB_DONE_ATM_REMOVE", "STR_PMCB_DONE_ATM_ADD"] select _enable, []] remoteExecCall ["PMCB_fnc_notify", _owner];
