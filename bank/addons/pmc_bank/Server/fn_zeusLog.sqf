// [Zeus unit] -> nothing. Zeus -> server. Sends the whole journal, newest first,
// including Zeus operations, as [number, time, account, account name, operation,
// amount, balance after, actor UID, actor name, mission].
if (!isServer) exitWith {};
call PMCB_fnc_serverLoad;
params [["_zeus", objNull, [objNull]]];
private _owner = [_zeus, false] call PMCB_fnc_caller;
if (_owner < 0 || {!([_zeus] call PMCB_fnc_isZeus)}) exitWith {};
private _entries = +PMCB_log;
reverse _entries;
[_entries] remoteExecCall ["PMCB_fnc_receiveLog", _owner];
