// [object, storageID, options] -> true. Server. Makes the object open the arsenal
// of a storage; several objects may share one storage. Options (pairs or hashmap):
//   "items"      - initial stock [[class, amount], ...], applied only to a new storage
//   "categories" - categories everyone may take from (default all; see allowedTabs)
//   "persistent" - false keeps this storage for the current mission only
params [["_object", objNull, [objNull]], ["_id", "", [""]], ["_options", [], [[], createHashMap]]];
if (!isServer || {isNull _object} || {_id == ""}) exitWith {false};
call PMCA_fnc_serverLoad;
if (_options isEqualType []) then {_options = createHashMapFromArray _options};
private _storage = PMCA_storages getOrDefault [_id, createHashMap];
if (count _storage == 0) then {
    _storage = createHashMapFromArray [["items", createHashMap], ["categories", []], ["persist", true]];
    PMCA_storages set [_id, _storage];
    if ("persistent" in _options) then {_storage set ["persist", (_options get "persistent") isEqualTo true]};
    [_id, _options getOrDefault ["items", []]] call PMCA_fnc_storageAdd;
};
if ("persistent" in _options) then {_storage set ["persist", (_options get "persistent") isEqualTo true]};
if ("categories" in _options && {(_options get "categories") isEqualType []}) then {_storage set ["categories", _options get "categories"]};
_object setVariable ["PMCA_storage", _id, true];
// Actions on every client, including players joining later, while the object exists.
[_object] remoteExec ["PMCA_fnc_arsenal_init", 0, _object];
true
