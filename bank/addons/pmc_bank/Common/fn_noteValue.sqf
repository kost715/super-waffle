// [class] -> value of one banknote of this class, 0 if it is not a banknote.
params [["_class", "", [""]]];
private _lower = toLowerANSI _class;
private _note = (call PMCB_fnc_notes) select {toLowerANSI (_x select 0) == _lower};
if (_note isEqualTo []) then {0} else {(_note select 0) select 1}
