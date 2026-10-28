// [unit, ATM] -> nothing. Client -> server when the ATM screen opens.
if (!isServer) exitWith {};
call PMCB_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_atm", objNull, [objNull]]];
private _owner = [_unit] call PMCB_fnc_caller;
if (_owner < 0) exitWith {};
if !([_unit, _atm] call PMCB_fnc_atmNear) exitWith {["STR_PMCB_ERR_FAR", []] remoteExecCall ["PMCB_fnc_notify", _owner]};
[_unit] call PMCB_fnc_ensure;
PMCB_viewers set [_owner, _unit];
[_owner, _unit] call PMCB_fnc_push;
