// [Zeus unit, storageID] -> nothing. Zeus stock window -> server: sends the stock again.
if (!isServer) exitWith {};
call PMCA_fnc_serverLoad;
params [["_zeus", objNull, [objNull]], ["_id", "", [""]]];
private _owner = [_zeus] call PMCA_fnc_zeusCaller;
if (_owner < 0 || {!(_id in PMCA_storages)}) exitWith {};
[_id, [_id] call PMCA_fnc_stockRows] remoteExecCall ["PMCA_fnc_stockReceive", _owner];
