// [action class, config root] -> [class, entry] of the nearest class in the hook table:
// the class itself or the parent it inherits our overrides from (e.g. another mod's
// bandage based on FieldDressing). [] when none.
params ["_class", "_root"];
private _table = call PMCI_fnc_table;
private _cfg = _root >> _class;
private _found = [];
while {_found isEqualTo [] && {isClass _cfg}} do {
    private _name = configName _cfg;
    if (_name in _table) then {_found = [_name, _table get _name]} else {_cfg = inheritsFrom _cfg};
};
_found
