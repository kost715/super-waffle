// [storageID] -> [[class, amount, tab], ...]. Server. The stock for the Zeus stock
// window; tab -1 marks items the arsenal cannot list (e.g. from a mod no longer loaded).
params [["_id", "", [""]]];
private _items = (PMCA_storages getOrDefault [_id, createHashMap]) getOrDefault ["items", createHashMap];
(keys _items) apply {[_x, _items get _x, _x call PMCA_fnc_arsenal_itemType]}
