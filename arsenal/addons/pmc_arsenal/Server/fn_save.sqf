// Writes persistent storages to the server profile. Storages of other missions
// that were loaded but not registered here are written back unchanged.
if (!isServer || {isNil "PMCA_storages"} || {PMCA_saveBlocked}) exitWith {false};
private _rows = [];
{
    if (_y getOrDefault ["persist", true]) then {_rows pushBack [_x, (_y get "items") toArray false]};
} forEach PMCA_storages;
profileNamespace setVariable ["PMCA_storages_v1", [1, _rows]];
saveProfileNamespace;
PMCA_dirty = false;
true
