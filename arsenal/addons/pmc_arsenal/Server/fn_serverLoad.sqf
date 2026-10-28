// Loads the persistent storages once. Safe before postInit: Eden attribute
// expressions register storages while the mission objects initialise.
if (!isServer || {!isNil "PMCA_storages"}) exitWith {};
PMCA_storages = createHashMap;
PMCA_sessions = createHashMap;
PMCA_itemKeys = createHashMap;
PMCA_dirty = false;
PMCA_saveBlocked = false;
PMCA_storageObjects = [];
PMCA_boxOrder = createHashMap;
PMCA_boxes = createHashMap;
private _saved = profileNamespace getVariable ["PMCA_storages_v1", [1, []]];
private _valid = _saved isEqualType [] && {count _saved == 2} && {(_saved select 0) isEqualTo 1} && {(_saved select 1) isEqualType []};
if (_valid) then {
    {
        private _good = _x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""} && {(_x select 0) != ""} && {(_x select 1) isEqualType []};
        if (_good) then {
            private _items = createHashMap;
            {
                if (_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""} && {(_x select 1) isEqualType 0} && {
                    (_x select 1) == -1 || {(_x select 1) > 0 && {(_x select 1) == floor (_x select 1)}}
                }) then {_items set [_x select 0, _x select 1]} else {_good = false};
            } forEach (_x select 1);
            if (_good) then {
                PMCA_storages set [_x select 0, createHashMapFromArray [["items", _items], ["categories", []], ["persist", true]]];
            };
        };
        if (!_good) then {_valid = false};
    } forEach (_saved select 1);
};
// Ordinary inventories of arsenal objects: [1, [[key, PMCA_fnc_boxCargo record], ...]].
private _cargoValid = {
    params ["_cargo", "_depth"];
    _cargo isEqualType [] && {count _cargo == 4} && {_depth <= 4} && {(_cargo findIf {!(_x isEqualType [])}) < 0} && {
        ((_cargo select 0) findIf {!(_x isEqualTypeArray ["", 0])}) < 0} && {
        ((_cargo select 1) findIf {!(_x isEqualTypeArray ["", 0])}) < 0} && {
        ((_cargo select 2) findIf {!(_x isEqualType [] && {count _x > 0} && {(_x select 0) isEqualType ""})}) < 0} && {
        ((_cargo select 3) findIf {!(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""} && {[_x select 1, _depth + 1] call _cargoValid})}) < 0}
};
private _boxes = profileNamespace getVariable ["PMCA_boxes_v1", [1, []]];
if (_valid) then {
    _valid = _boxes isEqualType [] && {count _boxes == 2} && {(_boxes select 0) isEqualTo 1} && {(_boxes select 1) isEqualType []} && {
        ((_boxes select 1) findIf {!(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""} && {[_x select 1, 0] call _cargoValid})}) < 0};
    if (_valid) then {{PMCA_boxes set [_x select 0, _x select 1]} forEach (_boxes select 1)};
};
if (!_valid) then {
    // Fail closed: the damaged key stays on disk for recovery and is never overwritten.
    PMCA_storages = createHashMap;
    PMCA_boxes = createHashMap;
    PMCA_saveBlocked = true;
    diag_log text "[PMCA] ERROR: saved arsenal storages are invalid; they are kept untouched and this session will not save";
};
