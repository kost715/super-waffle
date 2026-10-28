// [storageID] -> [[class, amount], ...] (amount -1: unlimited; magazines in rounds).
params [["_id", "", [""]]];
if (!isServer) exitWith {[]};
call PMCA_fnc_serverLoad;
((PMCA_storages getOrDefault [_id, createHashMap]) getOrDefault ["items", createHashMap]) toArray false
