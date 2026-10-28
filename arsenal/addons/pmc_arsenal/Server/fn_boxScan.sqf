// -> true when the ordinary inventory of any persistent arsenal object changed since
// it was last recorded. Server. Records the new state for the next save.
private _changed = false;
{
    private _key = _x getVariable ["PMCA_boxKey", ""];
    private _storage = PMCA_storages getOrDefault [_x getVariable ["PMCA_storage", ""], createHashMap];
    // A destroyed object has lost its cargo: keep the last record.
    if (_key != "" && {alive _x} && {_storage getOrDefault ["persist", false]}) then {
        private _now = [_x] call PMCA_fnc_boxCargo;
        if !((PMCA_boxes getOrDefault [_key, []]) isEqualTo _now) then {
            PMCA_boxes set [_key, _now];
            _changed = true;
        };
    };
} forEach (PMCA_storageObjects select {!isNull _x});
_changed
