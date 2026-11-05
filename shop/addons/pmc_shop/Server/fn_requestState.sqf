// [unit, laptop] -> nothing. Client -> server when a laptop's browser opens: the client
// is told the market and its balances, and again whenever the market changes.
if (!isServer) exitWith {};
call PMCS_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_terminal", objNull, [objNull]]];
private _owner = [_unit] call PMCS_fnc_caller;
if (_owner < 0) exitWith {};
private _mode = _terminal getVariable ["PMCS_mode", ""];
if !([_unit, _terminal, _mode] call PMCS_fnc_terminalNear) exitWith {["STR_PMCS_ERR_FAR", []] remoteExecCall ["PMCS_fnc_notify", _owner]};
if (_mode == "admin" && {!([_unit] call PMCS_fnc_isZeus)}) exitWith {["STR_PMCS_ERR_ZEUS", []] remoteExecCall ["PMCS_fnc_notify", _owner]};
PMCS_viewers set [_owner, [_unit, _mode]];
[_owner, _unit, _mode] call PMCS_fnc_push;
