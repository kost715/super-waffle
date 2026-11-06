// [vest upgrade] -> what it takes from the inventory: [[class, count], ...] (warbelts, old
// uniforms and the table's item, the same class counted once).
params [["_upgrade", [], [[]]]];
_upgrade params ["", "", "", "", "", "", "", ["_belt", 0], ["_uniform", 0], ["_item", ""], ["_count", 0]];
(call PMCS_fnc_gearItems) params ["_beltClass", "_uniformClass"];
private _take = [];
{
    _x params ["_class", "_n"];
    if (_n > 0 && {_class != ""}) then {
        private _at = _take findIf {(_x select 0) == _class};
        if (_at < 0) then {_take pushBack [_class, _n]} else {(_take select _at) set [1, ((_take select _at) select 1) + _n]};
    };
} forEach [[_beltClass, _belt], [_uniformClass, _uniform], [_item, _count]];
_take
