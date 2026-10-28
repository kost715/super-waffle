// [object, storageID, options] -> true. Server. Makes the object open the arsenal
// of a storage; several objects may share one storage. Options (pairs or hashmap):
//   "items"      - initial stock [[class, amount], ...], applied only to a new storage
//                  and ignored in debug mode (the arsenal starts empty)
//   "categories" - categories everyone may take from (default all; see allowedTabs)
//   "persistent" - false keeps this storage for the current mission only
// The object's ordinary inventory is saved too, keyed by storage ID and the order in
// which the storage's objects were registered.
params [["_object", objNull, [objNull]], ["_id", "", [""]], ["_options", [], [[], createHashMap]]];
if (!isServer || {isNull _object} || {_id == ""}) exitWith {false};
call PMCA_fnc_serverLoad;
if (_options isEqualType []) then {_options = createHashMapFromArray _options};
private _storage = PMCA_storages getOrDefault [_id, createHashMap];
if (count _storage == 0) then {
    _storage = createHashMapFromArray [["items", createHashMap], ["categories", []], ["persist", true]];
    PMCA_storages set [_id, _storage];
    if ("persistent" in _options) then {_storage set ["persist", (_options get "persistent") isEqualTo true]};
    if !(missionNamespace getVariable ["PMCA_debugMode", false]) then {[_id, _options getOrDefault ["items", []]] call PMCA_fnc_storageAdd};
};
if ("persistent" in _options) then {_storage set ["persist", (_options get "persistent") isEqualTo true]};
if ("categories" in _options && {(_options get "categories") isEqualType []}) then {_storage set ["categories", _options get "categories"]};
// A lowered threshold also applies to stock saved before.
[_id] call PMCA_fnc_unlock;
if !(_object in PMCA_storageObjects && {(_object getVariable ["PMCA_storage", ""]) == _id}) then {
    _object setVariable ["PMCA_storage", _id, true];
    PMCA_storageObjects pushBackUnique _object;
    private _order = (PMCA_boxOrder getOrDefault [_id, 0]) + 1;
    PMCA_boxOrder set [_id, _order];
    _object setVariable ["PMCA_boxKey", format ["%1#%2", _id, _order]];
    // Before postInit, Eden inventory attributes may still fill the object; serverInit loads it then.
    if (missionNamespace getVariable ["PMCA_ready", false]) then {[_object] call PMCA_fnc_boxLoad};
    // Actions on every client, including players joining later, while the object exists.
    [_object] remoteExec ["PMCA_fnc_arsenal_init", 0, _object];
};
true
