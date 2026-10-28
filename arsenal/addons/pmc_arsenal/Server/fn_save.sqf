// Writes persistent storages and the recorded inventories of their objects to the
// server profile. Entries of other missions that were loaded but not registered
// here are written back unchanged.
if (!isServer || {isNil "PMCA_storages"} || {PMCA_saveBlocked}) exitWith {false};
private _rows = [];
{
    if (_y getOrDefault ["persist", true]) then {_rows pushBack [_x, (_y get "items") toArray false]};
} forEach PMCA_storages;
profileNamespace setVariable ["PMCA_storages_v1", [1, _rows]];
profileNamespace setVariable ["PMCA_boxes_v1", [1, PMCA_boxes toArray false]];
saveProfileNamespace;
PMCA_dirty = false;
true
