// [Zeus unit, arsenal object] -> nothing. Zeus module -> server. Opens the stock
// window for the storage the object opens.
if (!isServer) exitWith {};
call PMCA_fnc_serverLoad;
params [["_zeus", objNull, [objNull]], ["_object", objNull, [objNull]]];
private _owner = [_zeus] call PMCA_fnc_zeusCaller;
if (_owner < 0) exitWith {};
private _id = _object getVariable ["PMCA_storage", ""];
if !(_id in PMCA_storages) exitWith {["STR_PMCA_ERR_STOCK_OBJECT", []] remoteExecCall ["PMCA_fnc_notify", _owner]};
[_id, [_id] call PMCA_fnc_stockRows] remoteExecCall ["PMCA_fnc_stockReceive", _owner];
