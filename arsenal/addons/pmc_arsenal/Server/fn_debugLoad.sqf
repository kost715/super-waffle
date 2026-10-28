// [curator unit, box] -> nothing. Client (Zeus module) -> server, debug mode only.
// Everything in the box, including uniforms, vests and backpacks inside it, becomes
// unlimited in the storage of the nearest arsenal object within 100 m. The box
// itself is left as it is.
if (!isServer) exitWith {};
call PMCA_fnc_serverLoad;
params [["_unit", objNull, [objNull]], ["_box", objNull, [objNull]]];
private _owner = call PMCA_fnc_requestOwner;
if (isNull _unit || {isRemoteExecuted && {owner _unit != _owner}} || {isNull getAssignedCuratorLogic _unit}) exitWith {};
private _notify = {params ["_key", ["_args", []]]; [_key, _args] remoteExecCall ["PMCA_fnc_notify", _owner]};
if !(missionNamespace getVariable ["PMCA_debugMode", false]) exitWith {["STR_PMCA_ERR_DEBUG_OFF"] call _notify};
if (isNull _box || {_box isKindOf "CAManBase"}) exitWith {["STR_PMCA_ERR_DEBUG_BOX"] call _notify};
private _arsenal = objNull;
{
    if (_x distance _box <= 100 && {(_x getVariable ["PMCA_storage", ""]) in PMCA_storages} && {
        isNull _arsenal || {_x distance _box < _arsenal distance _box}}) then {_arsenal = _x};
} forEach (PMCA_storageObjects select {!isNull _x});
if (isNull _arsenal) exitWith {["STR_PMCA_ERR_DEBUG_FAR"] call _notify};
private _id = _arsenal getVariable "PMCA_storage";
private _storage = PMCA_storages get _id;
private _items = _storage get "items";
private _rows = [];
{
    if ((_x call PMCA_fnc_arsenal_itemType) >= 0 && {(_items getOrDefault [_x, 0]) != -1}) then {
        _items set [_x, -1];
        _rows pushBack [_x, -1];
    };
} forEach ([_box] call PMCA_fnc_cargoItems);
if (_rows isNotEqualTo [] && {_storage getOrDefault ["persist", true]}) then {PMCA_dirty = true};
[_id, _rows, true, []] call PMCA_fnc_broadcast;
["STR_PMCA_DEBUG_LOADED", [count _rows, _id]] call _notify;
